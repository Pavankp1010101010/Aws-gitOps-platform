#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this installer as root." >&2
  exit 2
fi

umask 077

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
user="agtp-sns-webhook"
token_file="/etc/agtp/sns-webhook-token"
grafana_password_file="/etc/agtp/grafana-admin-password"

export DEBIAN_FRONTEND=noninteractive
if ! command -v aws >/dev/null 2>&1 || ! aws --version 2>&1 | grep -q '^aws-cli/2\.'; then
  apt-get update
  apt-get install --yes --no-install-recommends gnupg unzip
  aws_cli_installer="$(mktemp)"
  trap 'rm -f -- "$aws_cli_installer"' EXIT
  curl --fail --location --silent --show-error \
    https://awscli.amazonaws.com/v2/install.sh --output "$aws_cli_installer"
  bash "$aws_cli_installer" --system
  rm -f -- "$aws_cli_installer"
  trap - EXIT
fi

if ! aws --version 2>&1 | grep -q '^aws-cli/2\.'; then
  echo "AWS CLI v2 is required for SNS publishing." >&2
  exit 1
fi

if ! getent group "$user" >/dev/null; then
  groupadd --system "$user"
fi
if ! getent passwd "$user" >/dev/null; then
  useradd --system --gid "$user" --no-create-home --shell /usr/sbin/nologin "$user"
fi
install -d --owner=root --group="$user" --mode=0750 /etc/agtp
install -d --owner=root --group=root --mode=0755 /opt/agtp
install --owner=root --group=root --mode=0755 "$script_dir/sns_webhook.py" /opt/agtp/sns_webhook.py
install --owner=root --group=root --mode=0644 "$script_dir/sns-webhook.service" /etc/systemd/system/agtp-sns-webhook.service

if [[ ! -s "$token_file" ]]; then
  openssl rand -hex 32 > "$token_file"
fi
chown root:"$user" "$token_file"
chmod 0640 "$token_file"

if [[ ! -s "$grafana_password_file" ]]; then
  openssl rand -hex 32 > "$grafana_password_file"
fi
chown root:root "$grafana_password_file"
chmod 0600 "$grafana_password_file"

cat > /etc/agtp/sns-webhook.env <<'EOF'
AWS_DEFAULT_REGION=us-east-1
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:507720142035:agtp-demo-host-alerts
SNS_WEBHOOK_BIND_ADDRESS=10.42.0.1
SNS_WEBHOOK_PORT=9811
SNS_WEBHOOK_TOKEN_FILE=/etc/agtp/sns-webhook-token
EOF
chown root:root /etc/agtp/sns-webhook.env
chmod 0644 /etc/agtp/sns-webhook.env

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic monitoring-sns-webhook \
  --from-file=token="$token_file" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic monitoring-grafana-admin \
  --from-literal=admin-user=admin --from-file=admin-password="$grafana_password_file" \
  --dry-run=client -o yaml | kubectl apply -f -

systemctl daemon-reload
systemctl enable --now agtp-sns-webhook.service
curl --fail --silent --show-error http://10.42.0.1:9811/healthz >/dev/null
echo "SNS webhook bridge and out-of-band monitoring credentials are ready."

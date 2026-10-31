#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this installer as root." >&2
  exit 2
fi

if [[ $# -ne 1 || ! "$1" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]]; then
  echo "Usage: $0 <backup-bucket-name>" >&2
  exit 2
fi

bucket="$1"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for command in aws kubectl flock; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command is unavailable: $command" >&2
    exit 1
  fi
done

if ! aws --version 2>&1 | grep -q '^aws-cli/2\.'; then
  echo "AWS CLI v2 is required for S3 backups." >&2
  exit 1
fi

if ! aws sts get-caller-identity --output json >/dev/null; then
  echo "The EC2 instance role is unavailable to the host backup service." >&2
  exit 1
fi

if ! aws s3api list-objects-v2 --bucket "$bucket" --prefix postgres/automated/ --max-keys 1 >/dev/null; then
  echo "The host role cannot list the automated PostgreSQL backup prefix." >&2
  exit 1
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
if ! kubectl cluster-info >/dev/null; then
  echo "The host cannot reach the local Kubernetes API." >&2
  exit 1
fi

install -d --owner=root --group=root --mode=0700 \
  /var/lib/agtp-postgres-backup/home \
  /var/lib/agtp-postgres-backup/tmp
install -d --owner=root --group=root --mode=0755 \
  /var/lib/node_exporter/textfile_collector \
  /etc/agtp \
  /opt/agtp

install --owner=root --group=root --mode=0750 \
  "$script_dir/backup-postgres.sh" /opt/agtp/backup-postgres.sh
install --owner=root --group=root --mode=0644 \
  "$script_dir/agtp-postgres-backup.service" /etc/systemd/system/agtp-postgres-backup.service
install --owner=root --group=root --mode=0644 \
  "$script_dir/agtp-postgres-backup.timer" /etc/systemd/system/agtp-postgres-backup.timer

printf 'BACKUP_BUCKET=%s\nAWS_DEFAULT_REGION=us-east-1\n' "$bucket" \
  > /etc/agtp/postgres-backup.env
chown root:root /etc/agtp/postgres-backup.env
chmod 0600 /etc/agtp/postgres-backup.env

metrics_file=/var/lib/node_exporter/textfile_collector/agtp-postgres-backup.prom
if [[ ! -e "$metrics_file" ]]; then
  cat > "$metrics_file" <<'EOF'
# HELP agtp_postgres_backup_last_success_timestamp_seconds Unix time of the last verified S3 upload.
# TYPE agtp_postgres_backup_last_success_timestamp_seconds gauge
agtp_postgres_backup_last_success_timestamp_seconds 0
# HELP agtp_postgres_backup_last_attempt_timestamp_seconds Unix time of the last backup attempt.
# TYPE agtp_postgres_backup_last_attempt_timestamp_seconds gauge
agtp_postgres_backup_last_attempt_timestamp_seconds 0
# HELP agtp_postgres_backup_last_attempt_success Whether the last backup attempt completed successfully.
# TYPE agtp_postgres_backup_last_attempt_success gauge
agtp_postgres_backup_last_attempt_success 0
EOF
  chown root:root "$metrics_file"
  chmod 0644 "$metrics_file"
fi

systemctl daemon-reload
systemctl enable --now agtp-postgres-backup.timer
systemctl is-enabled --quiet agtp-postgres-backup.timer
systemctl is-active --quiet agtp-postgres-backup.timer
echo "Daily PostgreSQL backup timer is enabled; run the service once to verify an upload."

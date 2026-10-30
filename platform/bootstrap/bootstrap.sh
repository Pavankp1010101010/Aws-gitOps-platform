#!/usr/bin/env bash
set -Eeuo pipefail

exec > >(tee -a /var/log/agtp-stage05-bootstrap.log | logger -t agtp-stage05-bootstrap) 2>&1

readonly K3S_VERSION="v1.36.5+k3s1"
readonly K3S_TAG_URL="v1.36.5%2Bk3s1"
readonly K3S_BINARY_SHA256="d73847bcd3c5fccef0115b372e2f9a91f3032dc84bbf71518a4617565294d313"
readonly K3S_INSTALLER_SHA256="46177d4c99440b4c0311b67233823a8e8a2fc09693f6c89af1a7161e152fbfad"
readonly ECR_PROVIDER_VERSION="v1.37.0"
readonly ECR_PROVIDER_SHA256="842e0fd8159f5ed8df2f38e6521e1e4f0a1ee80cf1e1ac119bbf20bf9c20681c"
readonly ARGOCD_VERSION="v3.5.6"
readonly ARGOCD_INSTALL_SHA256="846c644bc81ce5557dd9048757a9c7353378f25c5eb811c77d32a9e907823599"
readonly REGION="us-east-1"
readonly ECR_PROVIDER_DIR="/var/lib/rancher/k3s/credential-providers"
readonly CREDENTIAL_PROVIDER_CONFIG="/etc/rancher/k3s/ecr-credential-provider-config.yaml"
readonly KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

log() {
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*"
}

fail() {
  log "ERROR: $*"
  exit 1
}

verify_sha256() {
  local expected="$1"
  local file="$2"
  printf '%s  %s\n' "$expected" "$file" | sha256sum --check --status || fail "SHA-256 verification failed for $file"
}

download() {
  local url="$1"
  local destination="$2"
  curl --fail --location --silent --show-error --retry 5 --retry-all-errors "$url" --output "$destination" ||
    fail "Download failed: $url"
}

if [[ "$(id -u)" -ne 0 ]]; then
  fail "Bootstrap must run as root."
fi

if ! grep -q '^VERSION_ID="24.04"$' /etc/os-release; then
  fail "Expected Ubuntu 24.04 LTS."
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  fail "Expected an x86_64 host."
fi

if ! curl --silent --show-error --fail \
  --request PUT \
  --header "X-aws-ec2-metadata-token-ttl-seconds: 60" \
  http://169.254.169.254/latest/api/token >/dev/null; then
  fail "IMDSv2 is unavailable from the host."
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes --no-install-recommends ca-certificates curl

install -d -o root -g root -m 0755 /etc/agtp /etc/rancher/k3s
install -d -o root -g root -m 0755 "$ECR_PROVIDER_DIR"
install -d -o root -g root -m 0755 /var/lib/rancher/k3s/server/manifests

provider_tmp="$(mktemp)"
trap 'rm -f "$provider_tmp"' EXIT
download \
  "https://artifacts.k8s.io/binaries/cloud-provider-aws/${ECR_PROVIDER_VERSION}/linux/amd64/ecr-credential-provider-linux-amd64" \
  "$provider_tmp"
verify_sha256 "$ECR_PROVIDER_SHA256" "$provider_tmp"
install -o root -g root -m 0755 "$provider_tmp" "${ECR_PROVIDER_DIR}/ecr-credential-provider"
rm -f "$provider_tmp"
trap - EXIT

cat >/etc/rancher/k3s/ecr-credential-provider-config.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1
kind: CredentialProviderConfig
providers:
  - name: ecr-credential-provider
    matchImages:
      - "*.dkr.ecr.${REGION}.amazonaws.com"
    defaultCacheDuration: 10h
    apiVersion: credentialprovider.kubelet.k8s.io/v1
EOF
chmod 0644 "$CREDENTIAL_PROVIDER_CONFIG"

cat >/etc/rancher/k3s/config.yaml <<EOF
write-kubeconfig-mode: "0600"
secrets-encryption: true
disable:
  - servicelb
kubelet-arg:
  - image-credential-provider-config=${CREDENTIAL_PROVIDER_CONFIG}
  - image-credential-provider-bin-dir=${ECR_PROVIDER_DIR}
EOF
chmod 0600 /etc/rancher/k3s/config.yaml

cat >/var/lib/rancher/k3s/server/manifests/traefik-config.yaml <<'EOF'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    service:
      spec:
        type: ClusterIP
EOF
chmod 0644 /var/lib/rancher/k3s/server/manifests/traefik-config.yaml

if command -v k3s >/dev/null 2>&1; then
  installed_version="$(k3s --version | awk 'NR == 1 { print $3 }')"
  [[ "$installed_version" == "$K3S_VERSION" ]] ||
    fail "Found K3s ${installed_version}; refusing implicit version replacement."
  log "K3s ${K3S_VERSION} is already installed; preserving the existing cluster."
else
  installer="$(mktemp)"
  binary="$(mktemp)"
  trap 'rm -f "$installer" "$binary"' EXIT
  download \
    "https://raw.githubusercontent.com/k3s-io/k3s/${K3S_TAG_URL}/install.sh" \
    "$installer"
  verify_sha256 "$K3S_INSTALLER_SHA256" "$installer"
  download \
    "https://github.com/k3s-io/k3s/releases/download/${K3S_TAG_URL}/k3s" \
    "$binary"
  verify_sha256 "$K3S_BINARY_SHA256" "$binary"
  install -o root -g root -m 0755 "$binary" /usr/local/bin/k3s
  INSTALL_K3S_VERSION="$K3S_VERSION" \
    INSTALL_K3S_SKIP_DOWNLOAD=true \
    INSTALL_K3S_EXEC="server" \
    sh "$installer"
  rm -f "$installer" "$binary"
  trap - EXIT
fi

systemctl enable k3s
if systemctl is-active --quiet k3s; then
  systemctl restart k3s
else
  systemctl start k3s
fi

export KUBECONFIG
kubectl_ready=false
for _ in $(seq 1 120); do
  if kubectl get nodes >/dev/null 2>&1; then
    kubectl_ready=true
    break
  fi
  sleep 10
done
[[ "$kubectl_ready" == true ]] || fail "K3s API did not become ready within 20 minutes."

kubectl wait --for=condition=Ready node --all --timeout=10m ||
  fail "K3s node did not become Ready."
manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
download \
  "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" \
  "$manifest"
verify_sha256 "$ARGOCD_INSTALL_SHA256" "$manifest"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts --dry-run=server \
  -n argocd -f "$manifest" >/dev/null ||
  fail "Argo CD manifest could not be validated by the Kubernetes API."
kubectl apply --server-side --force-conflicts -n argocd -f "$manifest"
rm -f "$manifest"
trap - EXIT

kubectl wait --for=condition=Available deployment --all -n argocd --timeout=20m ||
  fail "Argo CD deployments did not become Available."
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=20m ||
  fail "Argo CD application controller did not become Ready."
kubectl wait --for=condition=Ready pod --all -n argocd --timeout=20m ||
  fail "Argo CD pods did not become Ready."

cat >/etc/systemd/system/agtp-argocd-port-forward.service <<'EOF'
[Unit]
Description=Loopback-only Argo CD port forward for SSM access
After=k3s.service
Requires=k3s.service

[Service]
Type=simple
Environment=KUBECONFIG=/etc/rancher/k3s/k3s.yaml
ExecStart=/usr/local/bin/kubectl -n argocd port-forward --address 127.0.0.1 svc/argocd-server 8443:443
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now agtp-argocd-port-forward.service

log "Stage 05 host bootstrap completed: K3s ${K3S_VERSION}, Argo CD ${ARGOCD_VERSION}, encrypted Kubernetes secrets, private Traefik service, SSM-only Argo access, and refreshable ECR credentials."
log "Apply /etc/agtp/root-app.yaml only after its target repository path is available on the configured Git revision."

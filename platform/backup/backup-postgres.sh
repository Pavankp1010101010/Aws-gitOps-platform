#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

readonly metric_dir="/var/lib/node_exporter/textfile_collector"
readonly metric_file="$metric_dir/agtp-postgres-backup.prom"
readonly work_dir="/var/lib/agtp-postgres-backup/tmp"
readonly lock_file="/run/lock/agtp-postgres-backup.lock"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run the PostgreSQL backup as root through its systemd unit." >&2
  exit 2
fi

exec 9>"$lock_file"
if ! flock -n 9; then
  echo "A PostgreSQL backup is already running; skipping this invocation."
  exit 0
fi

attempt_timestamp="$(date -u +%s)"
last_success_timestamp=0
if [[ -r "$metric_file" ]]; then
  last_success_timestamp="$(awk '$1 == "agtp_postgres_backup_last_success_timestamp_seconds" { print $2; exit }' "$metric_file")"
fi
if [[ ! "$last_success_timestamp" =~ ^[0-9]+$ ]]; then
  last_success_timestamp=0
fi

dump_file=""

write_metrics() {
  local success_timestamp="$1"
  local attempt_time="$2"
  local attempt_success="$3"
  local temporary_file

  temporary_file="$(mktemp "$metric_dir/.agtp-postgres-backup.prom.XXXXXX")"
  cat > "$temporary_file" <<EOF
# HELP agtp_postgres_backup_last_success_timestamp_seconds Unix time of the last verified S3 upload.
# TYPE agtp_postgres_backup_last_success_timestamp_seconds gauge
agtp_postgres_backup_last_success_timestamp_seconds $success_timestamp
# HELP agtp_postgres_backup_last_attempt_timestamp_seconds Unix time of the last backup attempt.
# TYPE agtp_postgres_backup_last_attempt_timestamp_seconds gauge
agtp_postgres_backup_last_attempt_timestamp_seconds $attempt_time
# HELP agtp_postgres_backup_last_attempt_success Whether the last backup attempt completed successfully.
# TYPE agtp_postgres_backup_last_attempt_success gauge
agtp_postgres_backup_last_attempt_success $attempt_success
EOF
  chmod 0644 "$temporary_file"
  mv -f -- "$temporary_file" "$metric_file"
}

finish() {
  local status="$?"
  trap - EXIT

  if [[ -n "$dump_file" ]] && ! rm -f -- "$dump_file"; then
    echo "Failed to remove the temporary PostgreSQL dump file." >&2
    status=1
  fi

  if [[ "$status" -eq 0 ]]; then
    completed_timestamp="$(date -u +%s)"
    if ! write_metrics "$completed_timestamp" "$attempt_timestamp" 1; then
      echo "Failed to write PostgreSQL backup success metrics." >&2
      status=1
    fi
  else
    if ! write_metrics "$last_success_timestamp" "$attempt_timestamp" 0; then
      echo "Failed to write PostgreSQL backup failure metrics." >&2
      status=1
    fi
    echo "PostgreSQL backup failed; inspect this unit's journal for the command error." >&2
  fi

  exit "$status"
}
trap finish EXIT

environment_file="/etc/agtp/postgres-backup.env"
if [[ ! -r "$environment_file" ]]; then
  echo "Missing PostgreSQL backup configuration: $environment_file" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$environment_file"

if [[ ! "${BACKUP_BUCKET:-}" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]]; then
  echo "BACKUP_BUCKET must be a valid S3 bucket name." >&2
  exit 1
fi

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
mkdir -p -- "$work_dir"
chmod 0700 "$work_dir"

kubectl wait --namespace support-ticket \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=database \
  --timeout=90s

database_pod="$(kubectl get pods --namespace support-ticket \
  --selector=app.kubernetes.io/component=database \
  --output='jsonpath={.items[0].metadata.name}')"
if [[ -z "$database_pod" ]]; then
  echo "No PostgreSQL pod was found in the support-ticket namespace." >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
object_key="postgres/automated/${timestamp}.dump"
dump_file="$(mktemp "$work_dir/postgres-XXXXXX.dump")"

kubectl exec --namespace support-ticket "$database_pod" -- \
  sh -ec 'pg_dump --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --no-owner --no-acl --format=custom' \
  > "$dump_file"
if [[ ! -s "$dump_file" ]]; then
  echo "PostgreSQL produced an empty backup archive." >&2
  exit 1
fi

kubectl exec --namespace support-ticket --stdin "$database_pod" -- pg_restore --list \
  < "$dump_file" > /dev/null

aws s3 cp "$dump_file" "s3://${BACKUP_BUCKET}/${object_key}" \
  --sse AES256 --only-show-errors

uploaded_size="$(aws s3api head-object --bucket "$BACKUP_BUCKET" --key "$object_key" \
  --query ContentLength --output text)"
expected_size="$(stat --format=%s "$dump_file")"
if [[ "$uploaded_size" != "$expected_size" || "$uploaded_size" -le 0 ]]; then
  echo "S3 backup size verification failed." >&2
  exit 1
fi

uploaded_encryption="$(aws s3api head-object --bucket "$BACKUP_BUCKET" --key "$object_key" \
  --query ServerSideEncryption --output text)"
if [[ "$uploaded_encryption" != "AES256" ]]; then
  echo "S3 backup encryption verification failed." >&2
  exit 1
fi

checksum="$(sha256sum "$dump_file" | awk '{ print $1 }')"
echo "Verified PostgreSQL backup upload: ${object_key} (${uploaded_size} bytes, SHA-256 ${checksum})."

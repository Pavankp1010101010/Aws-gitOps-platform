#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: $0 <rendered-helm-manifests>" >&2
  exit 2
fi

manifest="$1"
service_count="$(grep -c '^kind: Service$' "$manifest")"
cluster_ip_count="$(grep -c '^  type: ClusterIP$' "$manifest")"

[[ "$service_count" == "2" ]] || {
  echo "Expected exactly two internal Services; found $service_count." >&2
  exit 1
}
[[ "$cluster_ip_count" == "2" ]] || {
  echo "Every rendered Service must remain ClusterIP." >&2
  exit 1
}
! grep -q '^kind: Secret$' "$manifest" || {
  echo "Rendered chart must reference, not create, credentials." >&2
  exit 1
}
! grep -q '^  type: LoadBalancer$' "$manifest" || {
  echo "Public LoadBalancer Services are not allowed." >&2
  exit 1
}
grep -q 'argocd.argoproj.io/hook: Sync' "$manifest" || {
  echo "Database migrations must run as an Argo CD Sync hook." >&2
  exit 1
}
grep -A 1 'argocd.argoproj.io/hook: Sync' "$manifest" |
  grep -q 'argocd.argoproj.io/sync-wave: "1"' || {
  echo "Database migrations must run after the database at sync wave 0." >&2
  exit 1
}
grep -q 'argocd.argoproj.io/hook-delete-policy: BeforeHookCreation,HookSucceeded,HookFailed' "$manifest" || {
  echo "Completed or failed migration hooks must be removed so future syncs can proceed." >&2
  exit 1
}
awk '
  /^kind: / { is_deployment = ($0 == "kind: Deployment") }
  is_deployment && /argocd.argoproj.io\/sync-wave: "2"/ { found = 1 }
  END { exit !found }
' "$manifest" || {
  echo "The application must deploy after the migration at sync wave 2." >&2
  exit 1
}
grep -q 'argocd.argoproj.io/sync-options: Prune=false' "$manifest" || {
  echo "The persistent database claim must not be pruned automatically." >&2
  exit 1
}
grep -q '@sha256:' "$manifest" || {
  echo "Application and database images must be pinned by digest." >&2
  exit 1
}

echo "Helm output passed private-service, secret-reference, migration ordering and cleanup, PVC-retention, and image-digest checks."

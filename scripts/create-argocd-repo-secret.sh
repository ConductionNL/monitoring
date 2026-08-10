#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   export SSH_PRIVATE_KEY="$(cat id_ed25519)"
#   ./scripts/create-argocd-repo-secret.sh https://github.com/ConductionNL/monitoring.git repo-ssh-conduction-monitoring

REPO_URL=${1:-}
SECRET_NAME=${2:-repo-ssh-conduction-monitoring}
NAMESPACE=${NAMESPACE:-argocd}

if [[ -z "${REPO_URL}" ]]; then
  echo "REPO_URL (arg 1) required" >&2; exit 1
fi
if [[ -z "${SSH_PRIVATE_KEY:-}" ]]; then
  echo "SSH_PRIVATE_KEY env var required" >&2; exit 1
fi

cat <<YAML | kubectl -n "${NAMESPACE}" apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${REPO_URL}
  sshPrivateKey: |
$(echo "${SSH_PRIVATE_KEY}" | sed 's/^/    /')
YAML

echo "[OK] Secret ${SECRET_NAME} applied to namespace ${NAMESPACE}."


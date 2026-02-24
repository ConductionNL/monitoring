#!/usr/bin/env bash
# Maakt of werkt bij het Kubernetes Secret voor Grafana Keycloak OAuth uit grafana/.env
# Vereist: grafana/.env met GF_AUTH_GENERIC_OAUTH_CLIENT_ID en GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET
# Gebruik: ./scripts/grafana-oauth-secret.sh [namespace]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/grafana/.env"
NAMESPACE="${1:-monitoring}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Fout: $ENV_FILE niet gevonden. Kopieer grafana/.env.example naar grafana/.env en vul GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET in."
  exit 1
fi

kubectl create secret generic grafana-keycloak-oauth \
  --from-env-file="$ENV_FILE" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret grafana-keycloak-oauth in namespace $NAMESPACE is bijgewerkt. Herstart Grafana pods om de nieuwe waarden te laden (of wacht op rollout)."

#!/usr/bin/env bash
# Debug: controleer of Keycloak OAuth-config in de Grafana-pod zit.
# Gebruik: ./scripts/grafana-debug-oauth.sh [namespace]

set -e
NAMESPACE="${1:-monitoring}"
POD=$(kubectl -n "$NAMESPACE" get pods -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [[ -z "$POD" ]]; then
  echo "Geen Grafana-pod gevonden in namespace $NAMESPACE."
  exit 1
fi

echo "=== Grafana pod: $POD ==="
echo ""
echo "--- 1. Secret mount (oauth) ---"
kubectl -n "$NAMESPACE" exec "$POD" -- ls -la /etc/grafana/secrets/oauth 2>/dev/null || echo "Map /etc/grafana/secrets/oauth bestaat niet of is leeg."
echo ""
echo "--- 2. Inhoud client_id bestand (eerste regel) ---"
kubectl -n "$NAMESPACE" exec "$POD" -- cat /etc/grafana/secrets/oauth/GF_AUTH_GENERIC_OAUTH_CLIENT_ID 2>/dev/null | head -1 || echo "Bestand niet leesbaar."
echo ""
echo "--- 3. Grafana-config (auth.generic_oauth) ---"
kubectl -n "$NAMESPACE" exec "$POD" -- cat /etc/grafana/grafana.ini 2>/dev/null | sed -n '/\[auth.generic_oauth\]/,/^\[/p' || echo "grafana.ini niet gevonden of geen [auth.generic_oauth] sectie."
echo ""
echo "--- 4. Recente Grafana-logs (oauth/auth) ---"
kubectl -n "$NAMESPACE" logs "$POD" --tail=30 2>/dev/null | grep -i -E "oauth|generic_oauth|auth.generic" || echo "Geen relevante regels."

#!/usr/bin/env bash
# Past het Nextcloud-dashboard in het cluster aan met de namespaces uit grafana/.env (NEXTCLOUD_NAMESPACES).
# Zonder NEXTCLOUD_NAMESPACES wordt de standaard uit het dashboard in Git gebruikt.
# Gebruik: ./scripts/grafana-nextcloud-dashboard-apply.sh [namespace]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/grafana/.env"
DASHBOARD_YAML="$REPO_ROOT/grafana/dashboards/nextcloud-environments.yaml"
NAMESPACE="${1:-monitoring}"

# Lees NEXTCLOUD_NAMESPACES uit .env (niet source: waarde kan komma's bevatten)
if [[ -f "$ENV_FILE" ]]; then
  NEXTCLOUD_NAMESPACES=$(grep -E '^NEXTCLOUD_NAMESPACES=' "$ENV_FILE" 2>/dev/null | sed 's/^NEXTCLOUD_NAMESPACES=//' || true)
fi
# Normaliseer: komma-gescheiden, spaties optioneel, geen CRLF
LIST="${NEXTCLOUD_NAMESPACES:-nextcloud, nextcloud-data, nextcloud-llm}"
LIST=$(echo "$LIST" | tr -d '\r\n' | sed 's/,[[:space:]]*/,/g')
if [[ -z "$LIST" ]]; then
  echo "Fout: NEXTCLOUD_NAMESPACES leeg. Zet in grafana/.env bijvoorbeeld: NEXTCLOUD_NAMESPACES=nextcloud,nextcloud-data"
  exit 1
fi

# Bouw comma-list (met spatie na komma voor weergave) en pipe-list
COMMA_LIST=$(echo "$LIST" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | paste -sd ',' - | sed 's/,/, /g')
PIPE_LIST=$(echo "$LIST" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | paste -sd '|' -)

# Bouw options-array en current arrays voor Grafana (JSON)
OPTIONS_JSON=""
TEXT_ARR=""
VALUE_ARR=""
for ns in $(echo "$LIST" | tr ',' ' '); do
  ns=$(echo "$ns" | xargs)
  [[ -z "$ns" ]] && continue
  OPTIONS_JSON="${OPTIONS_JSON}{\"selected\":true,\"text\":\"$ns\",\"value\":\"$ns\"},"
  TEXT_ARR="${TEXT_ARR}\"$ns\","
  VALUE_ARR="${VALUE_ARR}\"$ns\","
done
OPTIONS_JSON="[${OPTIONS_JSON%,}]"
TEXT_ARR="[${TEXT_ARR%,}]"
VALUE_ARR="[${VALUE_ARR%,}]"

# Lees de dashboard-JSON uit de YAML (enige regel na "nextcloud-environments.json: |")
JSON_LINE=$(grep -A1 'nextcloud-environments.json: |' "$DASHBOARD_YAML" | tail -1 | sed 's/^[[:space:]]*//')

# Vervang de variabele-definitie in de JSON (comma, pipe, options, current)
# We zoeken naar het templating-blok en vervangen de waarden
JSON_LINE=$(echo "$JSON_LINE" | sed \
  -e "s/\"query\":\"[^\"]*\"/\"query\":\"$COMMA_LIST\"/" \
  -e "s/\"definition\":\"[^\"]*\"/\"definition\":\"$COMMA_LIST\"/" \
  -e "s/\"allValue\":\"[^\"]*\"/\"allValue\":\"$PIPE_LIST\"/" \
  -e "s/\"options\":\[[^]]*\]/\"options\":$OPTIONS_JSON/" \
  -e "s/\"text\":\[[^]]*\]/\"text\":$TEXT_ARR/" \
  -e "s/\"value\":\[[^]]*\]/\"value\":$VALUE_ARR/")

# Schrijf tijdelijke YAML met de aangepaste JSON
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
head -n 16 "$DASHBOARD_YAML" > "$TMP"
echo "    $JSON_LINE" >> "$TMP"

kubectl apply -f "$TMP" -n "$NAMESPACE"
echo "Dashboard Nextcloud-omgevingen is toegepast met namespaces: $COMMA_LIST"
echo "Grafana sidecar laadt het dashboard automatisch; bij twijfel: refresh of pod herstart."

    #!/usr/bin/env bash
    set -euo pipefail

    REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "$REPO_DIR"

    # 1) age key (privé) genereren als die er nog niet is
    if [ ! -f age.agekey ]; then
      echo "[INFO] Genereer age private key: age.agekey"
      age-keygen -o age.agekey
      echo "[NOTE] Bewaar age.agekey veilig; NIET committen."
    else
      echo "[OK] age.agekey bestaat al — overslaan."
    fi

    AGE_PUB=$(grep -E '^public key: ' age.agekey | awk '{print $3}')
    if [ -z "${AGE_PUB:-}" ]; then
      echo "[ERR] Kon public key niet lezen uit age.agekey"; exit 1
    fi
    echo "[INFO] Public key: $AGE_PUB"

    # 2) SOPS policy updaten met public key (indien leeg)
    if ! grep -q "$AGE_PUB" .sops.yaml 2>/dev/null; then
      echo "[INFO] Injecteer public key in .sops.yaml"
      tmp=$(mktemp)
      awk -v KEY="$AGE_PUB" '
        BEGIN { injected=0 }
        { print }
        END {
          if (!injected) { }
        }
      ' .sops.yaml > "$tmp"

      # Eenvoudig vervangen: zet de age array naar KEY
      python3 - <<PY
import yaml, sys
p = yaml.safe_load(open('.sops.yaml'))
for r in p.get('creation_rules', []):
    if isinstance(r.get('age'), list) and not r['age']:
        r['age'] = ['${AGE_PUB}']
open('.sops.yaml','w').write(yaml.safe_dump(p, sort_keys=False))
PY
    fi

    # 3) Slack webhook veilig inlezen en versleutelen
    if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
      read -rsp "Voer Slack webhook URL in (wordt niet getoond): " SLACK_WEBHOOK_URL
      echo
    fi

    TMP_SECRET=$(mktemp)
    cat > "$TMP_SECRET" <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-slack-webhook
  namespace: monitoring
type: Opaque
stringData:
  slack_webhook: "${SLACK_WEBHOOK_URL}"
YAML

    echo "[INFO] Versleutel met SOPS -> alerting/secret-alertmanager.sops.yaml"
    sops --encrypt --age "$AGE_PUB" "$TMP_SECRET" > alerting/secret-alertmanager.sops.yaml
    rm -f "$TMP_SECRET"

    echo "[DONE] Encrypted secret klaar: alerting/secret-alertmanager.sops.yaml"
    echo "      Commit nu alle wijzigingen (behalve age.agekey)."

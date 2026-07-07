#!/usr/bin/env bash
# SPDX-License-Identifier: EUPL-1.2
# role: tool
#
# scripts/verify.sh — snelle functionele verificatie (pre-push gate).
#
# Controleert de PrometheusRule-CRD's: YAML-structuur (kind, groups,
# alert+expr per regel), en de docs-sync-eis dat elke alert een
# runbook-pagina heeft in docs/rules/<AlertNaam>.md. Als promtool
# beschikbaar is, worden de regels daar ook doorheen gehaald
# (.spec-extractie via yq); zo niet, dan meldt de output die beperking.
#
# Writes: read-only
# Idempotent: yes
# Requires: python3; optioneel: promtool + yq (mikefarah)
#
# Usage:
#   ./scripts/verify.sh

set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'EOF'
import pathlib
import sys
import yaml

errors = []
alerts = []
for f in sorted(pathlib.Path("prometheus/rules").rglob("*.yaml")):
    try:
        docs = list(yaml.safe_load_all(f.read_text()))
    except yaml.YAMLError as e:
        errors.append(f"{f}: YAML-fout: {e}")
        continue
    for doc in docs:
        if not doc:
            continue
        if doc.get("kind") != "PrometheusRule":
            errors.append(f"{f}: kind is {doc.get('kind')!r}, "
                          "verwacht PrometheusRule")
            continue
        groups = (doc.get("spec") or {}).get("groups") or []
        if not groups:
            errors.append(f"{f}: geen spec.groups")
        for g in groups:
            for r in g.get("rules") or []:
                if "alert" in r:
                    alerts.append((f, r["alert"]))
                    if not r.get("expr"):
                        errors.append(f"{f}: alert {r['alert']} zonder expr")

# Dekking: eigen pagina docs/rules/<Alert>.md, of expliciet genoemd in
# een verzamelpagina (huisstijl: CoreDNSExtended bundelt zes alerts).
pages = list(pathlib.Path("docs/rules").glob("*.md"))
corpus = "\n".join(p.read_text(errors="replace") for p in pages)
runbooks = {p.stem for p in pages}
for f, alert in alerts:
    if alert not in runbooks and alert not in corpus:
        errors.append(f"{f}: alert {alert} heeft geen runbook in "
                      "docs/rules/ (eigen pagina of vermelding)")

for e in errors:
    print(e)
print(f"\nregels: {len(alerts)} alerts over "
      f"{len(runbooks)} runbook-pagina's; fouten: {len(errors)}")
sys.exit(1 if errors else 0)
EOF

if command -v promtool >/dev/null && command -v yq >/dev/null; then
  while IFS= read -r f; do
    yq eval '.spec' "$f" | promtool check rules /dev/stdin >/dev/null \
      || { echo "verify FAALT: promtool wijst $f af" >&2; exit 1; }
  done < <(find prometheus/rules -name '*.yaml' | sort)
  echo "verify: OK (structuur + runbook-dekking + promtool)"
else
  echo "verify: OK (structuur + runbook-dekking; promtool NIET beschikbaar" \
       "— PromQL-syntax niet gecontroleerd)"
fi

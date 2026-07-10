---
last_reviewed: 2026-07-10
owner: mark
---

# Alerting (Slack + SOPS)

## Overzicht
- Alertmanager config (routes/receivers): **inline** in
  `stack/values.yaml` onder `alertmanager.config` — dáár wijzig je
  routing.
- Slack secret (SOPS): `alerting/secret-alertmanager.sops.yaml`,
  gemount via `alertmanager.alertmanagerSpec.secrets:
  [alertmanager-slack-webhook]`; de webhook wordt gelezen via
  `api_url_file`.
- **Legacy**: `alerting/alertmanager.yaml` (ConfigMap voor het oude
  `configMapOverrideName`-mechanisme) wordt nergens meer gerefereerd —
  kandidaat voor verwijdering na teambevestiging (semantische review
  2026-07-10).

## Repo-server (Argo CD) voorbereiden
- Zorg dat `argocd-repo-server` kan decrypten met SOPS/age:
  - Binary `sops` aanwezig (image of sidecar)
  - Private key gemount, bijv. `/etc/sops/age.agekey`
  - Env: `SOPS_AGE_KEY_FILE=/etc/sops/age.agekey`

## Secret versleutelen (lokaal)
```bash
# Vereist: age, sops, python3-yaml
export SLACK_WEBHOOK_URL='https://hooks.slack.com/services/XXX/YYY/ZZZ'
./bootstrap_sops.sh
# Dit maakt of overschrijft alerting/secret-alertmanager.sops.yaml (encrypted)
# Commit & push
```

## Migratie van tijdelijke secret (indien gebruikt)
```bash
kubectl -n monitoring delete secret alertmanager-slack-webhook
# Argo maakt nu de SOPS-secret aan bij de volgende sync
```

## Slack kanaal wijzigen
- Pas in `alerting/alertmanager.yaml` de `slack_configs[].channel` aan (bijv. `#k8s-alerts`).
- Commit & push; Argo sync → Alertmanager herlaadt.

## Test
1. Forceer een testalert (zie docs/rules/* voor voorbeelden)
2. Controleer Alertmanager UI (active alerts)
3. Bevestig ontvangst in Slack-kanaal


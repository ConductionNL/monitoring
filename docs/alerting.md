---
last_reviewed: 2026-08-10
owner: info@conduction.nl
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
- **Opgeruimd (2026-07-10)**: de legacy ConfigMap
  `alerting/alertmanager.yaml` (oude `configMapOverrideName`-route) is
  uit de repo verwijderd. Leeft de gelijknamige ConfigMap nog als wees
  op het cluster, dan is opruimen mensenwerk — eerst mounts checken.
- **Stub-status (2026-07-13)**: `alerting/secret-alertmanager.sops.yaml`
  is nog een placeholder van één regel — er is hier nog niets écht
  versleuteld. Het hieronder genoemde `bootstrap_sops.sh` staat (nog)
  niet in `scripts/`; wie de secret echt aanmaakt, volgt de
  sops-procedure handmatig of zet dat script eerst terug. `.sops.yaml`
  heeft inmiddels wél beide recipients, zodat een bootstrap direct naar
  twee sleutels versleutelt.

## Log-alerts lopen níét via Alertmanager (2026-08-10)

De alerts onder `loki/alerts/` zijn Grafana Unified Alerting-regels, geen
`PrometheusRule`. Ze worden door Grafana geëvalueerd tegen de
Loki-datasource en gaan **niet** door de routes en receivers hierboven.
Een matcher toevoegen aan `alertmanager.config` doet voor deze alerts dus
niets.

Waar ze wél uitkomen, bepaalt een Grafana **contact point**. Dat is nog
niet ingericht: `notification_settings` staat uitgecommentarieerd in
`loki/alerts/hydra-pipeline-failures.yaml`. Tot dat gebeurt is
`HydraPipelineFailure` alleen zichtbaar in de Grafana-alertlijst en stuurt
hij geen Slack-bericht. Zie `docs/rules/HydraPipelineFailure.md`.

## Key-custody (review WP4, 2026-07-13)

Twee age-recipients in `.sops.yaml`; alles wordt naar beide versleuteld,
elk van de twee private keys kan ontsleutelen:

| Sleutel | Publieke recipient | Private key leeft | Custodian |
|---|---|---|---|
| primair | `age1wr3t…c8nd33` | con-prod (Secret `sops-age`, ns `con-ci`) + operator-backup | operator (mark) |
| escrow | `age13zm…zfndpx` | offline escrow (nooit op cluster, nooit in git) | info@conduction.nl |

Zelfde sleutelpaar als de talos runner-secrets (besluit WP4: één paar
volstaat op deze schaal). Rotatie: nieuwe key genereren, recipient
toevoegen aan `.sops.yaml`, `sops updatekeys` per bestand, oude
recipient verwijderen, nogmaals `updatekeys` — plaintext hoeft er nooit
opnieuw in. Uitgebreider rotatiepad: talos
`manifests/components/runner-secrets/README.md`.

> **Openstaand (2026-08-10): `loki/secret-loki-s3.sops.yaml` is niet te
> ontsleutelen.** Dat bestand is op 2026-04-03 versleuteld naar één
> recipient, `age1l2k98…dyehmy`, en die staat níét in `.sops.yaml` en
> niet in de tabel hierboven — hij dateert van vóór de WP4-sleutelwissel.
> `argocd-repo-server` heeft alleen de primaire key en kan er dus niets
> mee. De S3-credentials moeten opnieuw gezaaid worden (plaintext
> opnieuw invoeren, versleutelen naar beide recipients hierboven);
> `sops updatekeys` volstaat niet, want niemand heeft de oude private
> key nog. Dit is mensenwerk en moet vóór de Loki-uitrol gebeuren.



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
- Het kanaal wordt bepaald door de incoming-webhook-URL zelf (er staat
  geen `channel:` in `slack_configs`; de webhook is aan één kanaal
  gebonden).
- Maak in Slack een webhook aan voor het nieuwe kanaal en versleutel die
  opnieuw via `bootstrap_sops.sh` (zie "Secret versleutelen" hierboven).
- Commit & push; Argo sync → Alertmanager herlaadt.

## Test
1. Forceer een testalert (zie docs/rules/* voor voorbeelden)
2. Controleer Alertmanager UI (active alerts)
3. Bevestig ontvangst in Slack-kanaal


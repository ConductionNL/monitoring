---
last_reviewed: 2026-08-10
owner: info@conduction.nl
---

# HydraPipelineFailure

- Bron: `loki/alerts/hydra-pipeline-failures.yaml`
- Alert: `HydraPipelineFailure`
- Severity: `warning`

## Betekenis
Pods in een namespace die matcht op `hydra.*` loggen ERROR-regels met het
woord "pipeline". De alert komt niet uit Prometheus maar uit **Grafana
Unified Alerting**, dat een LogQL-query op de Loki-datasource evalueert.
Dit is de enige alert in deze repo die op logregels vuurt in plaats van op
metrics.

## Trigger
- `count_over_time({namespace=~"hydra.*"} |= "ERROR" |= "pipeline" [5m]) > 0` (for: 5m)
- Evaluatie-interval 1m, groep `loki-log-alerts` in Grafana-folder `Loki`.

## Runbook
1. Open Grafana Explore, kies de Loki-datasource en herhaal de query:
   `{namespace=~"hydra.*"} |= "ERROR" |= "pipeline"`.
2. Zoom in op de falende pod: `{namespace="<namespace>", pod="<pod>"} |= "ERROR"`.
3. Bekijk de podstatus op restarts, OOMKills of pending:
   `kubectl -n <namespace> describe pod <pod>`.
4. Controleer de bron waar de pipeline uit leest (API, database, queue) en de
   Argo CD-syncstatus van die namespace op recente wijzigingen.
5. Komt de fout uit een bekende, geaccepteerde situatie, pas dan de query in
   `loki/alerts/hydra-pipeline-failures.yaml` aan in plaats van de alert te
   dempen.

## Verwachte routing
- **Nog geen.** De regel heeft bewust geen `notification_settings`; er is in
  Grafana nog geen contact point ingericht. De alert is zichtbaar in de
  Grafana-alertlijst en stuurt geen Slack-bericht. Alertmanager (en dus
  `docs/alerting.md`) staat hier buiten: Grafana-alerts lopen niet via
  `stack/values.yaml` onder `alertmanager.config`.

## Test (non-prod)
- Draai een pod in een namespace die op `hydra` begint en laat die een regel
  met zowel `ERROR` als `pipeline` naar stdout schrijven; na ±5m hoort de
  regel in Grafana op Firing te staan.

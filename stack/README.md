# Stack

Helm values voor de **enige** monitoring-stack (kube-prometheus-stack): Prometheus, Alertmanager, Grafana, Prometheus Operator en default rules in één release.

- **`values.yaml`** – enige values-bestand voor die chart. Bevat config voor prometheus, alertmanager, grafana, defaultRules, additionalServiceMonitors.

Geen `overlays/prod` of andere omgevingen: er is één monitoring, dus één values-bestand. Argo CD gebruikt `$values/stack/values.yaml` (zie `apps/app-prom-prod.yaml`).

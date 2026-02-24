# Prometheus (GitOps)

Alle Prometheus-gerelateerde configuratie staat onder deze directory.

## Structuur

- **`rules/`** – PrometheusRule CRD’s, per domein in subdirectories:
  - `coredns/` – CoreDNS health en extended alerts
  - `deploy/` – Deployment health (unavailable replicas)
  - `hpa/` – HPA maxed out
  - `images/` – ImagePull errors
  - `ingress/` – Ingress 5xx
  - `certmanager/` – Certificate expiry
  - `pods/` – Pod pending, CreateContainerConfigError
  - `storage/` – PVC usage

Regels worden door Prometheus opgepikt via `ruleSelector.matchLabels.release: mon` (zie `overlays/prod/values-prom-stack.yaml`).

## Scrape-config en overige Prometheus-instellingen

- **Helm values**: `overlays/prod/values-prom-stack.yaml` onder `prometheus.prometheusSpec` (retention, resources, ruleSelector) en `additionalServiceMonitors` voor extra scrape targets.
- Er is geen aparte `prometheus.yaml`; de Prometheus Operator genereert de config uit ServiceMonitors en de values.

## Documentatie per alert

Runbooks en uitleg per alert: `docs/rules/<AlertName>.md`. De Slack-meldingen linken naar die bestanden.

## Industrie-afspraak

Component-gebaseerde indeling: alles wat bij **Prometheus** hoort (rules, en via values scrape/retention) staat hier of wordt hiernaar verwezen; Grafana en Alertmanager hebben eigen top-level directories (`grafana/`, `alerting/`).

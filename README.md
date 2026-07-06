# Monitoring GitOps (private repo) — Starter

**Stack**: Argo CD (multiple sources) + kube-prometheus-stack (Prometheus Operator) + Alertmanager + Grafana.
**Secrets**: SOPS (age). Repo is **private**; geen plaintext secrets.

## Repo-structuur (component-gebaseerd)

Alles is per **component** georganiseerd; uitbreiding met extra componenten (bijv. Loki, Tempo) volgt hetzelfde patroon.

```
monitoring/
├── apps/                    # Argo CD Applications (welke paden gesynct worden)
├── prometheus/              # Alles Prometheus-gerelateerd
│   ├── README.md
│   └── rules/               # PrometheusRule CRD's, per domein
│       ├── coredns/
│       ├── deploy/
│       ├── hpa/
│       ├── images/
│       ├── ingress/
│       ├── certmanager/
│       ├── pods/
│       └── storage/
├── grafana/                 # Alles Grafana-gerelateerd
│   ├── README.md
│   └── dashboards/          # ConfigMaps (label grafana_dashboard)
├── alerting/                # Alertmanager + event-routing
│   ├── alertmanager-managed-config.yaml
│   ├── secret-alertmanager.sops.yaml
│   └── argo-events/         # Webhook/autofix
├── stack/                   # Helm values (één monitoring-stack)
│   ├── README.md
│   └── values.yaml
├── docs/                    # Runbooks, uitleg per alert
│   ├── README.md
│   ├── rules/               # Eén .md per alert (Slack linkt hiernaar)
│   ├── alerting.md
│   └── ROADMAP.md
├── tests/                   # Connectivity / smoke tests
└── scripts/
```

**Afspraak**: Elke alert heeft documentatie in `docs/rules/<AlertName>.md`. Prometheus-config (rules, scrape) in `prometheus/` of via values; Grafana (dashboards, datasource) in `grafana/` of values; Alertmanager in `alerting/`.

## Inhoud (kort)

- **GitOps**: Argo CD haalt de Helm chart `kube-prometheus-stack` en past jullie values toe. Geen lokaal `helm install`. Zie `apps/app-prom-prod.yaml` voor alle sources (`prometheus/rules/*`, `grafana/dashboards`, `alerting`, values).
- **Configuratie in Git**: Stack-values in `stack/values.yaml`; dashboards in `grafana/dashboards/`; Prometheus-rules in `prometheus/rules/`; Alertmanager in `alerting/`. Zie `prometheus/README.md` en `grafana/README.md`.
- **Secrets**: SOPS (age). Slack webhook in `alerting/secret-alertmanager.sops.yaml`; lokaal genereren via `./bootstrap_sops.sh`.

## Bootstrap (lokaal, vóór eerste commit)

1. Installeer SOPS en age.
2. Genereer age key en versleutel Slack webhook:
   ```bash
   ./bootstrap_sops.sh
   ```
3. Argo CD repo-server: age private key in cluster (SOPS decrypt tijdens sync).
4. **Syncen**: `kubectl -n argocd apply -f apps/app-prom-prod.yaml`
5. **Verifiëren**: port-forward naar Prometheus (9090), Alertmanager (9093), Grafana (3000) — zie `docs/index.md` voor exacte commando’s.

## Belangrijke keuzes

- Repo is private; secrets via SOPS.
- Eén bron van waarheid: PrometheusRule-bestanden in `prometheus/rules/`; dashboards in `grafana/dashboards/`.
- Component-mappen: `prometheus/`, `grafana/`, `alerting/` (later uitbreidbaar).

## Cleanup/Notes

- Pas namespace of Slack-kanaal aan naar jullie werkelijkheid.
- Voeg nieuwe rules toe onder `prometheus/rules/<domein>/`, nieuwe dashboards onder `grafana/dashboards/`.

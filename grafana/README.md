# Grafana-configuratie (GitOps)

Alle Grafana-configuratie die we willen borgen staat in deze repo. **Secrets** (zoals OAuth client_secret) staan **niet** in de repo; die komen uit een lokaal `.env` bestand (gitignored) en worden als Kubernetes Secret in het cluster gezet.

## Keycloak OAuth (Generic OAuth)

Grafana kan aan Keycloak gekoppeld worden voor login. **Standaard staat dit uit** in de values, zodat een push niet breekt als het Secret `grafana-keycloak-oauth` nog niet bestaat.

De **niet-geheime** configuratie staat in Git (nu uitgecommentarieerd in `stack/values.yaml`):

- **Helm values**: `stack/values.yaml` → `grafana.grafana.ini` (server.root_url staat aan; Keycloak-block staat uitgecommentarieerd). Om Keycloak aan te zetten: uncomment de `auth.generic_oauth`-sectie en `envFromSecret: grafana-keycloak-oauth`, maak het Secret (zie hieronder), en sync opnieuw.
- **Secret**: `client_id` en `client_secret` komen uit een Kubernetes Secret `grafana-keycloak-oauth`, die je lokaal aanmaakt vanuit een **`.env`** bestand (niet committen).

### Secret uit .env zetten

1. Kopieer het voorbeeldbestand en vul het geheim in:
   ```bash
   cp grafana/.env.example grafana/.env
   # Bewerk grafana/.env en zet GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET op de echte waarde
   ```
2. Maak (of werk bij) het Secret in het cluster:
   ```bash
   ./scripts/grafana-oauth-secret.sh
   # Optioneel: ./scripts/grafana-oauth-secret.sh <namespace>
   ```
3. `.env` staat in `.gitignore`; commit het nooit. Voor een nieuw cluster of nieuwe omgeving: opnieuw `.env` vullen en het script draaien.

Grafana leest de env vars `GF_AUTH_GENERIC_OAUTH_CLIENT_ID` en `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET` uit dit Secret (`envFromSecret` in de values).

## Datasource

- **Prometheus** wordt expliciet in Git gezet via Helm values:
  - `stack/values.yaml` → `grafana.sidecar.datasources`
  - URL: `http://mon-kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090`

Geen handmatige configuratie in de Grafana UI nodig; na sync is de datasource beschikbaar.

## Dashboards

- **`dashboards/`**: ConfigMaps met label `grafana_dashboard: "1"`.
  - De kube-prometheus-stack Grafana sidecar laadt deze automatisch.
  - Elke ConfigMap: `data.<bestandsnaam>.json` = dashboard-JSON.
  - Voorbeelden: `node-overview.yaml` (node load / load per core, o.a. voor NodeSystemSaturation).

Nieuwe dashboards toevoegen:

1. Maak een nieuwe YAML in `grafana/dashboards/` (of exporteer bestaand dashboard uit Grafana als JSON).
2. ConfigMap met `metadata.labels.grafana_dashboard: "1"` en `namespace: monitoring`.
3. Commit + push; Argo CD synct → sidecar laadt het dashboard.

## Prometheus-configuratie (GitOps)

- **Rules**: `prometheus/rules/*` (PrometheusRule CRD’s), geselecteerd via `release: mon` in `stack/values.yaml`.
- **Scrape-config**: o.a. via `additionalServiceMonitors` in `stack/values.yaml`.
- **Alertmanager**: routing/receivers in `alerting/alertmanager-managed-config.yaml` (Secret) en eventueel values.

Alles wat we willen versioneren staat dus in Git; alleen de Helm chart zelf komt van de community repo.

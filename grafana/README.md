# Grafana-configuratie (GitOps)

Alle Grafana-configuratie die we willen borgen staat in deze repo. **Secrets** (zoals OAuth client_secret) staan **niet** in de repo; die komen uit een lokaal `.env` bestand (gitignored) en worden als Kubernetes Secret in het cluster gezet.

## Keycloak OAuth (Generic OAuth)

Grafana is gekoppeld aan Keycloak voor login. Je **maakt geen nieuwe secrets in Keycloak** – je gebruikt de **client secret die Keycloak al toont** bij je client (realm **commonground**, client `grafana`). Die waarde zet je lokaal in `grafana/.env`; het script maakt daar een Kubernetes Secret van zodat Grafana die kan gebruiken.

- **In Git**: `stack/values.yaml` → `grafana.grafana.ini` (auth.generic_oauth met urls, scopes, enz.) en `extraSecretMounts` (Secret als bestanden onder `/etc/grafana/secrets/oauth`). Client_id en client_secret worden uit die bestanden gelezen via `$__file{...}`.
- **Niet in Git**: de client secret uit Keycloak → in `grafana/.env` → script → K8s Secret `grafana-keycloak-oauth` (keys: `GF_AUTH_GENERIC_OAUTH_CLIENT_ID`, `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET`).

### Secret uit Keycloak naar het cluster

1. In Keycloak heb je al: realm **commonground**, client `grafana`, client secret (tab Credentials). **Kopieer die secret** – die gebruik je hier.
2. Lokaal:
   ```bash
   cp grafana/.env.example grafana/.env
   # Bewerk grafana/.env: zet GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET op de waarde uit Keycloak (client_id staat al op grafana)
   ```
3. Maak het Kubernetes Secret (eenmalig, of bij wijziging van de secret):
   ```bash
   ./scripts/grafana-oauth-secret.sh
   ```
4. `.env` staat in `.gitignore`; commit het nooit. Voor een ander cluster: opnieuw dezelfde Keycloak secret in `.env` zetten en het script draaien.

Grafana leest daarna `GF_AUTH_GENERIC_OAUTH_CLIENT_ID` en `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET` uit het Secret.

### Keycloak-login zie je niet?

1. **Secret en mount controleren**
   ```bash
   kubectl -n monitoring get secret grafana-keycloak-oauth
   kubectl -n monitoring get deployment mon-grafana -o yaml | grep -A10 extraSecretMounts
   # of: grep -A5 "oauth-secret\|secrets/oauth"
   ```
   De deployment moet een volume hebben dat `grafana-keycloak-oauth` mount op `/etc/grafana/secrets/oauth`. Zo niet: Argo CD opnieuw syncen (values hebben `extraSecretMounts`).

2. **Grafana herstarten** (zodat de pod het Secret laadt)
   ```bash
   kubectl -n monitoring rollout restart deployment mon-grafana
   ```
   Wacht tot de nieuwe pod Running is, open dan https://grafana.commonground.nu in een **incognitovenster** of hard refresh (Ctrl+Shift+R). Je zou nu **"Sign in with Keycloak"** moeten zien.

- **Redirect URI in Keycloak**  
  Bij de client (realm **commonground**) onder **Valid redirect URIs** minimaal:
  - `https://grafana.commonground.nu/login/generic_oauth`  
  Onder **Web origins** (indien aanwezig): `https://grafana.commonground.nu` of `+`.

4. **Logs bij login-fout**
   ```bash
   kubectl -n monitoring logs -l app.kubernetes.io/name=grafana --tail=100 | grep -i oauth
   ```

5. **Debugscript** (zichtbaar wat de pod ziet):
   ```bash
   ./scripts/grafana-debug-oauth.sh
   ```
   Controleer: bestaat `/etc/grafana/secrets/oauth`? Staat in `grafana.ini` de sectie `[auth.generic_oauth]` met `enabled = true`? Zo niet, dan geeft de Helm chart de values niet door aan de Grafana-subchart.

## Datasource

- **Prometheus** wordt expliciet in Git gezet via Helm values:
  - `stack/values.yaml` → `grafana.sidecar.datasources`
  - URL: `http://mon-kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090`

Geen handmatige configuratie in de Grafana UI nodig; na sync is de datasource beschikbaar.

## Dashboards

- **`dashboards/`**: ConfigMaps met label `grafana_dashboard: "1"`.
  - De kube-prometheus-stack Grafana sidecar laadt deze automatisch.
  - Elke ConfigMap: `data.<bestandsnaam>.json` = dashboard-JSON.
  - **Alert-history dashboards** (per veelvoorkomende alert):
    - `node-overview.yaml` – node load / load per core (NodeSystemSaturation).
    - `node-disk-io.yaml` – **NodeDiskIOSaturation**: disk IO queue (aqu-sq), utilization, read/write throughput. Link naar runbook in dashboard.
  - **Overzichten**:
    - `cluster-overview.yaml` – cluster: nodes, namespaces, pods, node CPU/memory, pods per namespace.
    - `nextcloud-environments.yaml` – Namespace-overzicht: **bovenin het dashboard** kies je in de dropdown welke namespaces je wilt zien (lijst komt uit Prometheus, geen vaste lijst meer nodig). Optioneel: met `NEXTCLOUD_NAMESPACES` in `grafana/.env` en `./scripts/grafana-nextcloud-dashboard-apply.sh` kun je nog een ConfigMap met vaste lijst applyen.

**Kosten/resources:** De dashboards gebruiken alleen metrics die de stack al scrapet (kube-state-metrics, node-exporter, kubelet). Geen extra scrape-targets of significante resourcekosten; alleen extra Prometheus-queries wanneer iemand een dashboard open heeft.

Nieuwe dashboards toevoegen:

1. Maak een nieuwe YAML in `grafana/dashboards/` (of exporteer bestaand dashboard uit Grafana als JSON).
2. ConfigMap met `metadata.labels.grafana_dashboard: "1"` en `namespace: monitoring`.
3. Commit + push; Argo CD synct → sidecar laadt het dashboard.

## Prometheus-configuratie (GitOps)

- **Rules**: `prometheus/rules/*` (PrometheusRule CRD’s), geselecteerd via `release: mon` in `stack/values.yaml`.
- **Scrape-config**: o.a. via `additionalServiceMonitors` in `stack/values.yaml`.
- **Alertmanager**: routing/receivers in `alerting/alertmanager-managed-config.yaml` (Secret) en eventueel values.

Alles wat we willen versioneren staat dus in Git; alleen de Helm chart zelf komt van de community repo.

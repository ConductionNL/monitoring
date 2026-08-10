---
last_reviewed: 2026-08-10
owner: info@conduction.nl
---

# Monitoring documentation

Dit dossier beschrijft welke alerts we hebben, wat ze betekenen en hoe je ze test.

> **Huisstijl runbooks:** elke pagina onder `rules/` volgt bewust één vast
> sjabloon (Bron / Betekenis / Trigger / Runbook / Routing) — referentie en
> handelingsstappen op één pagina, omdat je ze tijdens een alert samen nodig
> hebt. Dit is een vastgelegde uitzondering op de één-paginatype-regel uit
> het docs-contract (techbook `docs/conventies.md`).

## Inhoud
- **PHP-FPM/PM**: Zie `phpfpm-metrics.md` voor het aanzetten van metrics (exporter + ServiceMonitor). Alerts: `rules/PhpFpmDown.md`, enz.
- **Deployments**: `rules/DeploymentUnhealthy.md`, `rules/KubeDeploymentReplicasMismatch.md` (stack-default)
- **CoreDNS**: `rules/CoreDNSNotReady.md`
- **CoreDNS (extended)**: `rules/CoreDNSExtended.md`
- **Pods**: `rules/CreateContainerConfigError.md`, `rules/PodPendingLong.md`
- **Argo CD credential-refresh**: `rules/ArgoCDCredentialRefreshStale.md`, `rules/ArgoCDCredentialRefreshJobFailed.md` — de CronJob die Argo's cluster-credentials ververst; valt die stil, dan verliest Argo binnen 24u de toegang tot alle clusters
- **Overige**: HPA (`HPAMaxedOut.md`, `KubeHpaMaxedOut.md` — stack-default, o.a. coredns), Ingress (`IngressHigh5xx.md`), certs (`CertificateExpiringSoon.md`), storage (`PVCUsageHigh.md`), images (`ImagePullError.md`), **node** (`NodeDiskIOSaturation.md`, `NodeSystemSaturation.md`), **PHP-FPM/PM** (`PhpFpmDown.md`, `PhpFpmMaxChildrenReached.md`, `PhpFpmListenQueueHigh.md`, `PhpFpmNoIdleProcesses.md`)
- **Logs (Loki)**: `rules/HydraPipelineFailure.md` — de enige alert die op logregels vuurt in plaats van op metrics.
- **Changelog & agents**: repo-changelog in `CHANGELOG.md`; het agent-cataloog (operaties, autonomie, gates) in `docs/agents.md`.

## Waar regels vandaan komen
- Regels staan in de repo onder `prometheus/rules/` als losstaande `PrometheusRule` CRD's.
- Ze worden opgepakt door Prometheus via `ruleSelector.matchLabels.release: mon`.
- **Uitzondering — logs:** de regels onder `loki/alerts/` zijn géén
  `PrometheusRule` maar Grafana Unified Alerting-regels, geleverd als
  ConfigMap met label `grafana_alert: "1"`. Prometheus ziet ze niet;
  Grafana evalueert ze tegen de Loki-datasource. `scripts/verify.sh`
  controleert beide vormen en eist voor allebei een runbook.

## Logverzameling (Loki + Alloy)
- **Loki** slaat logs op; **Alloy** draait als DaemonSet en stuurt de podlogs
  van elke node naar Loki. Beide worden uitgerold door de Argo CD-Application
  `apps/app-loki-prod.yaml` in namespace `monitoring`.
- **Wat er verzameld wordt:** alle podlogs, met labels `namespace`, `pod`,
  `container` en `node`. De namespace `kube-system` is uitgesloten. De
  exclusielijst staat in `loki/alloy-config.yaml`.
- **Hoe lang:** `retention_period: 168h` (7 dagen), in `loki/values.yaml`.
  Langer bewaren betekent meer opslag; korter betekent dat een incident van
  vorige week niet meer te reconstrueren is. Let op de PVC-grootte: 7 dagen
  moet in de 10Gi van `singleBinary.persistence` passen.
- **Opslag nu: lokale schijf, bewust en tijdelijk.** `loki.storage.type` staat
  op `filesystem` en de logs staan op de PVC van de SingleBinary-pod (10Gi).
  Reden: de enige beschikbare S3-sleutel is die van de Nextcloud-tenants en kan
  bij de object storage van alle 85 tenants. Die aan de logstack hangen is te
  veel; tot Cyso een eigen sleutel plus bucket `loki-chunks` levert draait Loki
  op schijf. Zo staat de uitrol niet stil op die vraag.
  Omzetten naar S3 raakt **vier** plekken in `loki/values.yaml` — de checklist
  staat onderaan dat bestand. `deploymentMode` hoort daarbij op topniveau, niet
  onder `loki:`; stond het fout, dan rendert de chart zonder klagen maar start
  Loki zelf nooit.
- **Opslag straks (S3):** bucket `loki-chunks`; de credentials staan als
  SOPS-secret in `loki/secret-loki-s3.sops.yaml` (custody: `docs/alerting.md`).
  **Argo CD ontsleutelt dat bestand niet** — er is geen sops-plugin en geen
  age-sleutel in de namespace `argocd`. Het is daarom uitgesloten van de
  manifest-source en wordt door een mens geplaatst:
  `kubectl -n monitoring apply -f <(sops -d loki/secret-loki-s3.sops.yaml)`.
  Neem het níét op in een Argo-source: dan landt `ENC[...]` als wachtwoord in
  het cluster.
- **Bevragen:** Grafana → Explore → datasource `Loki`, bijvoorbeeld
  `{namespace="monitoring"} |= "ERROR"`.

## Routing van alerts
- Alertmanager configuratie (routes/receivers): inline in `stack/values.yaml`
  onder `alertmanager.config` — zie `docs/alerting.md` voor de details.
- Slack webhook (SOPS secret): `alerting/secret-alertmanager.sops.yaml`
- Voor e-mail of extra kanalen: voeg een receiver toe onder
  `alertmanager.config.receivers` in `stack/values.yaml` en (indien nodig)
  een extra secret.

## Testen
- Forceer een bekende conditie (zie elk rule-document) en controleer in:
  - Prometheus UI: Alerts tab
  - Alertmanager UI: actieve alerts en routing
  - Slack/e-mail: ontvangst van notificatie

### Port-forward UIs
```bash
# Prometheus
kubectl -n monitoring port-forward svc/mon-kube-prometheus-stack-prometheus 9090:9090
# open http://127.0.0.1:9090

# Alertmanager
kubectl -n monitoring port-forward svc/mon-kube-prometheus-stack-alertmanager 9093:9093
# open http://127.0.0.1:9093

# Grafana (optioneel, indien service aanwezig)
kubectl -n monitoring port-forward svc/mon-grafana 3000:80
# open http://127.0.0.1:3000 (user/pass via Secret grafana-admin)
```

### Connectivity tests (handmatig)
- Slack smoke (gebruikt bestaand Secret):
  ```bash
  kubectl -n monitoring create -f tests/connectivity/job-slack-smoke.yaml
  kubectl -n monitoring wait --for=condition=complete job -l app=connectivity-smoke --timeout=120s
  ```
- Egress/DNS check:
  ```bash
  kubectl -n monitoring create -f tests/connectivity/job-egress-dns.yaml
  kubectl -n monitoring wait --for=condition=complete job -l app=connectivity-smoke --timeout=120s
  ```

Opmerking: een automatische CI-run na push is voorlopig uitgeschakeld i.v.m. roterende kubeconfig. Zie `ROADMAP.md` (repo-root) voor het plan (ServiceAccount + stabiel kubeconfig-secret voor CI).


---
last_reviewed: 2026-07-06
owner: mark
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
- **Overige**: HPA (`HPAMaxedOut.md`, `KubeHpaMaxedOut.md` — stack-default, o.a. coredns), Ingress (`IngressHigh5xx.md`), certs (`CertificateExpiringSoon.md`), storage (`PVCUsageHigh.md`), images (`ImagePullError.md`), **node** (`NodeDiskIOSaturation.md`, `NodeSystemSaturation.md`), **PHP-FPM/PM** (`PhpFpmDown.md`, `PhpFpmMaxChildrenReached.md`, `PhpFpmListenQueueHigh.md`, `PhpFpmNoIdleProcesses.md`)
- **Changelog & agents**: repo-changelog in `CHANGELOG.md`; afspraken voor meerdere Cursor-agents in `docs/AGENTS.md`.

## Waar regels vandaan komen
- Regels staan in de repo onder `prometheus/rules/` als losstaande `PrometheusRule` CRD's.
- Ze worden opgepakt door Prometheus via `ruleSelector.matchLabels.release: mon`.

## Routing van alerts
- Alertmanager configuratie: `alerting/alertmanager.yaml`
- Slack webhook (SOPS secret): `alerting/secret-alertmanager.sops.yaml`
- Voor e-mail of extra kanalen: voeg een receiver toe in `alerting/alertmanager.yaml` en (indien nodig) een extra secret.

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


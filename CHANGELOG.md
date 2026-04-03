# Changelog

Alle belangrijke wijzigingen aan deze repo worden hier vastgelegd. Formaat gebaseerd op [Keep a Changelog](https://keepachangelog.com/nl/1.0.0/).

## [Unreleased]

### Toegevoegd
- `loki/values.yaml` — Helm values voor grafana/loki (SingleBinary, S3-opslag, 7d retentie)
- `loki/alloy-values.yaml` — Helm values voor grafana/alloy (DaemonSet log-collectie)
- `loki/alloy-config.yaml` — Alloy pipeline config (Kubernetes pod discovery, namespace/pod/container/node labels, kube-system exclusie)
- `loki/datasource-loki.yaml` — Grafana sidecar datasource ConfigMap voor Loki
- `loki/alerts/hydra-pipeline-failures.yaml` — HydraPipelineFailure LogQL alert rule via Grafana Alerting (Slack routing: TODO, wordt apart opgepakt)
- `loki/secret-loki-s3.sops.yaml` — SOPS-versleuteld Secret met S3-credentials
- `apps/app-loki-prod.yaml` — ArgoCD Application voor Loki stack (multi-source: Loki chart + Alloy chart + Git manifests)
- `docs/rules/HydraPipelineFailure.md` — runbook voor log-gebaseerde Hydra pipeline alert
- `openspec/changes/loki-stack/` — OpenSpec change: proposal, specs, design, tasks

### Gewijzigd
- `stack/values.yaml` — `unified_alerting.enabled: true` toegevoegd aan `grafana.ini` (vereist voor Grafana Alerting)
- `.sops.yaml` — creation rule voor `loki/secret-*.sops.yaml` toegevoegd

- `grafana/.env.example` — `NEXTCLOUD_NAMESPACES` (komma-gescheiden) voor Nextcloud-dashboard; script leest dit en past dashboard in cluster aan
- `scripts/grafana-nextcloud-dashboard-apply.sh` — past Nextcloud-dashboard toe met namespaces uit `grafana/.env`
- `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml` — PHP-FPM/PM-alerts (PhpFpmDown, PhpFpmMaxChildrenReached, PhpFpmListenQueueHigh, PhpFpmNoIdleProcesses)
- `docs/rules/PhpFpmDown.md`, `PhpFpmMaxChildrenReached.md`, `PhpFpmListenQueueHigh.md`, `PhpFpmNoIdleProcesses.md` — runbooks voor PM-alerts
- `docs/phpfpm-metrics.md` — uitleg exporter + ServiceMonitor voor PHP-FPM metrics
- `grafana/dashboards/cluster-overview.yaml` — cluster-overview (nodes, namespaces, pods, node CPU/memory, pods per namespace)
- `grafana/dashboards/nextcloud-environments.yaml` — Nextcloud-omgevingen (filter op namespace-regex, pods/deployments, CPU/memory per pod)
- `grafana/dashboards/node-disk-io.yaml` — dashboard NodeDiskIOSaturation (disk IO queue, utilization, read/write), met link naar runbook
- `docs/rules/DeploymentUnhealthy.md` — runbook voor DeploymentUnhealthy-alert
- `docs/rules/KubeHpaMaxedOut.md` — documentatie KubeHpaMaxedOut (stack vs eigen HPAMaxedOut)
- `docs/rules/NodeSystemSaturation.md` — runbook NodeSystemSaturation (node load, extreme waarden)
- `grafana/dashboards/node-overview.yaml` — node-overview dashboard
- `grafana/README.md` — documentatie Grafana-dashboards
- `docs/AGENTS.md` — afspraken voor multi-agent werk en changelog
- `.cursor/rules/changelog-and-agents.mdc` — Cursor rule: changelog bijwerken en agent-coördinatie
- `CHANGELOG.md` — dit bestand

### Gewijzigd
- `apps/app-prom-prod.yaml` — source `prometheus/rules/nextcloud` toegevoegd voor PHP-FPM rules
- `grafana/README.md` — Nextcloud-namespaces via .env + script; dashboards-sectie
- `docs/README.md` — PHP-FPM/PM rules en link naar phpfpm-metrics.md
- `README.md` — inhoud/documentatie
- `docs/README.md` — overzicht rules, testen en verwijzing naar CHANGELOG/AGENTS
- `apps/app-prom-prod.yaml` — Argo CD app configuratie
- `stack/values.yaml` (voorheen overlays/prod/values-prom-stack.yaml) — Helm values (o.a. alert routing, runbook-links naar `docs/rules/`)
- `docs/rules/HPAMaxedOut.md` — aanpassingen runbook
- Verwijzingen `doc/` → `docs/` in o.a. CHANGELOG, docs/AGENTS.md, .cursor/rules, docs/README.md, docs/ROADMAP.md, docs/alerting.md, docs/rules/HPAMaxedOut.md, stack/values.yaml, alertmanager-managed-config.yaml

### Opmerking
- Wijzigingen door Cursor-agents: zie `docs/AGENTS.md` voor afspraken. Elke agent werkt bij voorkeur in eigen deel en werkt **CHANGELOG.md** bij bij commits.

---

## Template voor nieuwe entries (boven [Unreleased])

```markdown
## [Unreleased]

### Toegevoegd
- bestand of feature — korte beschrijving

### Gewijzigd
- bestand — wat er veranderd is

### Verwijderd
- (indien van toepassing)
```

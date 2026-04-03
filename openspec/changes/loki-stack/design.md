## Context

The monitoring repository manages a kube-prometheus-stack deployment via ArgoCD with a component-based directory structure (`prometheus/`, `grafana/`, `alerting/`, `stack/`). Each component is either a Helm source or a plain-manifest source in the ArgoCD Application's multi-source list. Grafana runs at `grafana.commonground.nu` with Keycloak OAuth, sidecar-loaded dashboards (label `grafana_dashboard: "1"`), and sidecar-discovered datasources. Secrets are SOPS-encrypted with age. Alertmanager routes to Slack via an encrypted webhook.

There is currently no log aggregation — adding Loki fills this gap without touching existing components.

## Goals / Non-Goals

**Goals:**

- Deploy Loki + Alloy as a self-contained component alongside the existing stack
- Enable LogQL queries in Grafana Explore
- Demonstrate log-based alerting to Slack via Grafana Alerting
- Design for production object storage from day one (even if filesystem is used initially)

**Non-Goals:**

- Modifying any existing Prometheus, Alertmanager, or Grafana configuration files
- Deploying Tempo or any tracing infrastructure
- Running the Loki ruler — all alerting goes through Grafana unified alerting
- Auto-remediation via Argo Events for log-based alerts (future work)

## Decisions

### D1: Separate ArgoCD Application (not merged into app-prom-prod)

Add `apps/app-loki-prod.yaml` as an independent Application rather than adding Loki sources to the existing `app-prom-prod.yaml`.

**Rationale:** Keeps blast radius isolated — a broken Loki config cannot block Prometheus syncs. Matches the principle that each Application owns one concern. Allows independent sync/rollback.

**Alternative considered:** Adding Loki as additional sources in `app-prom-prod.yaml`. Rejected because it couples unrelated lifecycle — Loki upgrades shouldn't require the Prometheus app to re-sync.

### D2: `grafana/loki` Helm chart in single-binary mode

Use the upstream `grafana/loki` chart (v6.x+) in single-binary (`deploymentMode: SingleBinary`) mode for initial deployment.

**Rationale:** Single-binary is simplest to operate and sufficient for the current log volume. The chart supports switching to simple-scalable mode later by changing `deploymentMode` without restructuring config files.

**Alternative considered:** `grafana/loki-stack` meta-chart (bundles Loki + Promtail). Rejected because it ships Promtail (not Alloy) and adds unnecessary coupling.

### D3: Alloy via standalone `grafana/alloy` Helm chart

Deploy Alloy using the standalone `grafana/alloy` chart as a second Helm source in the ArgoCD Application, rather than bundling it with Loki.

**Rationale:** Keeps Alloy lifecycle independent from Loki. Allows upgrading the collection agent without touching the storage engine. The Alloy chart is actively maintained and is Grafana's strategic direction.

**Alternative considered:** Configuring Alloy as a sub-chart of `grafana/loki`. Rejected — the loki chart doesn't bundle Alloy natively, and sub-chart wiring adds complexity.

### D4: Grafana datasource via sidecar ConfigMap

Create `loki/datasource-loki.yaml` as a ConfigMap with the appropriate sidecar label, deployed as a plain manifest source in the ArgoCD Application.

**Rationale:** Matches exactly how the existing Prometheus datasource works — sidecar auto-discovery, no manual Grafana configuration needed. The datasource sidecar label needs to be verified from `stack/values.yaml` (likely `grafana_datasource: "1"` but may differ).

**Alternative considered:** Adding the Loki datasource to `stack/values.yaml` under `grafana.additionalDataSources`. Rejected because it would modify the existing values file, violating the constraint that existing configs are untouched.

### D5: Grafana Alerting for log-based alerts (not Loki ruler)

Configure log-based alert rules through Grafana's provisioning API (alert rule ConfigMaps or GrafanaAlertRuleGroup CRs), not through Loki's built-in ruler.

**Rationale:** Avoids running a second alerting engine. Grafana unified alerting supports LogQL datasource queries natively. Notifications route through Grafana's contact points, which can be configured to use the same Slack webhook as Alertmanager without duplicating receiver config.

**Alternative considered:** Loki ruler with AlertManager integration. Rejected — adds operational complexity (ruler ring, WAL) and would require routing to the existing Alertmanager, creating coupling.

### D6: Storage abstraction via values sections

Structure `loki/values.yaml` with a clearly commented storage section that switches between `filesystem` and `s3` backends. S3 credentials reference a Kubernetes Secret (SOPS-encrypted if present).

**Rationale:** Avoids hardcoding any cloud provider. Teams using Ceph RGW, MinIO, or Fuga Cloud all provide S3-compatible endpoints — the only config difference is the endpoint URL, bucket name, and credentials.

### D7: Alloy pipeline config as separate ConfigMap

Place the Alloy river config in `loki/alloy-config.yaml` rather than inlining it in values.

**Rationale:** Keeps the pipeline definition readable and under the 200-line file limit. The Alloy chart supports mounting external ConfigMaps for its config.

## Risks / Trade-offs

**[Single-binary mode limits horizontal scaling]** → Acceptable for initial deployment. Migration path to simple-scalable is a values change (`deploymentMode`), not a restructure. Monitor ingestion rate and switch when needed.

**[Filesystem storage is not production-grade]** → Designed for S3 from the start. Filesystem is a deliberate initial choice to avoid requiring object storage credentials before the first deployment. Document the switch clearly.

**[Grafana Alerting contact point may not exist yet]** → The `team-platform-slack` contact point in Grafana may need to be created if only Alertmanager currently sends to Slack. This is a one-time setup step — document in the runbook and tasks.

**[Alloy DaemonSet adds resource overhead per node]** → Alloy is lightweight (~50-100MB RAM per node). Define resource requests/limits. Acceptable trade-off for full log coverage.

**[SOPS creation rule requires `.sops.yaml` edit]** → This is the only existing file modification. It is additive (new rule, doesn't change existing rules) and low-risk.

## Migration Plan

1. **Phase 1 — Deploy with filesystem storage:** Merge the Loki stack with PVC-backed storage. Verify ArgoCD sync, Grafana datasource, and basic LogQL queries.
2. **Phase 2 — Enable alerting:** Configure Grafana contact point (if needed) and verify the HydraPipelineFailure alert fires to Slack.
3. **Phase 3 — Switch to object storage (when ready):** Update `loki/values.yaml` storage section to S3, add SOPS-encrypted credentials, re-sync.
4. **Rollback:** Delete the `app-loki-prod` ArgoCD Application. All Loki resources are pruned. No impact on existing stack.

## Open Questions — Resolved

- **Q1 — RESOLVED:** Datasource sidecar uses the chart default label `grafana_datasource: "1"` (no explicit label override in `stack/values.yaml`).
- **Q2 — RESOLVED:** Unified alerting is NOT enabled. Must add `[unified_alerting] enabled = true` to `grafana.ini` via `stack/values.yaml`. This is an **additional change to an existing file** — keep it minimal (additive only).
- **Q3 — RESOLVED:** Slack contact point exists only in Alertmanager. Must provision a Grafana Slack contact point via alerting provisioning ConfigMap, referencing the same webhook Secret (or a copy).
- **Q4 — RESOLVED:** Log volume unknown. Start with single-binary mode; monitor and scale later.

## Additional Design Decisions (from Q&A)

### D8: Enable Grafana unified alerting in stack/values.yaml
Add `unified_alerting.enabled: true` under `grafana.grafana.ini` in `stack/values.yaml`. This is the one required modification to an existing file — it is additive and does not change existing alerting behavior (Alertmanager continues to work independently).

### D9: Provision Grafana Slack contact point
Create a Grafana alerting provisioning ConfigMap (`loki/alerts/grafana-contact-point.yaml`) that defines a `team-platform-slack` contact point in Grafana. The Slack webhook URL will be referenced from the existing SOPS-encrypted secret or a new SOPS secret under `loki/`.

### D10: S3-compatible object storage from day one
Configure Loki with S3 storage backend from the start. S3 credentials stored in `loki/secret-loki-s3.sops.yaml`. Filesystem mode documented as a commented fallback for local dev/testing.

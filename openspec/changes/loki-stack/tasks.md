## 1. Repository Setup

- [x] 1.1 Create `loki/` directory structure: `loki/`, `loki/alerts/`
- [x] 1.2 Add SOPS creation rule to `.sops.yaml` for `^loki/secret-.*\.sops\.yaml$` using existing age public key
- [x] 1.3 Enable Grafana unified alerting: add `unified_alerting.enabled: true` under `grafana.grafana.ini` in `stack/values.yaml`

## 2. Loki Deployment

- [x] 2.1 Create `loki/values.yaml` with `grafana/loki` chart config in SingleBinary mode
- [x] 2.2 Configure S3-compatible object storage as primary backend in `loki/values.yaml` (endpoint, bucket, region as configurable values; filesystem as commented fallback)
- [x] 2.3 Create `loki/secret-loki-s3.sops.yaml` with S3 access key and secret key, encrypted with SOPS/age
- [x] 2.4 Configure retention (default 7 days) in `loki/values.yaml`
- [x] 2.5 Set resource requests/limits for Loki pods in `loki/values.yaml`
- [x] 2.6 Disable Loki ruler in `loki/values.yaml`

## 3. Alloy Log Collection

- [x] 3.1 Add Alloy Helm chart values (DaemonSet mode) as `loki/alloy-values.yaml`
- [x] 3.2 Create `loki/alloy-config.yaml` with Kubernetes pod log discovery pipeline (namespace, pod, container, node labels)
- [x] 3.3 Configure namespace exclusion list in Alloy config (default: drop `kube-system`)
- [x] 3.4 Configure Alloy to ship logs to Loki push endpoint (`http://<loki-svc>.monitoring.svc.cluster.local:3100/loki/api/v1/push`)
- [x] 3.5 Set resource requests/limits for Alloy DaemonSet

## 4. Grafana Loki Datasource

- [x] 4.1 Create `loki/datasource-loki.yaml` ConfigMap with label `grafana_datasource: "1"` pointing to Loki query endpoint

## 5. Log-Based Alerting

- [x] ~~5.1 Grafana Slack contact point~~ — descoped (will be handled by separate SWE repo)
- [x] 5.2 Create `loki/alerts/hydra-pipeline-failures.yaml` with HydraPipelineFailure LogQL alert rule provisioned via Grafana alerting ConfigMap
- [x] ~~5.3 Alert notification routing~~ — descoped (blocked on contact point, TODO left in alert rule)

## 6. ArgoCD Application

- [x] 6.1 Create `apps/app-loki-prod.yaml` with multi-source pattern: Loki Helm chart + Git ref for values + Git path for `loki/` plain manifests
- [x] 6.2 Add Alloy Helm chart as additional source in the ArgoCD Application (separate Helm source with `loki/alloy-values.yaml`)
- [x] 6.3 Configure automated sync policy with prune, self-heal, ServerSideApply (matching existing app)
- [x] 6.4 Set destination namespace to `monitoring` with CreateNamespace=true

## 7. Documentation

- [x] 7.1 Create `docs/rules/HydraPipelineFailure.md` runbook stub (symptom, possible causes, resolution steps)
- [x] 7.2 Add inline comments in `loki/values.yaml` explaining S3 storage config, filesystem fallback, and retention

## 8. Validation

- [x] 8.1 Verify all files under `loki/` are under 200 lines
- [x] 8.2 Verify no plaintext secrets in any new files (`git diff --staged` check)
- [x] 8.3 Verify only additive change to `stack/values.yaml` (unified alerting enable)
- [x] 8.4 Verify `apps/app-prom-prod.yaml` is NOT modified
- [x] 8.5 Run `openspec validate loki-stack` to confirm all specs are covered by tasks

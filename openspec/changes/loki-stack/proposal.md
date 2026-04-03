## Why

The monitoring stack provides metrics, dashboards, and metric-based alerting but has no centralized logging. Operators rely on `kubectl logs` for troubleshooting — ephemeral, scattered across nodes, and impossible to search historically. With Hydra pipeline workloads and multi-tenant Nextcloud deployments growing, we need structured log aggregation and log-based alerting routed to the existing Slack workflow. Loki is the natural fit: it integrates natively with the existing Grafana instance, uses the same label model as Prometheus, and avoids a heavyweight Elasticsearch deployment.

## What Changes

- Add a new `loki/` top-level directory containing Helm values for Loki (log storage/query) and Alloy (log collection DaemonSet), following the existing component pattern.
- Add a Grafana Loki datasource via sidecar ConfigMap, matching the established datasource pattern.
- Add at least one LogQL-based alert rule (Hydra pipeline failures) configured through Grafana Alerting, routing to the existing Slack contact point.
- Add a new ArgoCD Application (`apps/app-loki-prod.yaml`) using the multi-source pattern so Loki deploys independently from the existing Prometheus stack.
- Add a SOPS creation rule for `loki/secret-*.sops.yaml` to support future S3 storage credentials.
- Add runbook stubs in `docs/rules/` for every new log-based alert.

## Capabilities

### New Capabilities

- `loki-log-storage`: Loki deployment for log ingestion, storage, and LogQL queries — with pluggable retention and S3-compatible storage backend.
- `alloy-log-collection`: Alloy DaemonSet for collecting pod logs via Kubernetes service discovery and shipping to Loki.
- `loki-grafana-datasource`: Grafana datasource ConfigMap enabling log exploration and LogQL queries in the existing Grafana instance.
- `loki-log-alerting`: Log-based alert rules evaluated by Grafana Alerting (not Loki ruler), with notifications to the existing Slack channel.
- `loki-argocd-app`: ArgoCD Application definition for independent GitOps deployment of the Loki stack.

### Modified Capabilities

_(none — existing Prometheus, Alertmanager, and Grafana configurations are untouched)_

## Impact

- **New Kubernetes resources**: Loki StatefulSet/Deployment, Alloy DaemonSet, associated Services, ConfigMaps, and PVCs in the `monitoring` namespace.
- **Grafana**: gains a second datasource (Loki) alongside Prometheus. Unified alerting must be enabled for log-based alerts.
- **ArgoCD**: new Application object — no changes to existing `app-prom-prod.yaml`.
- **SOPS config**: `.sops.yaml` gains an additional creation rule for `loki/` secrets.
- **Storage**: requires either local PVC (initial) or S3-compatible object storage (production) for log data.
- **Network**: Alloy pods need access to Loki push endpoint; Grafana needs access to Loki query endpoint — all within `monitoring` namespace.

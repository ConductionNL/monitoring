## ADDED Requirements

### Requirement: Loki datasource via sidecar ConfigMap
The system SHALL create a ConfigMap that the Grafana sidecar auto-discovers as a datasource. The ConfigMap MUST carry the label that the Grafana datasource sidecar watches (verify from `stack/values.yaml` — commonly `grafana_datasource: "1"`).

#### Scenario: Datasource ConfigMap deployed
- **WHEN** ArgoCD syncs the Loki application
- **THEN** a ConfigMap with the correct sidecar label exists in the `monitoring` namespace

#### Scenario: Grafana discovers Loki datasource
- **WHEN** the Grafana sidecar detects the new ConfigMap
- **THEN** a datasource named "Loki" of type `loki` appears in Grafana → Configuration → Data Sources

### Requirement: Datasource points to in-cluster Loki
The datasource URL SHALL be `http://<loki-service>.monitoring.svc.cluster.local:3100` using proxy access mode.

#### Scenario: LogQL queries work from Grafana
- **WHEN** a user opens Grafana Explore and selects the Loki datasource
- **THEN** LogQL queries return log results from the in-cluster Loki instance

### Requirement: Datasource definition in separate file
The datasource ConfigMap SHALL live in `loki/datasource-loki.yaml`, separate from Helm values.

#### Scenario: Datasource file exists
- **WHEN** the Loki directory is checked
- **THEN** `loki/datasource-loki.yaml` exists as a standalone Kubernetes ConfigMap manifest

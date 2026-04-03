## ADDED Requirements

### Requirement: Alloy deployed as DaemonSet
The system SHALL deploy Grafana Alloy as a DaemonSet for log collection, replacing Promtail as the collection agent. Alloy SHALL be deployed via Helm (standalone `grafana/alloy` chart or bundled with loki-stack).

#### Scenario: Alloy running on every node
- **WHEN** ArgoCD syncs the Loki application
- **THEN** an Alloy pod runs on every schedulable node in the cluster

### Requirement: Kubernetes pod log discovery
Alloy SHALL discover pod logs via Kubernetes service discovery and enrich log entries with labels: `namespace`, `pod`, `container`, `node`.

#### Scenario: Pod logs collected with labels
- **WHEN** a pod in any namespace writes to stdout/stderr
- **THEN** Alloy collects the log lines and attaches `namespace`, `pod`, `container`, and `node` labels before sending to Loki

### Requirement: Configurable namespace exclusions
Alloy SHALL support an exclusion list for namespaces whose logs should not be collected. By default, `kube-system` control-plane noise SHALL be dropped.

#### Scenario: Excluded namespace logs dropped
- **WHEN** a pod in `kube-system` writes logs
- **THEN** Alloy does not forward those log lines to Loki

#### Scenario: Custom exclusion list
- **WHEN** the exclusion list in `loki/alloy-config.yaml` is modified to include `test-namespace`
- **THEN** logs from `test-namespace` are no longer forwarded to Loki

### Requirement: Alloy ships to Loki push endpoint
Alloy SHALL send collected logs to the Loki push API endpoint within the cluster (`http://<loki-svc>.monitoring.svc.cluster.local:3100/loki/api/v1/push`).

#### Scenario: Logs arrive in Loki
- **WHEN** Alloy collects log lines from a running pod
- **THEN** those log lines are queryable in Loki via LogQL within the configured scrape interval

### Requirement: Alloy pipeline config in separate file
The Alloy pipeline configuration SHALL live in `loki/alloy-config.yaml`, separate from `loki/values.yaml`, and SHALL be under 200 lines.

#### Scenario: Config file exists and is within limit
- **WHEN** `loki/alloy-config.yaml` is checked
- **THEN** the file exists and contains fewer than 200 lines

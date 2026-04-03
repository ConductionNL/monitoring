## ADDED Requirements

### Requirement: Loki deployment via Helm chart
The system SHALL deploy Loki using the `grafana/loki` Helm chart in single-binary or simple-scalable mode, managed via a `loki/values.yaml` file in the repository root.

#### Scenario: Loki pods running in monitoring namespace
- **WHEN** ArgoCD syncs the Loki application
- **THEN** Loki pods are created in the `monitoring` namespace and reach Ready state

#### Scenario: Loki accepts log pushes
- **WHEN** a client sends a POST to `http://<loki-svc>.monitoring.svc.cluster.local:3100/loki/api/v1/push`
- **THEN** Loki ingests the log entries and returns HTTP 204

### Requirement: Pluggable storage backend
The system SHALL support both filesystem (PVC-backed) and S3-compatible object storage, configurable via clearly documented sections in `loki/values.yaml`. No cloud-provider-specific values SHALL be hardcoded.

#### Scenario: Filesystem storage (default)
- **WHEN** `loki/values.yaml` specifies `filesystem` as the storage type
- **THEN** Loki stores chunks and index on a PersistentVolumeClaim

#### Scenario: S3-compatible storage
- **WHEN** `loki/values.yaml` specifies `s3` as the storage type with endpoint, bucket, and credential references
- **THEN** Loki stores chunks and index in the configured S3-compatible bucket

### Requirement: Configurable retention
The system SHALL expose a retention period in `loki/values.yaml` with a default of 7 days. The retention value MUST be adjustable without changing any other configuration.

#### Scenario: Default retention applied
- **WHEN** no retention override is set
- **THEN** Loki retains logs for 7 days and deletes older data

#### Scenario: Custom retention applied
- **WHEN** retention is set to 30 days in `loki/values.yaml`
- **THEN** Loki retains logs for 30 days

### Requirement: Resource limits defined
The system SHALL define CPU and memory requests and limits for Loki pods, consistent with the sizing conventions used by Prometheus and Alertmanager in `stack/values.yaml`.

#### Scenario: Resource constraints applied
- **WHEN** Loki pods are scheduled
- **THEN** pods have explicit resource requests and limits set

### Requirement: File size limit
Each configuration file under `loki/` SHALL be under 200 lines.

#### Scenario: Values file within limit
- **WHEN** `loki/values.yaml` is checked
- **THEN** the file contains fewer than 200 lines

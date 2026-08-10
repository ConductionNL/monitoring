## ADDED Requirements

### Requirement: Log-based alerts via Grafana Alerting only
All log-based alert rules SHALL be evaluated by Grafana Alerting (unified alerting), NOT by the Loki ruler component. The Loki ruler SHALL remain disabled.

#### Scenario: Loki ruler not running
- **WHEN** the Loki deployment is inspected
- **THEN** no ruler component is running; ruler is disabled in `loki/values.yaml`

### Requirement: HydraPipelineFailure alert rule
The system SHALL include at least one example LogQL alert: `HydraPipelineFailure`, which fires when Hydra pipeline pods emit error-level logs matching a failure pattern (e.g., `{namespace=~"hydra.*"} |= "ERROR" |= "pipeline"`).

#### Scenario: Alert fires on Hydra error logs
- **WHEN** a pod in a `hydra*` namespace emits log lines containing "ERROR" and "pipeline"
- **THEN** the `HydraPipelineFailure` alert transitions to firing state in Grafana Alerting

#### Scenario: Alert notification reaches Slack
- **WHEN** `HydraPipelineFailure` fires
- **THEN** a notification is sent to the existing `team-platform-slack` contact point in Grafana, including namespace, pod name, and a log snippet

### Requirement: Alert rule stored as code
The alert rule definition SHALL be stored in `loki/alerts/hydra-pipeline-failures.yaml` as a Grafana alert provisioning ConfigMap or GrafanaAlertRuleGroup CR.

#### Scenario: Alert rule file exists
- **WHEN** the Loki directory is checked
- **THEN** `loki/alerts/hydra-pipeline-failures.yaml` exists and defines the alert rule

### Requirement: Runbook for every log-based alert
Each log-based alert SHALL have a corresponding runbook stub at `docs/rules/<AlertName>.md` following the existing runbook format (symptom, possible causes, resolution steps).

#### Scenario: HydraPipelineFailure runbook exists
- **WHEN** `docs/rules/HydraPipelineFailure.md` is checked
- **THEN** the file exists with sections for symptom, possible causes, and resolution steps

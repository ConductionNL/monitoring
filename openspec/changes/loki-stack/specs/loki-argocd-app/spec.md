## ADDED Requirements

### Requirement: Independent ArgoCD Application
The system SHALL define a new ArgoCD Application in `apps/app-loki-prod.yaml` that deploys the Loki stack independently from the existing Prometheus stack application.

#### Scenario: Loki app syncs without affecting Prometheus app
- **WHEN** ArgoCD syncs `app-loki-prod`
- **THEN** the Loki stack deploys successfully AND `app-prom-prod` remains unchanged and healthy

### Requirement: Multi-source pattern
The ArgoCD Application SHALL use the multi-source pattern matching `apps/app-prom-prod.yaml`:
- Source 1: Helm chart repository with `valueFiles: $values/loki/values.yaml`
- Source 2: Git repository ref for values
- Source 3+: Git paths for non-Helm resources (`loki/` directory contents)

#### Scenario: Helm values loaded from Git
- **WHEN** ArgoCD renders the Loki application
- **THEN** Helm values are sourced from `loki/values.yaml` in the Git repository

#### Scenario: Non-Helm resources included
- **WHEN** ArgoCD syncs the Loki application
- **THEN** the datasource ConfigMap, Alloy config, and alert rules from the `loki/` directory are applied alongside the Helm-managed resources

### Requirement: Automated sync with prune and self-heal
The ArgoCD Application SHALL have automated sync policy with prune and self-heal enabled, matching the existing application's sync policy.

#### Scenario: Drift is auto-corrected
- **WHEN** a resource managed by the Loki application is manually modified in the cluster
- **THEN** ArgoCD detects the drift and self-heals to the Git-defined state

### Requirement: Monitoring namespace
The ArgoCD Application destination SHALL be the `monitoring` namespace, consistent with the existing stack.

#### Scenario: All Loki resources in monitoring namespace
- **WHEN** the Loki application is synced
- **THEN** all created resources exist in the `monitoring` namespace

### Requirement: SOPS decryption support
If SOPS-encrypted secrets exist under `loki/`, ArgoCD MUST decrypt them during sync using the existing SOPS/age setup. The `.sops.yaml` file SHALL include a creation rule for `^loki/secret-.*\.sops\.yaml$`.

#### Scenario: SOPS rule added
- **WHEN** `.sops.yaml` is inspected
- **THEN** a creation rule matching `^loki/secret-.*\.sops\.yaml$` exists with the same age public key as existing rules

#### Scenario: Encrypted secret decrypted at sync
- **WHEN** a SOPS-encrypted secret exists at `loki/secret-loki-s3.sops.yaml`
- **THEN** ArgoCD decrypts it during sync and applies the plaintext Secret to the cluster

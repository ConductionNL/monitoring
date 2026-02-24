# DeploymentUnhealthy

- Bron: `prometheus/rules/deploy/rules-deploy-unhealthy.yaml`
- Alert: `DeploymentUnhealthy`
- Severity: `warning`

## Betekenis
Een deployment heeft replicas in status "unavailable" (niet beschikbaar) gedurende >1m. Vaak door mislukte rollouts, crashloops of schedulingproblemen.

## Trigger
- `sum by (namespace, deployment) (kube_deployment_status_replicas_unavailable) > 0` (for: 1m)

## Runbook
1. `kubectl -n <namespace> get deployment <deployment>` en `kubectl -n <namespace> describe deployment <deployment>` → events, conditions.
2. Bekijk pods: `kubectl -n <namespace> get pods -l <deployment-selector>` en `describe pod` voor failed/unknown.
3. Controleer ReplicaSet en rollout status; bij image/config fouten: fix en eventueel rollback.

## Verwachte routing
- Slack default receiver (`team-platform-slack`).

## Test (non-prod)
- Zet een test-deployment op een niet-bestaande image of met een invalid config; wacht 1m tot de alert vuurt.

---
last_reviewed: 2026-07-06
owner: info@conduction.nl
---

# KubeDeploymentReplicasMismatch

- Bron: **kube-prometheus-stack** default rules (niet in deze repo; zit in de Helm chart).
- Alert: `KubeDeploymentReplicasMismatch`
- Severity: `warning`

## Betekenis
Een Deployment heeft gedurende langere tijd (ca. 15 min) niet het verwachte aantal replicas: het aantal *desired* komt niet overeen met het aantal *available*. Er draaien dus minder (of in zeldzame gevallen meer) pods dan gewenst.

## Impact
Mogelijk verminderde beschikbaarheid of capaciteit van de workload.

## Trigger
- Vergelijking van desired vs. available replicas (kube-state-metrics); vuurt na ca. 15 min mismatch.

## Runbook
1. **Deployment en pods bekijken**
   - `kubectl -n <namespace> get deployment <deployment>` en `kubectl -n <namespace> describe deployment <deployment>` → events, conditions, desired/current.
   - `kubectl -n <namespace> get pods -l <deployment-selector>` en `describe pod` voor niet-Running pods.

2. **Mogelijke oorzaken**
   - **Scheduling**: niet genoeg geschikte nodes (affinity, taints/tolerations, resource requests).
   - **Resources**: CPU/memory limits, of specifieke resources (bijv. GPU) niet beschikbaar.
   - **Terminatie**: lange `terminationGracePeriodSeconds` → pods blijven lang “Terminating”.
   - **Evictie**: lagere pod priority dan andere workloads → eviction.
   - **HPA**: HPA schaalt omhoog maar er kunnen geen extra pods gepland worden.

3. **Actie**
   - Bij tekort aan capaciteit: extra nodes of aanpassen van requests/limits/affinity.
   - Deployment/HPA-definitie aanpassen of rollback als de wijziging de oorzaak is.
   - Zie ook [Debugging Pods](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/#debugging-pods).

## Verwachte routing
- Default receiver (bijv. `team-platform-slack`), tenzij er een specifieke route voor deze alert is.

## Opmerking
- De 15 min-evaluatie is in de stack vastgelegd; bij zeer trage rollouts (bijv. CI) kan de alert eerder vuren dan dat de rollout klaar is.

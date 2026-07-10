---
last_reviewed: 2026-07-06
owner: mark
---

# PodPendingLong

- Bron: `prometheus/rules/pods/rules-podpending.yaml`
- Alert: `PodPendingLong`
- Severity: `warning`

## Betekenis
Een pod blijft >10m in fase `Pending`.

## Trigger
- `sum by (namespace,pod) (kube_pod_status_phase{phase="Pending"} == 1) > 0` (for: 10m)

## Runbook
1. `kubectl -n <ns> describe pod <pod>` → events/conditions.
2. Check resources/requests, node selectors/taints, quota, image pulls.

## Verwachte routing
- Slack default receiver.

## Test (non-prod)
- Maak een pod met niet-matchende nodeSelector/taint of onvoldoende resources en wacht 10m.


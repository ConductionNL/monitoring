---
last_reviewed: 2026-07-06
owner: mark
---

# HPAMaxedOut

- Bron: `prometheus/rules/hpa/rules-hpa-maxed.yaml`
- Alert: `HPAMaxedOut`
- Severity: `warning`

## Betekenis
HPA zit op maximaal aantal replicas (>10m), risico op underprovisioning.

## Trigger
- `max by (namespace,hpa) (kube_hpa_status_current_replicas) == max by (namespace,hpa) (kube_hpa_spec_max_replicas)` (for: 10m)

## Runbook
1. Check workload load/latency en resource requests.
2. Verhoog `maxReplicas` of optimaliseer toepassing.
3. Voor **CoreDNS** (kube-system/coredns): zie ook `docs/rules/KubeHpaMaxedOut.md` — zelfde probleem, uitgebreider runbook (o.a. DNS-load en maxReplicas).

## Verwachte routing
- Slack default receiver.

## Test
- Zet een test-HPA bewust laag en genereer load (non-prod).


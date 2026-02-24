# PVCUsageHigh

- Bron: `prometheus/rules/storage/rules-pvc-usage.yaml`
- Alert: `PVCUsageHigh`
- Severity: `warning`

## Betekenis
Beschikbare ruimte op PVC <10% (15m).

## Trigger
- `(kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes) < 0.10` (for: 15m)

## Runbook
1. Identificeer PVC en namespace uit labels.
2. Ruim data op of vergroot volume.
3. Controleer retentie/logrotatie.

## Verwachte routing
- Slack default receiver.

## Test
- Schrijf data in een test-PVC tot onder 10% vrij (alleen non-prod).


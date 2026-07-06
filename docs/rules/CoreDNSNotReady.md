---
last_reviewed: 2026-07-06
owner: mark
---

# CoreDNSNotReady

- Bron: `prometheus/rules/coredns/rules-coredns.yaml`
- Alert: `CoreDNSNotReady`
- Severity: `warning`

## Wat betekent dit
De CoreDNS health metric laat geen requests zien. De expressie kijkt 5 minuten lang naar een 0-teller en triggert als dat aanhoudt.

## Trigger (expressie)
- `sum by (pod) (coredns_health_request_duration_seconds_count{job="kube-dns"} == 0) > 0` (for: 5m)

## Actie / runbook
1. Controleer CoreDNS pods in `kube-system` (status, logs).
2. Controleer endpoints/service `kube-dns`.
3. Verifieer de Corefile configuratie.

## Verwachte routing
- Default receiver: Slack `#k8s-alerts` via Alertmanager.

## Test (alleen veilig in testomgeving!)
- (Impactvol) Schaal CoreDNS tijdelijk terug:
  ```bash
  kubectl -n kube-system scale deploy coredns --replicas=0
  # Wacht >5m, controleer alert, daarna herstellen:
  kubectl -n kube-system scale deploy coredns --replicas=<orig>
  ```
- Alternatief: cordon/taint de nodes waar CoreDNS draait en observeer.


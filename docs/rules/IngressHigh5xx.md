# IngressHigh5xx

- Bron: `prometheus/rules/ingress/rules-nginx-5xx.yaml`
- Alert: `IngressHigh5xx`
- Severity: `warning`

## Betekenis
Meer dan 5% 5xx responses over 5–10 minuten.

## Trigger
- `(sum by (ingress,namespace) (rate(nginx_ingress_controller_requests{status=~"5.."}[5m])) / sum by (ingress,namespace) (rate(nginx_ingress_controller_requests[5m]))) > 0.05` (for: 10m)

## Runbook
1. Check backend service/pods voor errors/timeouts.
2. Controleer ingress config, timeouts, health checks.

## Verwachte routing
- Slack default receiver.

## Test
- Forceer 5xx op een test-ingress (non-prod) en verifieer alert.


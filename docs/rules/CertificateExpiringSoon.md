---
last_reviewed: 2026-07-06
owner: info@conduction.nl
---

# CertificateExpiringSoon

- Bron: `prometheus/rules/certmanager/rules-cert-expiry.yaml`
- Alert: `CertificateExpiringSoon`
- Severity: `warning`

## Betekenis
Een cert-manager certificaat verloopt binnen 14 dagen.

## Trigger
- `(certmanager_certificate_expiration_timestamp_seconds - time()) < 14 * 24 * 3600` (for: 60m)

## Runbook
1. Controleer Issuer/ClusterIssuer en challenges.
2. Bekijk cert-manager events en logs.
3. Forceer hernieuwing indien nodig.

## Verwachte routing
- Slack default receiver.

## Test
- Maak een kortlopend testcert (non-prod) en controleer alert.


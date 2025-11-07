# KubeClientCertificateExpiration

- Bron: kube-prometheus-stack default rules
- Alert: `KubeClientCertificateExpiration`
- Severity: `warning`

## Betekenis
Clientcertificaten die door de Kubernetes API-server worden gezien, verlopen binnenkort. Denk aan kubelet client certs, controller-manager/scheduler client certs, aggregated API servers, of statische kubeconfigs.

## Diagnostiek (Prometheus)
- Overzicht (kortste resterende tijd eerst):
  - `sort(apiserver_client_certificate_expiration_seconds)`
  - `bottomk(10, apiserver_client_certificate_expiration_seconds)`
- Filter op specifieke client/issuer/subject labels als aanwezig, om de bron te vinden.

## Stappenplan (oplossen)
1. Identificeer de bron
   - Bekijk labels/onderwerpen in de metric-resultaten (client/subject/issuer/serial).
   - Bepaal of het gaat om kubelet, control-plane componenten, aggregated API (bv. metrics-server), of een externe client (admin kubeconfig).
2. Kubelet clientcerts
   - Zorg dat kubelet certificate rotation aan staat (kubelet config `rotateCertificates: true`).
   - Controleer CSR’s en approvals:
     - `kubectl get csr`
     - Afgekeurd/blokkade? Check approving controllers of policy.
3. Control-plane componenten (controller-manager/scheduler)
   - Indien self-managed: hergenereer/renew clientcerts of ververs de secrets/manifests en herstart de pods veilig.
   - In managed omgevingen: certificaatrotatie is vaak geautomatiseerd door de provider; verifieer of rotatie loopt en of er fouten zijn in controller logs.
4. Aggregated/extension API servers (bijv. metrics-server)
   - Heruitgeven/vernieuwen van clientcert of herdeploy met geldige credentials.
5. Statische kubeconfigs (developers/automation)
   - Genereer nieuwe kubeconfig met geldige clientcerts/credentials.
   - Vervang secrets/CI-variabelen en herstart jobs die het gebruiken.
6. Validatie
   - De waarde van `apiserver_client_certificate_expiration_seconds` stijgt weer (voldoende marge) voor de betreffende subjecten.
   - Alert gaat naar Resolved na volgende evaluaties.

## Routing
- Slack via default receiver; meldingsherhaling ingesteld op 24h.

## Test
- N.v.t. (productie-alert). Verifiëren door de Prometheus-query; er is geen veilige synthetische test in productie.


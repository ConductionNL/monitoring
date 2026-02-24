# CoreDNS Extended Alerts

- Bron: `prometheus/rules/coredns/rules-coredns-extended.yaml`
- Alerts: `CoreDNSDeploymentUnavailable`, `CoreDNSPodRestarts`, `CoreDNSServfailRateHigh`, `CoreDNSRefusedRateHigh`, `CoreDNSConfigRecreatedRecently`, `KubeSystemDeploymentRolledOut`
- Severity: mix van critical/warning/info

## Betekenis (kort)
- Unavailable replicas: CoreDNS deployment mist replicas >5m (service-impact).
- Pod restarts: te veel herstarts in 10m (stabiliteit).
- SERVFAIL/REFUSED ratio: foutpercentages in DNS-responses.
- ConfigMap recreatie en deployment changes: change indicators in `kube-system`.

## Triggers (samengevat)
- Unavailable: `kube_deployment_status_replicas_unavailable{ns="kube-system", deployment~="coredns.*"} > 0` (5m)
- Restarts: `sum(increase(kube_pod_container_status_restarts_total{ns="kube-system", pod~="coredns-.*"}[10m])) > 3` (5m)
- SERVFAIL: `sum(rate(coredns_dns_responses_total{rcode="SERVFAIL"}[5m])) / sum(rate(...)) > 0.01` (5m)
- REFUSED: `...{rcode="REFUSED"} > 0.05` (10m)
- Config recreated: `time() - kube_configmap_created{ns="kube-system",configmap="coredns"} < 600` (1m)
- Deployment rolled: `changes(kube_deployment_status_observed_generation{ns="kube-system"}[10m]) > 0` (1m)

## Runbook
1. Pods/Deployment status en logs checken in `kube-system`.
2. Bekijk CoreDNS service/endpoints en netwerk policies.
3. Controleer Corefile config en recente changes (ConfigMap/deployment rollout).
4. Bij SERVFAIL/REFUSED: bekijk upstream resolvers, timeouts en policy.

## Verwachte routing
- Slack default receiver (`#k8s-alerts`) via Alertmanager.

## Test (alleen non-prod)
- Schaal CoreDNS tijdelijk terug of wijzig (tijdelijk) Corefile om errorratio te simuleren; herstel direct na verificatie.


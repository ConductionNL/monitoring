---
last_reviewed: 2026-07-06
owner: mark
---

# KubeSchedulerDown

- Bron: kube-prometheus-stack default rules
- Alert: `KubeSchedulerDown`
- Severity: `critical`

## Betekenis
Prometheus ziet de `kube-scheduler` niet (meer) als up via de metrics endpoint. Dit kan duiden op:
- Scheduler-proces is gestopt of gecrasht.
- Metrics endpoint is niet bereikbaar (network/RBAC/ServiceMonitor).
- In managed control planes: tijdelijke provider-storing of maintenance.

## Typische trigger
Afgeleid van de `up{job="kube-scheduler"}` metric (of `absent(...)`) gedurende een periode (bijv. 15m).

## Runbook
1. Verifieer status
   - `kubectl -n kube-system get pods -l component=kube-scheduler -o wide` (labels kunnen per distro afwijken).
   - Bekijk `up{job="kube-scheduler"}` in Prometheus en de `Targets`-pagina: is de scrape failing? (DNS, TLS, 401/403, timeout)
2. Logs/gezondheid
   - `kubectl -n kube-system logs -l component=kube-scheduler --tail=200`
   - Control-plane events: `kubectl -n kube-system get events --sort-by=.lastTimestamp`
3. Scraping en netwerk
   - ServiceMonitor/Endpoints: bestaat er een `Service`/`Endpoints` voor de scheduler metrics en matcht de ServiceMonitor-selector?
   - NetworkPolicy/Firewall: mag Prometheus de scheduler endpoint bereiken?
   - TLS/RBAC: vereist de endpoint auth? Controleer eventueel certificaten en rollen.
4. Managed vs self-managed
   - Managed (AKS/EKS/GKE): controleer provider status/maintenance-meldingen; vaak herstelt dit automatisch. Escaleer naar cloud support bij aanhoudende uitval.
   - Self-managed: herstel scheduler (re-deploy/rollout/restart), verhelp resource- of configuratieproblemen en zorg voor HA (meerdere replicas) waar passend.
5. Validatie
   - `up{job="kube-scheduler"} == 1` voor alle verwachte instanties.
   - Alert gaat naar Resolved na enkele evaluaties.

## Routing
- Slack via default receiver; critical prioriteit.

## Test (alleen non-prod)
- Pauzeer de scheduler of blokkeer de metrics-scrape tijdelijk (NetworkPolicy/Service) en controleer dat de alert vuurt; herstel daarna direct.



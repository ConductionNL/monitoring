---
last_reviewed: 2026-07-06
owner: info@conduction.nl
---

# PhpFpmMaxChildrenReached

- Bron: `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml`
- Alert: `PhpFpmMaxChildrenReached`
- Severity: `warning`

## Betekenis
Het maximum aantal child processen (pm.max_children) is minstens één keer bereikt. Nieuwe requests kunnen in de listen queue terechtkomen; de PM was verzadigd.

## Trigger
- `php_fpm_max_children_reached > 0` (for: 1m). De metric is een teller (aantal keren dat de limiet is bereikt).

## Runbook
1. **Huidige belasting**: Bekijk in Grafana/Prometheus: `php_fpm_active_processes`, `php_fpm_idle_processes`, `php_fpm_listen_queue` voor deze pool.
2. **pm.max_children**: Verhoog in de PHP-FPM poolconfiguratie indien de workload structureel hoger is, of optimaliseer de app (minder lange requests, caching).
3. **Spreiding**: Bij meerdere replicas: is de load gelijkmatig? Overweeg meer replicas of resource limits aanpassen.

## PM-instellingen: wat kan beter?
- **pm.max_children** verhogen tot minimaal het dubbele van het gemiddelde aantal actieve processen bij piek (rekening houdend met beschikbaar geheugen per worker).
- **pm.start_servers**: in de buurt van `(pm.min_spare_servers + pm.max_spare_servers) / 2` zodat er bij opstart al voldoende workers zijn.
- **pm.min_spare_servers** en **pm.max_spare_servers** iets verhogen zodat er sneller idle workers beschikbaar zijn bij pieken.
- Na wijziging: pool herladen (`php-fpm reload` of pod herstart) en daarna de metrics opnieuw bekijken.

## Verwachte routing
- Alertmanager default-receiver `team-platform-slack` → Slack-kanaal `#k8s-alerts` (het kanaal hangt aan de webhook-URL, zie `docs/alerting.md`).

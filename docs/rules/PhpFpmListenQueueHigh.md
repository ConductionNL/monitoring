---
last_reviewed: 2026-07-06
owner: info@conduction.nl
---

# PhpFpmListenQueueHigh

- Bron: `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml`
- Alert: `PhpFpmListenQueueHigh`
- Severity: `warning`

## Betekenis
Er staan te veel requests in de PHP-FPM listen queue. De process manager is verzadigd; nieuwe verbindingen wachten.

## Trigger
- `php_fpm_listen_queue > 10` (for: 5m)

## Runbook
1. **Actieve processen**: Bekijk `php_fpm_active_processes` en `php_fpm_total_processes` / `php_fpm_idle_processes`. Zijn alle workers bezet?
2. **pm.max_children / pm.start_servers**: Verhoog indien nodig; zorg dat er voldoende child processen zijn voor de piekbelasting.
3. **Trage requests**: Controleer `php_fpm_slow_requests` (indien slow-log ingeschakeld) en app-logica; lange queries of blokkades verhogen de queue.

## PM-instellingen: wat kan beter?
- **pm.max_children** verhogen zodat de listen queue niet meer oploopt; richtlijn: hoger dan het typische aantal gelijktijdige actieve processen bij piek.
- **pm.start_servers** verhogen zodat er direct meer workers klaarstaan bij opstart (bijv. 2–4 voor lichte loads, meer bij zwaardere).
- **pm.min_spare_servers** en **pm.max_spare_servers** verhogen zodat er meer idle workers blijven; daarmee daalt de queue sneller.
- Bij aanhoudende hoge queue: ook app-optimalisatie (caching, slow queries) en eventueel meer replicas.

## Verwachte routing
- Default (bijv. team-platform-slack).

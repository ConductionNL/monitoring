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

## Verwachte routing
- Default (bijv. team-platform-slack).

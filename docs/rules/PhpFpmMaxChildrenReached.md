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

## Verwachte routing
- Default (bijv. team-platform-slack).

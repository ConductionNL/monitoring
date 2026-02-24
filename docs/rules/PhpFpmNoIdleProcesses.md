# PhpFpmNoIdleProcesses

- Bron: `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml`
- Alert: `PhpFpmNoIdleProcesses`
- Severity: `warning`

## Betekenis
Er zijn geen idle child processen; alle PHP-FPM workers zijn actief. Nieuwe requests moeten wachten tot er een worker vrijkomt (verzadiging van de PM).

## Trigger
- `php_fpm_idle_processes == 0 and php_fpm_active_processes > 0` (for: 5m)

## Runbook
1. **Kortdurend vs structureel**: Bij een korte piek is dit normaal; bij aanhoudende situatie: meer workers of betere spreiding.
2. **pm.max_children / pm.min_spare**: Verhoog max_children of min_spare_servers zodat er meer processen beschikbaar zijn.
3. **App-performance**: Onderzoek trage requests (slow-log, logs) zodat workers sneller vrij komen.

## Verwachte routing
- Default (bijv. team-platform-slack).

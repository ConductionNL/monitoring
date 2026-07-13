---
last_reviewed: 2026-07-06
owner: info@conduction.nl
---

# PhpFpmDown

- Bron: `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml`
- Alert: `PhpFpmDown`
- Severity: `critical`

## Betekenis
De PHP-FPM statuspagina (PM) is niet bereikbaar. De exporter kan geen metrics ophalen; PM-servers of child processen werken mogelijk niet, of de exporter/statuspagina is niet bereikbaar.

## Vereisten
- PHP-FPM met `pm.status_path = /status` (of overeenkomstig) in de poolconfiguratie.
- Een PHP-FPM exporter (bijv. [Lusitaniae phpfpm_exporter](https://github.com/Lusitaniae/phpfpm_exporter)) als sidecar of naast de workload, die door Prometheus wordt gescrapet (ServiceMonitor of scrape config).

## Trigger
- `php_fpm_up == 0` (for: 2m)

## Runbook
1. **Pod en exporter**: `kubectl -n <namespace> get pods`, logs van de pod met de PHP-FPM workload en de exporter-sidecar. Is de exporter draaiend en kan die de socket bereiken?
2. **PHP-FPM status**: In de app-pod: controleer of PHP-FPM draait en of de statuspagina bereikbaar is (afhankelijk van setup: lokaal curl of via exporter).
3. **ServiceMonitor / scrape**: Is er een ServiceMonitor (of equivalente scrape config) die de exporter target? Heeft Prometheus de target in zijn config?
4. **Socket/path**: Klopt het socket-path dat de exporter gebruikt met de daadwerkelijke PHP-FPM socket?

## Verwachte routing
- Default receiver (bijv. `team-platform-slack`); kan naar specifieke receiver voor Nextcloud/PM.

## Zie ook
- PhpFpmMaxChildrenReached, PhpFpmListenQueueHigh, PhpFpmNoIdleProcesses voor andere PM-alerts.

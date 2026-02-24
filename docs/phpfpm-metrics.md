# PHP-FPM / PM metrics en alerts

De alerts voor PHP-FPM (process manager: PM-servers, child processen, listen queue) gebruiken metrics van een **PHP-FPM exporter**. Die exporter moet je zelf bij je Nextcloud (of andere PHP-FPM) workload deployen; de monitoring-repo levert alleen de **PrometheusRules** en runbooks.

## Wat je nodig hebt

1. **PHP-FPM statuspagina**  
   In de PHP-FPM poolconfiguratie:
   - `pm.status_path = /status` (of een ander path dat je consistent gebruikt).

2. **Exporter**  
   Bijvoorbeeld [Lusitaniae phpfpm_exporter](https://github.com/Lusitaniae/phpfpm_exporter):
   - Draait als sidecar naast je app of als aparte pod die de PHP-FPM socket kan bereiken.
   - Stelt metrics beschikbaar op een poort (standaard 9253) onder `/metrics`.
   - Metric-namen: `php_fpm_up`, `php_fpm_listen_queue`, `php_fpm_active_processes`, `php_fpm_idle_processes`, `php_fpm_total_processes`, `php_fpm_max_children_reached`, enz.

3. **Scrape door Prometheus**  
   Zorg dat Prometheus de exporter scrapet:
   - **ServiceMonitor** (aanbevolen): in de namespace van je workload een ServiceMonitor die de exporter-service target (poort 9253, path `/metrics`).
   - Of een bestaande scrape-config in de monitoring-stack die op die service/pod target.

## Alerts in deze repo

- **PhpFpmDown** – exporter kan PHP-FPM status niet ophalen (`php_fpm_up == 0`).
- **PhpFpmMaxChildrenReached** – max children is bereikt; requests kunnen wachten.
- **PhpFpmListenQueueHigh** – listen queue > 10 gedurende 5m.
- **PhpFpmNoIdleProcesses** – geen idle workers; PM verzadigd.

Runbooks: `docs/rules/PhpFpmDown.md`, enz.

## Regels in Git

- `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml`  
  Bevat de bovenstaande alerts. Wordt door Argo CD gesynct; ze gaan pas vuren zodra de metrics in Prometheus binnenkomen (dus nadat je de exporter + ServiceMonitor hebt gedeployed).

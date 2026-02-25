# PHP-FPM / PM metrics en alerts

De alerts voor PHP-FPM gebruiken metrics van een **PHP-FPM exporter**. Eerst **bewijzen dat het werkt met wat er al in de namespace staat**; daarna pas eventueel extra implementatie.

## Eerst: gebruik wat er al staat

Jullie hebben al een **nextcloud-metrics** deploy in de namespace. Geen nieuwe YAML; we sluiten alleen de monitoring daarop aan.

**Controleren wat er nu staat (in vng-backend-accept of epe):**
```bash
kubectl get svc -n vng-backend-accept -o wide
kubectl get svc -n epe -o wide
```
- Welke **Service** hoort bij nextcloud-metrics? Noteer de **labels** (bijv. `app: nextcloud-metrics` of `app.kubernetes.io/name: nextcloud-metrics`) en de **poort** waarop metrics worden geëxposeerd (vaak 9253 voor phpfpm_exporter).

**ServiceMonitor in `stack/values.yaml`:**
- De selector moet overeenkomen met die labels (nu: **`app: nextcloud-metrics`**).
- De poort moet overeenkomen (nu: **9253**).  
Als jullie andere labels of poort gebruiken: pas alleen die twee in `stack/values.yaml` aan.

**Daarna:** push + sync stack → Prometheus scrapet de bestaande service → als die al `php_fpm_*` metrics levert, zie je data in het Grafana-dashboard. **Eerst dit bewijzen; daarna pas iets nieuws implementeren.**

## Wat er in deze repo staat

- **ServiceMonitor** in `stack/values.yaml`: scrapet Services met label **`app: nextcloud-metrics`** en poort **9253** in **vng-backend-accept** en **epe**. Als jullie bestaande Service andere labels/poort heeft: pas die twee in de ServiceMonitor aan (geen nieuwe workloads).
- **Voorbeeld-manifest** `examples/nextcloud-phpfpm-exporter/`: alleen gebruiken **nadat** bewezen is dat scrapen werkt; voor als je later ergens een nieuwe exporter bij wilt zetten.

## Wat je nodig hebt

1. **PHP-FPM statuspagina**  
   In de PHP-FPM poolconfiguratie:
   - `pm.status_path = /status` (of een ander path dat je consistent gebruikt).
   - Voor de voorbeeld-pod: PHP-FPM moet op **TCP** luisteren (bijv. poort 9000) zodat de exporter er vanaf een andere pod mee kan praten; of de exporter draait als **sidecar** in dezelfde pod en gebruikt de Unix-socket.

2. **Exporter**  
   Bijv. Lusitaniae phpfpm_exporter:
   - Draait in jullie **nextcloud-metrics** deploy of als test-pod uit `examples/nextcloud-phpfpm-exporter/`.
   - Stelt metrics beschikbaar op poort **9253** onder `/metrics`.
   - Metric-namen: `php_fpm_up`, `php_fpm_listen_queue`, `php_fpm_active_processes`, `php_fpm_idle_processes`, `php_fpm_total_processes`, `php_fpm_max_children_reached`, enz.

3. **Scrape**  
   Zorg dat de **Service** voor de exporter:
   - poort **9253** exposeert;
   - label **`app: nextcloud-metrics`** heeft.  
   Dan pikt de bestaande ServiceMonitor in `stack/values.yaml` die service automatisch op (in vng-backend-accept en epe).

## Alerts in deze repo

- **PhpFpmDown** – exporter kan PHP-FPM status niet ophalen (`php_fpm_up == 0`).
- **PhpFpmMaxChildrenReached** – max children is bereikt; requests kunnen wachten.
- **PhpFpmListenQueueHigh** – listen queue > 10 gedurende 5m.
- **PhpFpmNoIdleProcesses** – geen idle workers; PM verzadigd.

Runbooks: `docs/rules/PhpFpmDown.md`, enz.

## Regels in Git

- `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml`  
  Bevat de bovenstaande alerts. Wordt door Argo CD gesynct; ze gaan pas vuren zodra de metrics in Prometheus binnenkomen.

## Volgorde: eerst bewijzen, daarna implementeren

1. **Nu:** Kijk in de namespace wat de **bestaande** nextcloud-metrics Service heeft: labels en poort. Pas zo nodig in `stack/values.yaml` de ServiceMonitor aan (selector en port) zodat die exact die Service pakt. Push/sync → controleer in Grafana of er data binnenkomt. Geen nieuwe YAML.
2. **Daarna:** Als blijkt dat de bestaande deploy nog geen php_fpm_* metrics levert, dan pas in het platform (of met het voorbeeld) de exporter toevoegen/uitbreiden.

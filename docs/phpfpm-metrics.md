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

### Nog geen data? Debug-checklist

In het dashboard **Nextcloud-omgevingen** staan nu een **PHP-FPM scrape status**-panel (1 = target wordt gescrapet) en een **PHP-FPM troubleshooting**-tekst met dezelfde stappen. Geen data daar = Prometheus scrapet de exporter niet of de exporter bereikt PHP-FPM niet.

1. **ServiceMonitor voor de exporter-pod**
   ```bash
   kubectl get servicemonitor -n monitoring | grep -E 'nextcloud|phpfpm'
   ```
   Er zou **nextcloud-phpfpm-exporter** moeten staan (standalone in `servicemonitors/nextcloud-phpfpm-exporter.yaml`, door Argo gesynct). Zo niet: push + sync van de app (path `servicemonitors` staat in `apps/app-prom-prod.yaml`).

2. **Target in Prometheus**
   Prometheus UI → Status → Targets. Zoek op `nextcloud-phpfpm` of op `vng-backend-test`. Staat de target erbij en is die **Up**? Zo niet: klik op de target voor de fout (connection refused, timeout, no match, etc.).

3. **Wat levert de exporter lokaal?**
   ```bash
   kubectl -n vng-backend-test port-forward svc/nextcloud-phpfpm-exporter 9253:9253
   ```
   Open http://localhost:9253/metrics en zoek op `php_fpm_`. Zie je `php_fpm_up`, `php_fpm_active_processes`, enz.?  
   - **php_fpm_up 0**: exporter draait maar kan PHP-FPM niet bereiken (verkeerd adres, geen TCP, geen pm.status_path).  
   - Geen php_fpm_*: verkeerde image of path.  
   - Wel php_fpm_* met waarden: dan zou Prometheus ze moeten hebben; controleer stap 2 en in Grafana Explore query `php_fpm_up` of `{job="nextcloud-phpfpm"}`. Het dashboard filtert op `job="nextcloud-phpfpm"` (geen namespace-filter), zodat data zichtbaar is zodra de target gescrapet wordt.

4. **Namespace in ServiceMonitor**  
   De ServiceMonitor moet de namespace van de pod bevatten (`vng-backend-test` staat in `stack/values.yaml` bij de entry `nextcloud-phpfpm-exporter` → `namespaceSelector.matchNames`). Na wijziging: push + sync.

## Wat er in deze repo staat

- **ServiceMonitor** in `stack/values.yaml`: scrapet Services met label **`app: nextcloud-metrics`** en poort **9253** in **vng-backend-accept** en **epe**. Als jullie bestaande Service andere labels/poort heeft: pas die twee in de ServiceMonitor aan (geen nieuwe workloads).
- **Voorbeeld-manifest** `examples/nextcloud-phpfpm-exporter/`: alleen gebruiken **nadat** bewezen is dat scrapen werkt; voor als je later ergens een nieuwe exporter bij wilt zetten.

**pm.max_children / pm.start_servers enz. in Grafana?**  
De **config-exporter** (examples/nextcloud-phpfpm-exporter/) serveert die vier waarden op poort 9254; het dashboard filtert op `job="nextcloud-phpfpm-config"`.

### Hoe en wat: waarom de 4 pm.xxx-panels vullen (of niet)

De keten is: **config-exporter in de pod** → **Service met poort 9254** → **ServiceMonitor met endpoint `port: config`** → **Prometheus scrapet** → **Grafana toont `job="nextcloud-phpfpm-config"`**.

| Stap | Wat | Waar te controleren |
|------|-----|---------------------|
| 1 | Pod heeft **twee** containers: `phpfpm-exporter` (9253) en `config-exporter` (9254). | `kubectl get pods -n vng-backend-test -l app=nextcloud-phpfpm-exporter` → READY moet **2/2** zijn. |
| 2 | Service heeft **twee** poorten: `metrics` (9253) en **`config`** (9254). | `kubectl get svc -n vng-backend-test nextcloud-phpfpm-exporter -o yaml` → onder `spec.ports` zowel 9253 als 9254. |
| 3 | Config-exporter geeft metrics op 9254. | `kubectl exec -n vng-backend-test deploy/nextcloud-phpfpm-exporter -c config-exporter -- wget -qO- http://127.0.0.1:9254/metrics` → moet `php_fpm_config_max_children` tonen. |
| 4 | **ServiceMonitor** staat in de cluster en heeft **twee** endpoints (port `metrics` en port **`config`**). | `kubectl get servicemonitor -n monitoring nextcloud-phpfpm-exporter -o yaml` → onder `spec.endpoints` twee items; tweede met `port: config`. Wordt door Argo gesynct uit `servicemonitors/` (zie `apps/app-prom-prod.yaml`). |
| 5 | Prometheus scrapet de target voor job **nextcloud-phpfpm-config**. | Prometheus UI → Status → Targets → zoek op `nextcloud-phpfpm-config` of op poort 9254. Staat die target op **Up**? |
| 6 | Grafana haalt de metrics op. | Grafana → Explore (Prometheus) → query `php_fpm_config_max_children` of `up{job="nextcloud-phpfpm-config"}`. Zie je waarden (bijv. 50, 5, 5, 35)? |

**Geen data in de panels?** Meestal ontbreekt stap 4 of 5: de ServiceMonitor is niet gesynct (Argo-app voor `servicemonitors` syncen), of Prometheus pikt alleen de eerste endpoint van de ServiceMonitor op en niet de tweede. Controleer in Prometheus Targets of er **twee** targets zijn voor deze Service (één job=nextcloud-phpfpm, één job=nextcloud-phpfpm-config).

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

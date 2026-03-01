# PHP-FPM exporter: 1× in één namespace, vrijdag bij alle deploys

## Nu: 1× als pod in één namespace (incl. 4 pm.xxx in dashboard)

**Bestanden:** `configmaps.yaml` (pool-config sample + script) en `one-namespace.yaml` (Deployment met runtime-exporter + config-exporter, Service 9253 + 9254).

1. **PHP-FPM-adres aanpassen** in `one-namespace.yaml` als je andere service/namespace gebruikt:  
   `--phpfpm.socket-paths=tcp://nextcloud.vng-backend-test.svc.cluster.local:9000` → vervang indien nodig. PHP-FPM moet op TCP (bijv. 9000) luisteren en **pm.status_path** hebben.

2. **Stappen uitvoeren (vng-backend-test):**
   ```bash
   # Eerst ConfigMaps (pool-config sample + config-exporter script)
   kubectl apply -f configmaps.yaml -n vng-backend-test

   # Daarna Deployment + Service (runtime-exporter op 9253, config-exporter op 9254)
   kubectl apply -f one-namespace.yaml -n vng-backend-test
   ```

3. **Controleren:** Pod heeft twee containers; Service heeft poorten 9253 en 9254. Na sync van de monitoring-stack (ServiceMonitor in `servicemonitors/`) scrapet Prometheus beide. De 4 pm.xxx-panels in het dashboard vullen met de waarden uit de sample-config (50, 5, 5, 35) tot je een echte pool-config mount.

## Vrijdag: bij alle deploys

Zelfde **label** `app: nextcloud-phpfpm-exporter` en **poort 9253** bij elke deploy (exporter als container of sidecar). Dezelfde ServiceMonitor pikt ze dan op. Nieuwe namespaces toevoegen onder `prometheusOperator.additionalServiceMonitors` → `nextcloud-phpfpm-exporter` → `namespaceSelector.matchNames` in `stack/values.yaml`.

## pm.max_children etc. (config) in Grafana

De Lusitaniae-exporter levert alleen **runtime**-metrics. De **pool-config** (pm.max_children, pm.start_servers, pm.min_spare_servers, pm.max_spare_servers) kun je als metrics tonen door de **config-exporter** als sidecar in je **Nextcloud-pod** te draaien:

1. **Script** `phpfpm-config-exporter.py` in deze map: leest de pool-config en serveert op :9254/metrics de vier waarden als `php_fpm_config_*`.
2. In je Nextcloud-deploy: extra container die dit script draait (image met Python3), env `CONFIG_PATH=/pad/naar/pool.conf` (bijv. `/usr/local/etc/php-fpm.d/www.conf`), poort 9254.
3. Pool-config in de pod mounten (of het pad waar die al staat gebruiken).
4. Service uitbreiden met poort 9254. De ServiceMonitor in deze repo scrapet 9254 al (tweede endpoint).
5. Dashboard "Nextcloud-omgevingen" heeft vier panels voor deze config-metrics; die vullen zodra de metrics binnenkomen.

De test-pod in vng-backend-test heeft alleen de runtime-exporter (9253); voor die pod is 9254 niet beschikbaar (geen probleem).

## Vereisten

- PHP-FPM: **pm.status_path** aan (bijv. `/status`), luisteren op **TCP** (bijv. 9000) zodat de exporter kan verbinden, of exporter als sidecar met Unix-socket.

## Als jullie al een nextcloud-metrics deploy hebben

- **Al poort 9253 met php_fpm_* metrics?** Alleen **stack/values.yaml** pushen en syncen; de ServiceMonitor scrapet die service dan. Geen voorbeeld-pod nodig.
- **Nog geen PHP-FPM exporter?** Voeg in jullie bestaande nextcloud-metrics deploy een container toe met deze exporter (zelfde image + args naar jullie PHP-FPM), en exposeer poort 9253 op de Service met label `app: nextcloud-metrics`. Of run dit voorbeeld onder een andere **Deployment-naam** (bijv. `nextcloud-phpfpm-test`) in dezelfde namespace; de **Service** moet wel label `app: nextcloud-metrics` hebben zodat de ServiceMonitor hem pikt.

## In het platform (nextcloud-metrics)

- Zorg dat jullie **nextcloud-metrics** deploy een container heeft die deze exporter draait (zelfde image en args, socket-path naar de PHP-FPM van Nextcloud).
- Zorg dat de **Service** voor die deploy:
  - poort **9253** exposeert (naam mag `metrics` zijn of gewoon 9253);
  - label **`app: nextcloud-metrics`** heeft.
- De ServiceMonitor in deze repo pikt die service dan op (in namespaces `vng-backend-accept` en `epe`). Voor andere namespaces: voeg ze toe onder `namespaceSelector.matchNames` in `stack/values.yaml`.

## Zie ook

- `docs/phpfpm-metrics.md` – overzicht wat je nodig hebt en welke alerts er zijn.

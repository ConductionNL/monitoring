# Voorbeeld: PHP-FPM exporter (1× test, daarna in platform)

Deze map bevat een **eenmalige test-deployment** van de PHP-FPM exporter. Als het werkt, kun je hetzelfde patroon in jullie **nextcloud-metrics** deploy in het platform opnemen.

## Vereisten

- PHP-FPM in Nextcloud heeft **pm.status_path** aan (bijv. `/status`) en luistert op **TCP** (bijv. poort 9000), of de exporter kan de **Unix-socket** bereiken (bijv. als sidecar in dezelfde pod).
- De **ServiceMonitor** voor `app: nextcloud-metrics` staat al in `stack/values.yaml` (namespaces `vng-backend-accept`, `epe`). Elke Service in die namespaces met label `app: nextcloud-metrics` en poort **9253** wordt door Prometheus gescrapet.

## 1× test met dit voorbeeld

1. **Pas de PHP-FPM-adres aan** in `deployment.yaml`:
   - Voor **TCP**: `--phpfpm.socket-paths=tcp://<nextcloud-service>.<namespace>.svc.cluster.local:9000`
   - Vervang `<nextcloud-service>` door de naam van de Service van je Nextcloud (bijv. `nextcloud` of `nextcloud-app`) en `<namespace>` door `vng-backend-accept` of `epe`.

2. **Deploy in dezelfde namespace als je Nextcloud** (bijv. vng-backend-accept):
   ```bash
   kubectl apply -f deployment.yaml -n vng-backend-accept
   kubectl apply -f service.yaml -n vng-backend-accept
   ```

3. **Controleer**:
   - Pod draait: `kubectl -n vng-backend-accept get pods -l app=nextcloud-metrics`
   - Metrics lokaal: `kubectl -n vng-backend-accept port-forward svc/nextcloud-metrics 9253:9253` en open http://localhost:9253/metrics (zoek `php_fpm_`).

4. **Sync monitoring-stack** (als de ServiceMonitor nog niet actief was): push/Argo sync voor `stack/values.yaml`. Daarna zou Prometheus de target moeten hebben en het Grafana-dashboard "Nextcloud-omgevingen" (PHP-FPM-rij) data tonen.

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

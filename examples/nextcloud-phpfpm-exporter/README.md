# PHP-FPM exporter: 1× in één namespace, vrijdag bij alle deploys

## Nu: 1× als pod in één namespace

**Bestand:** `one-namespace.yaml` (Deployment + Service, label `app: nextcloud-phpfpm-exporter`, poort 9253).

1. **PHP-FPM-adres aanpassen** in `one-namespace.yaml` als je andere service/namespace gebruikt:  
   `--phpfpm.socket-paths=tcp://nextcloud.vng-backend-accept.svc.cluster.local:9000` → vervang `nextcloud` / `vng-backend-accept` indien nodig. PHP-FPM moet op TCP (bijv. 9000) luisteren en **pm.status_path** hebben.

2. **Toepassen in vng-backend-test:**
   ```bash
   kubectl apply -f one-namespace.yaml -n vng-backend-test
   ```
   (Namespace staat al in het bestand; `-n vng-backend-test` kan ook.)

3. **Stack syncen** (ServiceMonitor voor `app: nextcloud-phpfpm-exporter` staat in `stack/values.yaml`). Daarna scrapet Prometheus deze pod; de PHP-FPM-rij in het dashboard zou data moeten tonen.

## Vrijdag: bij alle deploys

Zelfde **label** `app: nextcloud-phpfpm-exporter` en **poort 9253** bij elke deploy (exporter als container of sidecar). Dezelfde ServiceMonitor pikt ze dan op. Nieuwe namespaces toevoegen onder `prometheusOperator.additionalServiceMonitors` → `nextcloud-phpfpm-exporter` → `namespaceSelector.matchNames` in `stack/values.yaml`.

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

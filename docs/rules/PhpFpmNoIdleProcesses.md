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

## PM-instellingen: wat kan beter?
- **pm.min_spare_servers** verhogen zodat er altijd een paar idle workers blijven (bijv. 2–4 voor lichte loads).
- **pm.max_spare_servers** verhogen zodat bij pieken meer spare workers mogen bestaan; typisch iets lager dan pm.max_children.
- **pm.max_children** verhogen als je structureel alle workers vol hebt, binnen de grenzen van beschikbaar geheugen.
- **pm.start_servers** afstemmen op min/max spare zodat er bij start al voldoende workers zijn.

## Verwachte routing
- Default (bijv. team-platform-slack).

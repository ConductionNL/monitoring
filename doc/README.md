# Monitoring documentation

Dit dossier beschrijft welke alerts we hebben, wat ze betekenen en hoe je ze test.

## Inhoud
- CoreDNS: zie `rules/CoreDNSNotReady.md`
- CoreDNS (extended): zie `rules/CoreDNSExtended.md`
- Pods: zie `rules/CreateContainerConfigError.md`

## Waar regels vandaan komen
- Regels staan in de repo onder `rules/` als losstaande `PrometheusRule` CRD's.
- Ze worden opgepakt door Prometheus via `ruleSelector.matchLabels.release: mon`.

## Routing van alerts
- Alertmanager configuratie: `alerting/alertmanager.yaml`
- Slack webhook (SOPS secret): `alerting/secret-alertmanager.sops.yaml`
- Voor e-mail of extra kanalen: voeg een receiver toe in `alerting/alertmanager.yaml` en (indien nodig) een extra secret.

## Testen
- Forceer een bekende conditie (zie elk rule-document) en controleer in:
  - Prometheus UI: Alerts tab
  - Alertmanager UI: actieve alerts en routing
  - Slack/e-mail: ontvangst van notificatie

### Port-forward UIs
```bash
# Prometheus
kubectl -n monitoring port-forward svc/mon-kube-prometheus-stack-prometheus 9090:9090
# open http://127.0.0.1:9090

# Alertmanager
kubectl -n monitoring port-forward svc/mon-kube-prometheus-stack-alertmanager 9093:9093
# open http://127.0.0.1:9093

# Grafana (optioneel, indien service aanwezig)
kubectl -n monitoring port-forward svc/mon-grafana 3000:80
# open http://127.0.0.1:3000 (user/pass via Secret grafana-admin)
```


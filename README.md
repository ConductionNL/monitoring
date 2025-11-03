# Monitoring GitOps (private repo) — Starter

**Stack**: Argo CD + kube-prometheus-stack (Prometheus Operator) + Alertmanager + (optioneel) Grafana.
**Secrets**: SOPS (age). Repo is **private**; geen plaintext secrets.

## Inhoud
- `overlays/prod`: Kustomize overlay met losse resources (rules, alerting) naast de Helm chart (via Argo CD multiple sources).
- `rules/`: Losse `PrometheusRule` CRD's. Labels bevatten `release: mon` voor selector-match.
- `alerting/alertmanager.yaml`: Alertmanager routes/receivers (zonder secret).
- `alerting/secret-alertmanager.sops.yaml`: **SOPS-versleuteld** geheim (Slack webhook). Wordt lokaal gegenereerd via het bootstrap-script.
- `apps/`: Argo CD `Application` manifests per omgeving.
- `.sops.yaml`: SOPS policy (welke paden versleuteld moeten worden).

## Bootstrap (lokaal, vóór eerste commit)
1. Installeer SOPS en age.
2. Genereer age key en versleutel Slack webhook:
   ```bash
   ./bootstrap_sops.sh
   ```
   Dit maakt:
   - `alerting/secret-alertmanager.sops.yaml` (encrypted)
   - `age.agekey` (privé sleutel; **niet committen**).

3. Argo CD repo-server configureren: plaats de age private key in het cluster (bv. als Secret + volume mount) zodat Argo sops kan decrypten tijdens sync.
   - Documentatie Argo + SOPS: repo-server plugin of sidecar; zorg dat `sops` binary aanwezig is.

4. **Syncen**
   ```bash
    kubectl -n argocd apply -f apps/app-prom-prod.yaml
   ```

5. **Verifiëren**
   ```bash
   # Prometheus
   kubectl -n monitoring port-forward svc/mon-kube-prometheus-stack-prometheus 9090:9090
   open http://127.0.0.1:9090    # Status -> Rules / Alerts

   # Alertmanager
   kubectl -n monitoring port-forward svc/mon-kube-prometheus-stack-alertmanager 9093:9093
   open http://127.0.0.1:9093
   ```

6. **Notes**: Single-cluster setup (alleen `overlays/prod`).

## Belangrijke keuzes
- Repo is private; alle secrets via SOPS. Geen GitHub Secrets gebruiken voor Argo.
- Eén bron van waarheid: losse `PrometheusRule` bestanden in `rules/`.
- Slack notificaties via Alertmanager; Grafana voor visualisatie.

## Cleanup/Notes
- Pas `namespace` of `channel` aan naar jullie werkelijkheid.
- Voeg extra rules/dashboards als losse bestanden toe (reviewbaar).

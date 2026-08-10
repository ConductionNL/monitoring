---
last_reviewed: 2026-08-10
owner: info@conduction.nl
---

# ArgoCDCredentialRefreshStale

- Bron: `prometheus/rules/argocd/rules-credential-refresh.yaml`
- Alert: `ArgoCDCredentialRefreshStale`
- Severity: `critical`

## Betekenis
De CronJob `argocd-credential-refresh` (namespace `argocd`, elke 12 uur) heeft
al meer dan 14 uur geen succesvolle run gehad. Die job haalt via de
Gardener-API verse 24-uurs-kubeconfigs op voor de shoot-clusters (con-prod,
conductionprod, test-accept) en schrijft ze als `cluster-api.*`-secrets. Staat
hij stil, dan verliest Argo CD binnen 24 uur de toegang tot alles wat het
beheert. De achtergrond staat in `cluster-infra/docs/argocd.md`
§ Credential-refresh.

## Trigger
- `time() - kube_cronjob_status_last_successful_time{namespace="argocd", cronjob="argocd-credential-refresh"} > 14 * 3600` (for: 15m)

## Runbook
1. Bekijk de laatste jobs: `kubectl -n argocd get job`. Een `Failed` job wijst
   naar de oorzaak; de pod blijft staan (`restartPolicy: Never`), dus
   `kubectl -n argocd logs job/<naam>` werkt.
2. Bekijk in de log de regel `Gardener-token: <n>d resterend`. De job verlengt
   sinds 2026-08-10 zijn eigen token (90 dagen looptijd, drempel 30 dagen), dus
   een verlopen token betekent dat de job zélf al langer dan 90 dagen niet
   succesvol heeft gedraaid — dan is handmatige rotatie nodig als break-glass.
   Staat er een waarschuwing over minten of patchen, dan is de verlenging het
   probleem en niet de refresh. Expiry uitlezen zonder het token te tonen, de
   drempels (`RENEW_BEFORE_DAYS`, `TOKEN_DURATION`) en de handmatige procedure:
   `cluster-infra/docs/argocd.md` § Credential-refresh.
3. Na rotatie een handmatige run forceren:
   `kubectl -n argocd create job --from=cronjob/argocd-credential-refresh argocd-credential-refresh-manual-<datum>`
4. Controleer dat het client-certificaat in de drie `cluster-api.*`-secrets
   subject `…:garden-wh2mnkj:argocd-automation` heeft. Staat er een
   persoonlijke identiteit (bijvoorbeeld `mark-conduction`), dan houdt het
   werkstation-vangnet `mcc-login.timer` Argo overeind terwijl de CronJob in
   werkelijkheid stil is — dat is geen oplossing.

## Blinde vlek
Deze regel meet de tijd sinds het laatste succes. Wordt de CronJob zelf
verwijderd of gesuspendeerd, dan verdwijnt de metric en zwijgt de alert. Een
verdwenen `argocd-credential-refresh` valt dus niet op via dit signaal.

## Verwachte routing
- Slack default receiver (`team-platform-slack`).

## Test
- `kubectl -n argocd patch cronjob argocd-credential-refresh -p '{"spec":{"suspend":true}}'`
  laat de metric bevriezen; na 14u vuurt de alert. In de praktijk te lang om af
  te wachten — controleer liever de expr handmatig in de Prometheus-UI, waar de
  waarde na een succesvolle run terug naar bijna nul moet lopen.

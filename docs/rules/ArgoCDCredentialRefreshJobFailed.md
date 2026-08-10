---
last_reviewed: 2026-08-10
owner: info@conduction.nl
---

# ArgoCDCredentialRefreshJobFailed

- Bron: `prometheus/rules/argocd/rules-credential-refresh.yaml`
- Alert: `ArgoCDCredentialRefreshJobFailed`
- Severity: `warning`

## Betekenis
Een run van de CronJob `argocd-credential-refresh` is gefaald (Job-conditie
`Failed`, meestal `BackoffLimitExceeded`). Dit is het vroege signaal: één
mislukte run is nog niet acuut, want de vorige `cluster-api.*`-credentials zijn
24 uur geldig. Blijft het falen, dan volgt
[`ArgoCDCredentialRefreshStale`](ArgoCDCredentialRefreshStale.md) en wordt het
wel acuut.

## Trigger
- `kube_job_failed{namespace="argocd", job_name=~"argocd-credential-refresh-.*", condition="true"} > 0` (for: 5m)

## Runbook
1. `kubectl -n argocd logs job/<job_name>` — de pod blijft bestaan
   (`restartPolicy: Never`), dus de logs zijn er nog. Zijn ze weg, dan heeft
   `failedJobsHistoryLimit: 3` ze opgeruimd.
2. `kubectl -n argocd describe job <job_name>` voor de conditie en de events.
3. Verlopen Gardener-token is de bekende oorzaak. De job verlengt zijn token
   sinds 2026-08-10 zelf; een waarschuwing in de log over minten of patchen is
   het vroege signaal dat die verlenging niet lukt — dan blijft er nog
   `RENEW_BEFORE_DAYS` (30) tijd om het handmatig te doen. Procedure:
   `cluster-infra/docs/argocd.md` § Credential-refresh.
4. Na de fix een handmatige run forceren en het certsubject verifiëren — de
   stappen staan in het runbook van `ArgoCDCredentialRefreshStale`.

## Verwachte routing
- Slack default receiver (`team-platform-slack`).

## Test
- Vervang tijdelijk de inhoud van `gardener-sa-kubeconfig` door een ongeldige
  waarde in een niet-productieomgeving, of wacht een echte storing af. Niet op
  con-prod forceren: de job schrijft de credentials waar Argo CD op leunt.

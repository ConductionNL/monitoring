# Changelog

Alle belangrijke wijzigingen aan deze repo worden hier vastgelegd. Formaat gebaseerd op [Keep a Changelog](https://keepachangelog.com/nl/1.0.0/).

## [Unreleased]

### Toegevoegd — 2026-08-10 (alerting op Argo CD credential-refresh)

Op 2026-08-10 faalde de CronJob `argocd-credential-refresh` in namespace
`argocd` doordat het Gardener-service-account-token in
`gardener-sa-kubeconfig` was verlopen (90-daagse looptijd, handmatige
rotatie). Dat mechanisme is missiekritisch — valt het stil, dan verliest
Argo CD binnen 24 uur de toegang tot con-prod, conductionprod en
test-accept — maar er stond geen enkele alert op. Het is opgemerkt doordat
iemand toevallig de job-status zag, niet doordat monitoring het meldde.
`cluster-infra/docs/argocd.md` noemde deze alerting al als opvolgpunt voor
deze repo.

- `prometheus/rules/argocd/rules-credential-refresh.yaml` (nieuw), twee regels:
  - `ArgoCDCredentialRefreshStale` (`critical`) — meer dan 14 uur geen
    succesvolle run (12u-schedule plus marge voor één overslaande run). Dit is
    de regel die de storing van vandaag zou hebben gemeld ruim voordat de
    24-uurs-certificaten verliepen.
  - `ArgoCDCredentialRefreshJobFailed` (`warning`) — een individuele run faalt;
    het vroege signaal, nog niet acuut.
- Runbooks `docs/rules/ArgoCDCredentialRefreshStale.md` en
  `docs/rules/ArgoCDCredentialRefreshJobFailed.md`, en een regel in
  `docs/index.md`.
- `apps/app-prom-prod.yaml`: bron voor `prometheus/rules/argocd` toegevoegd.
  De Application somt de rule-mappen **per pad** op in plaats van
  `prometheus/rules` te recursen, dus een nieuwe map wordt zonder deze regel
  nooit gesynct — de regels zouden stil in git blijven liggen. Let hierop bij
  elke volgende rule-map.

Metrieknamen en labels zijn tegen de live kube-state-metrics (v2.17.0,
`mon-kube-state-metrics`) gecontroleerd, niet aangenomen:
`kube_cronjob_status_last_successful_time{namespace,cronjob}` en
`kube_job_failed{namespace,job_name,condition}` bestaan daar met exact deze
labels, en zowel `jobs` als `cronjobs` staan in de `--resources`-lijst zonder
metric-allowlist.

Bekende blinde vlek, vastgelegd in het runbook: wordt de CronJob verwijderd of
gesuspendeerd, dan verdwijnt de metric en zwijgt de stale-alert.

### Toegevoegd — 2026-08-10 (docs-touched-gate, techbook-pin op v0.2.0)

De hookset kende geen gate op §7 van de conventies: documentatie wijzigt
in dezelfde PR als de code die zij beschrijft. `docs-contract` en
`docs-claims` kijken naar de hele boom en nooit naar wat je pusht.
`docs-touched` is de diff-gate die dat wél ziet.

- `.pre-commit-config.yaml`: techbook-pin van `edf269ee…` naar `v0.2.0`
  en `- id: docs-touched` toegevoegd. Die twee horen in één wijziging:
  de hook bestáát niet in `edf269ee…`, dus los toevoegen faalt, en een
  pin op een niet-bestaande rev laat pre-commit al bij het uitchecken
  van de techbook-repo stuklopen — dat zou óók `docs-contract`,
  `docs-claims` en `verify` meenemen. Meteen de eerste tag in plaats van
  een kale sha; daar stappen we vanaf.
- `.docs-touched.yaml` (nieuw): drie regels — `stack/**` + `alerting/**`
  (routing en receivers staan inline in `stack/values.yaml`; alleen
  `docs/alerting.md` beschrijft waar een alert uitkomt),
  `servicemonitors/**` + `grafana/dashboards/**` (de keten van exporter
  tot paneel uit `docs/phpfpm-metrics.md`), en `scripts/**` (ops-scripts
  zonder scripts-assertie). `**/*.sops.yaml` is uitgezonderd: een
  geroteerde webhook verandert geen te documenteren gedrag.
- **`prometheus/rules/**` staat er bewust níét in.** `scripts/verify.sh`
  eist al per alert een runbook in `docs/rules/`, over de hele boom in
  plaats van alleen de diff. Die assertie is strenger dan een diff-gate;
  hem hier herhalen levert twee meldingen voor één fout en geen extra
  dekking.
- `docs/agents.md`: sectie Gates met de verwijzing; `last_reviewed` bij.

De gate staat op **`mode: warn`** — hij rapporteert volledig en geeft
exit 0. Eerst een periode meekijken of de padregels op deze repo geen
ruis opleveren; pas daarna naar `enforce`. Een gate die eeuwig alleen
waarschuwt wordt genegeerd, dus de omzetting hoort na een rustige maand
te gebeuren en niet later.

### Gewijzigd — 2026-08-03 (Argo-bron en runbook-links naar GitHub)

Echte drift, geverifieerd tegen het cluster: de live app `mon` leest
`github.com/ConductionNL/monitoring.git` (Synced/Healthy), terwijl git nog
`codeberg.org` declareerde. Laatste commit op `apps/` was
`d0c71d7 chore: repoint GitHub -> Codeberg`; de weg terug is live gedaan
maar nooit in git geland. Wie dit bestand opnieuw applyde, zette monitoring
terug op Codeberg.

- `apps/app-prom-prod.yaml`: 13× `repoURL` naar
  `github.com/ConductionNL/monitoring.git`.
- `alerting/alertmanager-managed-config.yaml` en `stack/values.yaml`: de
  `runbook_url` in alerts. Let op de vorm — Codeberg gebruikt
  `/src/branch/main/`, GitHub `/blob/main/`; een platte host-swap had
  404's opgeleverd op elke alert-runbooklink.
- `grafana/dashboards/{cluster-overview,node-disk-io,nextcloud-environments}.yaml`:
  dashboard-links naar de docs, zelfde padvorm-correctie.
- `scripts/create-argocd-repo-secret.sh`: het usage-voorbeeld maakte een
  Argo-repo-secret voor de Codeberg-remote — dus credentials voor een
  bron die niet meer gelezen wordt.

**Let op bij applyen: dit manifest doet méér dan de host corrigeren.** Het
declareert 14 sources, de live app heeft er 12. Twee staan in git maar niet
live: `prometheus/rules/nextcloud` en `servicemonitors` (beide met echte
inhoud, uit `9ca5258` — de Nextcloud PHP-FPM-monitoring). Applyen activeert
die dus alsnog. Dat is vermoedelijk gewenst, maar het is een functionele
wijziging bovenop de host-fix, geen bijproduct. `selfHeal` en `prune`
staan aan op deze app.

Gecontroleerd: YAML valide en de embedded dashboard-JSON parseert nog
(host-omzetting in single-line JSON is stil te breken). Nul
Codeberg-refs over behalve `.pre-commit-config.yaml`, die in een aparte PR
zit.
### Toegevoegd — 2026-08-03 (openspec-tooling losgeknipt van de loki-branch)

De openspec-tooling zat opgesloten in `feature/loki-stack-openspec`, in een
commit `chore: preserve local WIP (openspec editor tooling + dashboard
tweak)`. Die branch loopt 19 commits achter op `main` en de loki-stack is
niet uitgerold (0 loki-pods, geen loki-namespace), dus de tooling wachtte op
werk dat nog niet af is. `main` had er nul bestanden van.

Overgezet: `.github/skills/openspec-{explore,propose,apply-change,archive-change}/SKILL.md`
en `.github/prompts/opsx-{explore,propose,apply,archive}.prompt.md` —
8 bestanden, 1250 regels.

**Bewust niet meegenomen — de `.cursor/`-helft.** Die WIP-commit bracht
dezelfde tooling twee keer: de vier `SKILL.md`'s zijn byte-identiek tussen
`.cursor/skills/` en `.github/skills/`, en de vier `.cursor/commands/`
schelen 3 regels frontmatter met hun `.github/prompts/`-tegenhanger. Dat is
precies het patroon dat op 2026-07-14 is verwijderd onder "één
agent-waarheid" (zie de entry hieronder): twee waarheden en een
case-collision. `.github/` is de canonieke plek.

**Ook niet meegenomen — de dashboard-tweak** uit die commit. Die raakt
`grafana/dashboards/nextcloud-environments.yaml`, dat ook in de
Codeberg→GitHub-PR zit; één bestand in twee PR's is een conflict in de maak.

De loki-stack blijft op zijn branch; daar wordt apart tijd voor ingepland.
### 2026-08-03 — pre-commit-hookbron naar GitHub
- `.pre-commit-config.yaml`: de techbook-hook komt van
  `github.com/ConductionNL/techbook` in plaats van `codeberg.org`. De pin
  `edf269ee…` blijft ongewijzigd: die commit bestaat op beide forges en is
  daar voorouder van `main`. Host-only dus — de gates (`docs-contract`,
  `docs-claims`) gedragen zich identiek.
- Waarom: dit was de laatste harde Codeberg-afhankelijkheid buiten talos.
  Zolang die bestond moest `techbook` naar twee forges gepusht blijven
  worden, en dat is niet volgehouden — 7 van de 9 repos zijn daar uit
  elkaar gelopen. De bron van het patroon zat in
  `techbook/scripts/rollout_precommit_hook.sh`, dat deze URL in élke repo
  schreef; die is in dezelfde ronde omgezet.

### Verwijderd — 2026-07-14 (één agent-waarheid: legacy Cursor-era agent-bestanden weg)
- `docs/AGENTS.md` en `.cursor/rules/changelog-and-agents.mdc` verwijderd
  (git-historie is het archief): beide codificeerden Cursor-tijdperk
  agent-afspraken naast het echte cataloog `docs/agents.md` —
  case-collision en twee waarheden. Verwijzing in `docs/index.md`
  rechtgezet. Conform spec-delta add-component-skills (fase 0).

### Gewijzigd — 2026-07-14 (runbooks: receiver vs Slack-kanaal ontward)
- 11 runbooks noemden de routing inconsistent ("team-platform-slack" of
  "#k8s-alerts" door elkaar). Nu overal één regel: Alertmanager-receiver
  `team-platform-slack` → Slack-kanaal `#k8s-alerts` (kanaal hangt aan de
  webhook-URL). Gevonden doordat de platform-assistent de dubbelzinnige
  bron letterlijk citeerde en dat als hallucinatie werd gelezen.

### Gewijzigd — 2026-07-13 (eigenaarschap → info@conduction.nl, review WP8)
- Alle `owner:`-front-matter en CODEOWNERS omgezet van `mark` naar
  `info@conduction.nl` (opvolging na 2026-08-31). Voorbereid op branch
  `chore/wp8-ownership`; review, merge en push door een mens.

### Toegevoegd — 2026-07-13 (SOPS-recipients + custody — review WP4, openspec add-sops-second-recipient)
- `.sops.yaml`: beide age-recipients ingevuld (primair + escrow, custodian
  info@conduction.nl) — de lijst was leeg; een toekomstige bootstrap versleutelt direct
  naar twee sleutels. Zelfde sleutelpaar als talos (besluit WP4).
- `docs/alerting.md`: key-custody-paragraaf + stub-status expliciet benoemd
  (`secret-alertmanager.sops.yaml` is een placeholder; `bootstrap_sops.sh` ontbreekt
  in `scripts/`).

### Toegevoegd
- `grafana/.env.example` — `NEXTCLOUD_NAMESPACES` (komma-gescheiden) voor Nextcloud-dashboard; script leest dit en past dashboard in cluster aan
- `scripts/grafana-nextcloud-dashboard-apply.sh` — past Nextcloud-dashboard toe met namespaces uit `grafana/.env`
- `prometheus/rules/nextcloud/rules-phpfpm-pm.yaml` — PHP-FPM/PM-alerts (PhpFpmDown, PhpFpmMaxChildrenReached, PhpFpmListenQueueHigh, PhpFpmNoIdleProcesses)
- `docs/rules/PhpFpmDown.md`, `PhpFpmMaxChildrenReached.md`, `PhpFpmListenQueueHigh.md`, `PhpFpmNoIdleProcesses.md` — runbooks voor PM-alerts
- `docs/phpfpm-metrics.md` — uitleg exporter + ServiceMonitor voor PHP-FPM metrics
- `grafana/dashboards/cluster-overview.yaml` — cluster-overview (nodes, namespaces, pods, node CPU/memory, pods per namespace)
- `grafana/dashboards/nextcloud-environments.yaml` — Nextcloud-omgevingen (filter op namespace-regex, pods/deployments, CPU/memory per pod)
- `grafana/dashboards/node-disk-io.yaml` — dashboard NodeDiskIOSaturation (disk IO queue, utilization, read/write), met link naar runbook
- `docs/rules/DeploymentUnhealthy.md` — runbook voor DeploymentUnhealthy-alert
- `docs/rules/KubeHpaMaxedOut.md` — documentatie KubeHpaMaxedOut (stack vs eigen HPAMaxedOut)
- `docs/rules/NodeSystemSaturation.md` — runbook NodeSystemSaturation (node load, extreme waarden)
- `grafana/dashboards/node-overview.yaml` — node-overview dashboard
- `grafana/README.md` — documentatie Grafana-dashboards
- `docs/AGENTS.md` — afspraken voor multi-agent werk en changelog
- `.cursor/rules/changelog-and-agents.mdc` — Cursor rule: changelog bijwerken en agent-coördinatie
- `CHANGELOG.md` — dit bestand

### Gewijzigd
- 2026-07-10: `docs/index.md` en `docs/alerting.md` — verouderde verwijzingen naar legacy `alerting/alertmanager.yaml` rechtgetrokken: routing/receivers staan inline in `stack/values.yaml` onder `alertmanager.config`; Slack-kanaal wordt bepaald door de webhook-URL (SOPS), niet door een `channel:`-veld (follow-up semantische review 2026-07-10)
- `apps/app-prom-prod.yaml` — source `prometheus/rules/nextcloud` toegevoegd voor PHP-FPM rules
- `grafana/README.md` — Nextcloud-namespaces via .env + script; dashboards-sectie
- `docs/README.md` — PHP-FPM/PM rules en link naar phpfpm-metrics.md
- `README.md` — inhoud/documentatie
- `docs/README.md` — overzicht rules, testen en verwijzing naar CHANGELOG/AGENTS
- `apps/app-prom-prod.yaml` — Argo CD app configuratie
- `stack/values.yaml` (voorheen overlays/prod/values-prom-stack.yaml) — Helm values (o.a. alert routing, runbook-links naar `docs/rules/`)
- `docs/rules/HPAMaxedOut.md` — aanpassingen runbook
- Verwijzingen `doc/` → `docs/` in o.a. CHANGELOG, docs/AGENTS.md, .cursor/rules, docs/README.md, docs/ROADMAP.md, docs/alerting.md, docs/rules/HPAMaxedOut.md, stack/values.yaml, alertmanager-managed-config.yaml

### Opmerking
- Wijzigingen door Cursor-agents: zie `docs/AGENTS.md` voor afspraken. Elke agent werkt bij voorkeur in eigen deel en werkt **CHANGELOG.md** bij bij commits.

---

## Template voor nieuwe entries (boven [Unreleased])

```markdown
## [Unreleased]

### Toegevoegd
- bestand of feature — korte beschrijving

### Gewijzigd
- bestand — wat er veranderd is

### Verwijderd
- (indien van toepassing)
```

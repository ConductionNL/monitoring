# Changelog

Alle belangrijke wijzigingen aan deze repo worden hier vastgelegd. Formaat gebaseerd op [Keep a Changelog](https://keepachangelog.com/nl/1.0.0/).

## [Unreleased]

### Gewijzigd — 2026-08-10 (Loki eerst op filesystem; twee defecten in de geporte values)

Loki gaat eerst op lokale schijf in plaats van S3. Reden: de enige beschikbare
S3-sleutel is die van de Nextcloud-tenants en kan bij de object storage van
alle 85 tenants. Dat aan een log-shipper hangen is te veel. Op filesystem kun
je de stack nu uitrollen en aantonen dat Alloy podlogs binnenkrijgt, en gaat S3
aan zodra Cyso een eigen sleutel plus bucket `loki-chunks` levert. De logs
staan op de 10Gi-PVC van de SingleBinary-pod, dus dit is een werkende
tussenstand en geen wegwerpopstelling.

- `loki/values.yaml`: `storage.type: filesystem` met chunks/rules-directories;
  het S3-blok staat er uitgecommentarieerd bij. De omzetting raakt **vier**
  plekken, en dat is nu een checklist onderaan het bestand:
  `loki.storage`, `loki.schemaConfig.object_store`,
  `loki.compactor.delete_request_store` en `extraEnvFrom`. Die middelste twee
  stonden nog op `s3` terwijl `storage.type` iets anders zei — precies het
  soort halve omzetting waar die checklist tegen beschermt.
- `extraEnvFrom` uit: de filesystem-stand heeft geen credentials nodig, en zo
  start de pod ook als het secret er niet is.

**Twee defecten die hierbij aan het licht kwamen, beide uit de geporte branch:**

1. **`deploymentMode` stond onder `loki:` in plaats van op topniveau.** De
   chart las hem dus niet, viel terug op de default `SimpleScalable` en rolde
   met `read`/`write`/`backend` op `replicas: 0` alleen de memcached-caches uit.
   **Loki zelf startte nooit.** Aangetoond met `helm template`: vóór de fix gaf
   de render `loki-read`, `loki-write` en `loki-backend`, alle drie op
   `replicas: 0`, en géén StatefulSet `loki`; erna één StatefulSet `loki` met
   `replicas: 1` en een volumeClaimTemplate. Les voor de volgende keer: de
   chart rendert in beide gevallen zonder fout, dus "het rendert" is geen
   bewijs — controleer dat er een StatefulSet `loki` in de output staat.
2. **De chunks-cache vroeg 9830Mi geheugen** (requests én limits), de
   results-cache 1229Mi. Chart-defaults, bedoeld om latency naar object storage
   te dempen; bij lokale schijf valt er niets te dempen, dus het was puur
   beslag op de nodes. `chunksCache` en `resultsCache` uit; bij de omzetting
   naar S3 weer aan, met een bewust gekozen grootte.

Na deze wijziging rendert de chart 12 resources: StatefulSet `loki`
(`replicas: 1`, één PVC), de canary-DaemonSet en het bijbehorende netwerk. Geen
memcached meer, en `filesystem` op alle drie de storage-plekken in de
gerenderde config.

### Gewijzigd — 2026-08-10 (S3-secret opnieuw gezaaid; sops-aanname gecorrigeerd)

De S3-secret voor Loki was versleuteld naar een age-recipient die niemand nog
heeft. Dat hoefde geen blokkade te zijn: dezelfde Fuga-S3-credentials staan al
in het cluster, in 85 namespaces, geseed uit
`nextcloud-platform/nextcloud-s3-seed` (aangemaakt 2026-06-22). Endpoint en
region zijn geen secret en staan in
`Nextcloud-base/nextcloud-platform/values/env/accept.yaml`
(`https://core.fuga.cloud:8080`, path-style).

- `loki/secret-loki-s3.sops.yaml` opnieuw gezaaid naar de twee actuele
  recipients uit `.sops.yaml`, met alle vier de variabelen die
  `loki/values.yaml` verwacht: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
  `S3_ENDPOINT`, `S3_REGION`. De waarden zijn nooit ontsleuteld weergegeven.
- `apps/app-loki-prod.yaml`: `secret-*.sops.yaml` weer **uitgesloten** van de
  manifest-source. De vorige entry beweerde dat de repo-server sops
  ontsleutelt; dat is niet zo. Gecontroleerd in het cluster: de enige
  `configManagementPlugin` is `helmfile`, er is geen age-sleutel in namespace
  `argocd`, en de repo-server heeft geen sops-env of -binary. Zonder deze
  uitsluiting applyt Argo het versleutelde bestand letterlijk en krijgt Loki
  `ENC[AES256_GCM,...]` als wachtwoord — dezelfde klasse fout als 2026-07-13,
  toen een applybaar voorbeeldbestand werkende secrets overschreef. Daarom is
  `alerting/secret-alertmanager.sops.yaml` ook 100% commentaar en niet
  applybaar.

`loki-s3-credentials` is daarmee een bootstrap-secret dat een mens plaatst:
`kubectl -n monitoring apply -f <(sops -d loki/secret-loki-s3.sops.yaml)`.

**Openstaand besluit, geen wijziging hier:** dit is één sleutel voor de object
storage van alle 85 Nextcloud-tenants. Die in `monitoring` zetten geeft de
logstack read/write op alle klantdata. Voor een log-shipper is dat te veel;
vraag bij Cyso een eigen sleutel plus een eigen bucket `loki-chunks`. De
hergebruik-route werkt, maar hoort geen eindstand te zijn. Ook nog onbekend:
of `S3_ENDPOINT` zonder schema en `S3_REGION: us-east-1` kloppen voor Loki's
S3-client, en of de bucket `loki-chunks` bestaat.

### Gewijzigd — 2026-08-10 (feature branches opgeruimd: alles op main)

De twee loki-branches zijn leeggehaald zodat er geen eeuwige feature branch
overblijft. Wat er nog buiten `main` lag:

- **`feat/loki-stack`** — de fix-commit is hier gemerged (`--no-ff`, historie
  behouden). Die is niet cosmetisch: zonder de omzetting naar het chart-schema
  rendert de Loki-chart niet, en `apps/app-loki-prod.yaml` staat al op main.
  Wie die Application had geapplied vóór deze merge, had een Application
  gekregen die nooit kon syncen. Er is nog geen `loki`-Application in het
  cluster, dus er is niets kapotgegaan.
- **`feature/loki-stack-openspec`** — hiervan is alleen
  `grafana/dashboards/nextcloud-environments.yaml` overgenomen: het
  PHP-FPM-paneel legt nu de geconfigureerde limieten (`pm.max_children`,
  start/spare-servers) over het actuele aantal processen heen, zodat je gebruik
  tégen de limiet ziet in plaats van twee losse grafieken. Bij het overnemen
  zijn de CRLF-regeleindes van die branch naar LF omgezet, conform
  `.gitattributes` (commit `4e6f48c`).

De rest van `feature/loki-stack-openspec` is bewust niet overgenomen. Die
branch is een momentopname van 37 commits terug: een merge zou
`scripts/verify.sh` verwijderen, de nieuwe argocd-alertregels weggooien en ~105
bestanden terugzetten naar CRLF. De enige unieke inhoud was het dashboard
hierboven en opsx-tooling in `.cursor/`, en die tooling staat op main al onder
`.github/` — één agent-waarheid, zie commit `71ea0a6`. Beide branches kunnen na
deze merge weg.

### Toegevoegd — 2026-08-10 (Loki + Alloy logstack, geport van een oude branch)

Loki draait **niet** in het cluster: er is geen Argo CD-Application `loki`
en geen bijbehorende workload. Dit is dus geen wijziging aan iets
bestaands maar een **nieuwe uitrol**, die pas gebeurt op het moment dat
deze PR merget — Argo pakt `apps/app-loki-prod.yaml` dan op en maakt Loki,
Alloy, de datasource en de alertregels aan in namespace `monitoring`.

Inhoud geport uit `feature/loki-stack-openspec` (3 juni, één WIP-commit).
Die branch is niet gemerged maar overgezet: hij mist alles wat main sinds
juni kreeg en sleepte tooling mee die hier niet hoort.

- `apps/app-loki-prod.yaml` (nieuw): Argo CD-Application met vier sources
  — de Helm-charts `loki` en `alloy`, een `ref: values` en de plain
  manifests uit `loki/`.
- `loki/values.yaml`, `loki/alloy-values.yaml`, `loki/alloy-config.yaml`,
  `loki/datasource-loki.yaml`, `loki/alerts/hydra-pipeline-failures.yaml`,
  `loki/secret-loki-s3.sops.yaml` (nieuw).
- `docs/rules/HydraPipelineFailure.md` (nieuw): herschreven naar de
  huisstijl van deze repo (Bron / Betekenis / Trigger / Runbook /
  Verwachte routing / Test) met front-matter. De branchversie was Engels,
  zonder front-matter, en beweerde routing naar `team-platform-slack` die
  niet bestaat.
- `openspec/changes/loki-stack/**` (nieuw): proposal, design, tasks,
  README en vijf spec-delta's, ongewijzigd overgenomen.
- `scripts/verify.sh`: scant nu ook `loki/alerts/`. Die alerts zijn geen
  `PrometheusRule` maar Grafana Unified Alerting-regels in een ConfigMap,
  dus ze krijgen een eigen structuurcheck (kind, label `grafana_alert`,
  title, expr) maar vallen onder dezelfde runbook-dekkingseis. Zonder
  deze uitbreiding was de dekking stil onvolledig: een log-alert zonder
  runbook was er ongemerkt doorheen gekomen. Negatief getest.
- `.docs-touched.yaml`: regel `log-collectie` op `loki/**`, met
  `loki/alerts/**` uitgezonderd (verify dekt dat al, over de hele boom in
  plaats van de diff) en `**/*.sops.yaml` uitgezonderd (zelfde afweging
  als bij `alertmanager-routing`). Reden: `alloy-config.yaml` bepaalt
  welke logs bestaan en `values.yaml` hoe lang, en dat merk je pas als je
  ze tijdens een incident mist.
- `docs/index.md`, `docs/alerting.md`: sectie logverzameling (wat wordt
  verzameld, retentie, opslag, bevragen) en de vastlegging dat
  Grafana-log-alerts níét via Alertmanager lopen.

**Bewust niet overgenomen:** `.claude/**` en `.cursor/**` (opsx-tooling;
main heeft dit onder `.github/`), `docs/AGENTS.md` (main heeft bewust één
agent-waarheid, `docs/agents.md`), en `alerting/alertmanager.yaml`. Dat
laatste bevat géén Loki-route — het is de legacy
`configMapOverrideName`-ConfigMap die main op 2026-07-10 juist heeft
opgeruimd, en de routing staat inmiddels inline in `stack/values.yaml`.
Terugzetten zou een opgeruimd bestand laten herleven zonder dat het iets
voor Loki doet. Er is dus geen Alertmanager-wijziging nodig: log-alerts
lopen via Grafana.

**Aangepast t.o.v. de branch:** de `repoURL`'s in de Application stonden
op `git@github.com:` (SSH); main gebruikt overal `https://github.com/…`
zoals in `apps/app-prom-prod.yaml`. Verder is de uitsluiting van
`secret-*.sops.yaml` uit de manifest-source geschrapt: dan zou de secret
nooit worden aangemaakt terwijl `loki/values.yaml` er via `extraEnvFrom`
op leunt. `alerting/` doet dit in `app-prom-prod.yaml` op dezelfde manier.

**Chartversies bewust niet gebumpt.** Beide pins bestaan nog upstream en
zijn niet deprecated, dus conform de afspraak blijven ze staan; het
verschil is wel groot en vraagt een aparte, geteste stap: `loki` 6.29.0
(appVersion 3.4.2, maart 2025) tegenover 7.2.0 nu, en `alloy` 0.12.0
(appVersion v1.7.0, feb 2025) tegenover 1.11.1 nu.

**Vier van de zes blokkades zijn opgelost; twee bleven liggen.**

Opgelost in deze wijziging:

1. **De chart rendeerde helemaal niet.** `loki/values.yaml` gebruikte het
   schema van Loki's eigen config (`storage.s3.bucketnames`,
   `access_key_id`) in plaats van dat van de chart
   (`storage.bucketNames.chunks`, `accessKeyId`). `helm template` viel om
   op `nil pointer evaluating interface {}.chunks`; de Application zou dus
   nooit gesynct hebben. Omgezet naar het chart-schema.
2. **SingleBinary botste met zijn eigen validatie.** De chart-defaults
   zetten `read`, `write` en `backend` op replicas > 0; samen met
   `singleBinary.replicas: 1` faalt de render op "more than zero replicas
   configured for both targets". Alle drie expliciet op 0.
3. **Env-vars expandeerden niet.** `global.extraArgs: ["-config.expand-env=true"]`
   toegevoegd — de chart noemt die vlag zelf als voorbeeld. Zonder dit
   komt de letterlijke tekst `${S3_ENDPOINT}` in de config terecht.
4. **De alerts-sidecar en de datasource-uid.**
   `grafana.sidecar.alerts.enabled: true` in `stack/values.yaml` (label
   `grafana_alert`, matcht wat `loki/alerts/*.yaml` zet), en `uid: loki`
   op de datasource zodat `datasourceUid: loki` in de alertregel niet
   doodloopt.

Beide charts renderen nu: `loki` 25 resources, `alloy` 6.

**Blijft staan, vóór de merge:**

1. **De S3-secret is niet te ontsleutelen.** `loki/secret-loki-s3.sops.yaml`
   is versleuteld naar `age1l2k98…dyehmy`, een recipient van vóór de
   WP4-sleutelwissel die niemand nog als private sleutel heeft.
   `sops updatekeys` kan dat niet repareren — opnieuw zaaien is de enige
   weg. Het bestand is hier ongewijzigd gekopieerd en nooit ontsleuteld.
   `.sops.yaml` heeft nu wél een creation-rule voor `loki/secret-*.sops.yaml`
   naar de twee actuele recipients, zodat dat zaaien één commando is.
   De secret moet `S3_ENDPOINT`, `S3_REGION`, `AWS_ACCESS_KEY_ID` en
   `AWS_SECRET_ACCESS_KEY` bevatten, en `loki-chunks` moet als bucket
   bestaan.
2. **De alert vuurt op iets dat niet draait.** `HydraPipelineFailure`
   query't `{namespace=~"hydra.*"}`. Er is geen `hydra`-namespace en geen
   Argo-Application die die pipeline uitrolt, dus de alert blijft in
   `noDataState: OK`. Onschadelijk, en klopt zodra Hydra er wél is; wie
   hem nu niet wil, haalt de regel en het runbook weg.

**Waarom dit niet eerder opviel:** `scripts/verify.sh` rendert geen charts.
De doc-asserties en de alertstructuurcheck draaien wel, maar een values-bestand
dat de chart laat omvallen passeert ongezien. Een render-check in de gate zou
blokkades 1 tot en met 3 hebben gevangen.

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

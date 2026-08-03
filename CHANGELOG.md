# Changelog

Alle belangrijke wijzigingen aan deze repo worden hier vastgelegd. Formaat gebaseerd op [Keep a Changelog](https://keepachangelog.com/nl/1.0.0/).

## [Unreleased]

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

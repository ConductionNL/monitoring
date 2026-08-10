---
last_reviewed: 2026-08-10
owner: info@conduction.nl
---

# Agent-cataloog (referentie)

Guardrails voor agents in deze repo, per het handboek-formaat
(org → Werken met agents). **Niet in dit cataloog = eerst vragen.**

## Operaties

| Operatie | Autonomie | Idempotentie | Verificatie |
|---|---|---|---|
| Alert toevoegen/wijzigen **mét** runbook-pagina | autonoom | declaratief (PrometheusRule) | verify: structuur + runbook-dekking + `release: mon`-label; zonder runbook faalt de gate |
| Runbook schrijven/bijwerken (huisstijl-sjabloon) | autonoom | tekstueel | docs-contract-gate |
| Grafana-dashboards / exporter-config voorbereiden | autonoom bewerken | declaratief | verify + render waar mogelijk; apply mens |
| Alertmanager-routing/receivers wijzigen | mens-vereist | — | raakt paging/Slack van het hele team; agent bereidt diff voor |
| SOPS-secrets (Slack-webhook, age) | mens-vereist | — | nooit ontsleutelen of aanmaken; procedure staat in alerting.md |
| `kubectl`/Helm/Argo-mutaties; connectivity-tests draaien | mens-vereist | — | agent levert commando + verwachte uitkomst |
| Push | mens-vereist | — | gates draaien bij de mens |
| Alert verwijderen zonder het runbook te archiveren; `age.agekey` of andere secrets committen | verboden | — | .gitignore + gitleaks zijn het vangnet, niet de vrijbrief |

## Gates

Naast `docs-contract`, `docs-claims` en de runbook-dekking in verify
draait sinds 2026-08-10 de diff-gate `docs-touched`: raakt een push
`stack/`, `alerting/`, `servicemonitors/`, `grafana/dashboards/` of
`scripts/`, dan hoort er documentatie mee te wijzigen. `prometheus/rules/`
staat er bewust níét in — de runbook-dekking in verify bewaakt dat al,
over de hele boom in plaats van alleen de diff. De padregels met hun
reden staan in `.docs-touched.yaml` in de repo-root; de gate staat op
`mode: warn` en blokkeert dus nog niet. Configformaat, vrijstelling
(`Docs-not-needed`-trailer) en verificatie: techbook
`docs/docs-touched.md`.

## Grondwaarheid en gedrag

- Handboek (MCP `conduction-docs`) boven modelkennis; `docs/index.md`
  hier is de ingang, de runbook-huisstijl staat daar vastgelegd.
- GET-check-first: bestaat de alert/runbook al, wat is de huidige
  trigger — lees vóór je schrijft.

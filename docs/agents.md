---
last_reviewed: 2026-07-08
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

## Grondwaarheid en gedrag

- Handboek (MCP `conduction-docs`) boven modelkennis; `docs/index.md`
  hier is de ingang, de runbook-huisstijl staat daar vastgelegd.
- GET-check-first: bestaat de alert/runbook al, wat is de huidige
  trigger — lees vóór je schrijft.

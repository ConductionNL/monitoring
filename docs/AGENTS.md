# Afspraken voor Cursor-agents (multi-agent)

Dit document beschrijft hoe meerdere Cursor-agent-sessies in deze repo kunnen samenwerken zonder elkaar in de weg te lopen.

## Doel
- **Documentatie en changelog** goed bijhouden.
- **Wijzigingen borging**: alles wat verandert komt in `CHANGELOG.md`.
- **Geen conflicten**: duidelijke afspraken zodat agents niet tegelijk dezelfde bestanden anders aanpassen.

## Changelog (CHANGELOG.md)
- Staat in de **root** van de repo: `CHANGELOG.md`.
- Elke inhoudelijke wijziging (rules, dashboards, values, docs, scripts) moet onder **`[Unreleased]`** worden vastgelegd met:
  - **Toegevoegd** — nieuwe bestanden/features
  - **Gewijzigd** — bestaande bestanden aangepast
  - **Verwijderd** — verwijderde bestanden (indien van toepassing)
- Formaat per regel: `- bestand of onderdeel — korte beschrijving`.

## Rolverdeling (aanbevolen)
- **Agent die “documentatie / changelog in de gaten houdt”**  
  Verantwoordelijk voor het actueel houden van `CHANGELOG.md`. Kan op basis van git status of wat de andere agent in de chat meldt de changelog bijwerken. Beperk wijzigingen aan andere bestanden tot wat nodig is voor documentatie (bijv. `docs/README.md`, `docs/rules/*.md`).

- **Agent die features/config doet**  
  Focust op rules, Helm values, Argo CD, Grafana, Alertmanager, etc. Meldt aan het einde van een taak **wat er gewijzigd is** (bestanden + korte omschrijving), zodat de documentatie-agent of dezelfde agent de changelog kan bijwerken.

## Namen geven (optioneel)
Om bij het switchen tussen chats duidelijk te hebben wie wat doet, kun je sessies een naam/rol geven (bijv. in de chat-titel of in je hoofd):
- **Doc** / **Changelog** — documentatie en CHANGELOG bijhouden  
- **Rules** / **Config** — Prometheus rules, Helm values, Grafana, Alertmanager  

Vul hieronder in wat jij gebruikt (of laat leeg):

| Rol        | Naam (vrij invullen) | Focus                          |
|-----------|----------------------|--------------------------------|
| Documentatie | *bijv. Doc*       | CHANGELOG, docs/, runbooks     |
| Features/config | *bijv. Rules*  | rules/, overlays/, grafana/, alerting/ |

## Hoe elkaar niet in de weg lopen
1. **Eén changelog**: geen aparte “agent-log” of “session-log” bestanden; alles in `CHANGELOG.md`.
2. **Domeinen**: waar mogelijk, werk in verschillende delen van de repo (bijv. de ene agent vooral `docs/rules/`, de andere `overlays/` of `grafana/`). Bij overlap: wijzigingen klein en atomisch houden.
3. **Cursor rule**: in `.cursor/rules/changelog-and-agents.mdc` staan dezelfde afspraken; die rule geldt voor alle sessies die deze repo openen.

## Autofix-agent (Argo Events)
De **autofix** in deze repo is de **Argo Events Sensor** (`alerting/argo-events/sensor-autofix.yaml`) die op Alertmanager-events reageert en o.a. rollouts herstart. Dat is een **cluster-component**, geen Cursor-agent. Wijzigingen aan die sensor of bijbehorende config horen ook in `CHANGELOG.md` onder `[Unreleased]`.

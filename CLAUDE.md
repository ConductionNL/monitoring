# CLAUDE.md

Prometheus-stack (kube-prometheus-stack, release `mon`) met per alert
een runbook. Ingang: `docs/index.md`; elke alert-regel is een
PrometheusRule-CRD onder `prometheus/rules/` met label `release: mon`
(anders pakt Prometheus hem niet op — dat is een geteste bewering).

## Agent-guardrails

- Operatie-cataloog: `docs/agents.md` — **niet gecatalogiseerd = eerst
  vragen**. Kernregel: geen alert zonder runbook (gate-gedekt).
- Grondwaarheid: MCP `conduction-docs` (handboek) boven modelkennis.
- Vóór afronden: `./scripts/verify.sh` groen; docs mee in dezelfde
  wijziging. Alertmanager-routing, secrets, kubectl en push doet een
  mens. Nooit `--no-verify`.

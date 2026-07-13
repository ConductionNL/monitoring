---
last_reviewed: 2026-07-06
owner: info@conduction.nl
---

# KubeHpaMaxedOut

- Bron: **kube-prometheus-stack** (standaard regel, niet in deze repo).
- Alert: `KubeHpaMaxedOut`
- Severity: `warning`

## Betekenis
Een Horizontal Pod Autoscaler draait al **langer dan 15 minuten** op het maximum aantal replicas. De HPA kan niet verder omhoog schalen; bij toenemende load bestaat risico op underprovisioning.

Je ziet deze alert o.a. als: *"HPA is running at max replicas – HPA kube-system/coredns has been running at max replicas for longer than 15 minutes on cluster"*.

## Verschil met HPAMaxedOut
In deze repo staat ook een eigen regel **HPAMaxedOut** (vuurt na 10m). Beide alerts betekenen hetzelfde; de stack-regel vuurt 5 minuten later (15m). Runbook is voor beide hetzelfde. Om alleen onze 10m-regel te gebruiken: in `stack/values.yaml` onder `defaultRules.disabled` o.a. `KubeHpaMaxedOut: true` zetten.

## Trigger (stack)
- HPA `current_replicas == max_replicas` gedurende **15m** (exacte expressie zit in de Helm chart).

## Runbook

### Algemeen
1. Bekijk workload: `kubectl -n <namespace> get hpa <hpa-name>` en events.
2. Check resource **requests** (te laag → HPA schaalt snel naar max) en **maxReplicas** (te laag → plafond bereikt).
3. Verhoog `maxReplicas` en/of stel requests/limits bij; optimaliseer de app indien nodig.

### Specifiek: CoreDNS (kube-system/coredns)
- CoreDNS heeft vaak een HPA op CPU. Als die lang op max staat:
  1. **Korte termijn**: verhoog `maxReplicas` van de CoreDNS HPA (bijv. in Helm values of manifest).
  2. **Oorzaak**: veel DNS-queries (nieuwe workloads, misconfiguratie, retries). Check CoreDNS metrics (queries/sec) en of er onnodige DNS-load is.
  3. Overweeg node-local DNS cache of tuning van CoreDNS resources/requests als het structureel voorkomt.

## Verwachte routing
- Slack default receiver (`team-platform-slack`).

## Test (non-prod)
- Zet een test-HPA bewust laag (lage maxReplicas) en genereer load; na 15m zou deze alert (of na 10m onze HPAMaxedOut) moeten vuren.

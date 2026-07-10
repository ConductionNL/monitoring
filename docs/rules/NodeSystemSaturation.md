---
last_reviewed: 2026-07-06
owner: mark
---

# NodeSystemSaturation

- Bron: **kube-prometheus-stack** (standaard regel, node-exporter).
- Alert: `NodeSystemSaturation`
- Severity: `warning`

## Betekenis
De **systeemload per CPU-core** op een **node** (host) is te hoog: gemiddeld > 2 gedurende 15 minuten. Dat wijst op CPU-saturatie op die machine; de node kan traag of onbereikbaar worden.

## Let op: waar gaat de alert over?

De alert gaat over de **node** (het fysieke/virtuele systeem), **niet** over de namespace of de node-exporter zelf.

- **Instance 10.250.3.208:9100** = de **node** waar de metriek vandaan komt (9100 is de node-exporter poort).
- **Namespace=monitoring, Pod=mon-prometheus-node-exporter-…** = de **node-exporter** pod die **op die node** draait en de metriek aanlevert. Die pod zit in de monitoring namespace, maar de **saturatie is op de node**, niet specifiek in monitoring. Alle workloads op die node kunnen de load veroorzaken.

Dus: het probleem is de **node** (bijv. 10.250.3.208), niet "de monitoring namespace".

## Extreme waarden (bijv. 930)

Een **load per core van 930** is in de praktijk onrealistisch; een echte machine zou dan al lang zijn vastgelopen. Mogelijke verklaringen:

1. **Metriek/relabel** – verkeerde eenheid, ontbrekende of foutieve `node_cpu_seconds_total` (deling door 0 of heel klein getal).
2. **Korte piek** – uitzonderlijke spike die in de alert terechtkwam.
3. **Verkeerde instance** – dubbel instance-label of verkeerde scrape.

**Actie:** verifieer de load via **Prometheus** of de **cloud/beheer-console** van jullie managed K8s (geen SSH nodig). Als de node daar normaal oogt maar de alert 900+ toont, richt je op metric/relabel/config van node-exporter/Prometheus.

## Trigger (stack)
- `(node_load1 / aantal_cores) > 2` gedurende **15m** (node_exporter, job="node-exporter").

## Runbook

1. **Node identificeren**  
   Gebruik het `instance`-label (bijv. `10.250.3.208:9100`) → node-IP is het deel vóór de dubbele punt.

2. **Load op de node verifiëren** (zonder SSH – managed K8s)
   - **Prometheus**: `node_load1{instance="10.250.3.208:9100"}` en `count without (cpu, mode) (node_cpu_seconds_total{instance="10.250.3.208:9100", mode="idle"})` (aantal cores). De ratio load/cores moet kloppen met de alertwaarde; bij 930 vaak een metric/relabel-fout.
   - **Cloud/beheer-console**: kijk naar CPU- en load-metrics van de node in de provider-console (AWS/GCP/Azure, Gardener, etc.).
   - **Debug pod op de node** (indien toegestaan): `kubectl debug node/<NODE_NAME> -it --image=busybox` en dan `cat /proc/loadavg` (niet overal beschikbaar).

3. **Welke workloads zitten op die node?**  
   ```bash
   kubectl get pods -A -o wide --field-selector spec.nodeName=<NODE_NAME>
   ```  
   Zoek naar CPU-intensieve pods (app, batch jobs, build pods, etc.).

4. **Mitigatie**  
   - Tijdelijke verlichting: zware pods verplaatsen (andere node), of node cordonen/drainen.  
   - Structureel: resource requests/limits aanscherpen, HPA, of meer/sterkere nodes.

5. **Bij onrealistische waarden (bijv. 930)**  
   - In Prometheus voor die instance controleren: `node_load1`, `count(node_cpu_seconds_total{mode="idle"})` (aantal cores).  
   - Controleren of er relabels of meerdere scrapes zijn die de ratio kapot maken; indien nodig default rule uitzetten tot het is opgelost: `defaultRules.disabled.NodeSystemSaturation: true` in `stack/values.yaml`.

## Verwachte routing
- Slack via default receiver (`team-platform-slack`).

## Test (non-prod)
- Op een testnode kunstmatig hoge CPU-load genereren (bijv. `stress-ng`) en wachten tot de alert vuurt; daarna load stoppen en Resolved controleren.

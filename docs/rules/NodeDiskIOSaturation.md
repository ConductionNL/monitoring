---
last_reviewed: 2026-07-06
owner: mark
---

# NodeDiskIOSaturation

- Bron: kube-prometheus-stack default rules
- Alert: `NodeDiskIOSaturation`
- Severity: `warning`

## Betekenis
Hoge I/O-queue/disk-wachttijd op een node. De schijf kan het aantal I/O-verzoeken niet bijbenen (sustained queue depth / time-weighted I/O).

## Typische trigger
Afgeleid van `node_exporter` disk-timers (o.a. `node_disk_io_time_weighted_seconds_total`). Duurt even voort voordat de alert vuurt.

## Runbook
1. Bepaal node en (indien bekend) device
   - In Slack/Alertmanager zie je het `instance`/`node` label.
   - In Prometheus:
     - `topk(5, rate(node_disk_io_time_weighted_seconds_total[5m]))`
     - `topk(5, rate(node_disk_io_time_seconds_total[5m]))`
2. Welke pods veroorzaken I/O op die node?
   - `kubectl get pods -A -o wide --field-selector spec.nodeName=<NODE>`
   - Controleer bekende I/O-intensieve workloads (db, backup, logging, indexing).
   - Heeft de pod PVC’s? Kijk PVC/SC:
     - `kubectl -n <NS> get pod <POD> -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}'`
     - `kubectl -n <NS> describe pvc <PVC>`
3. Cloud/volume-tuning (indien van toepassing)
   - EBS: migreer naar gp3 en zet IOPS/throughput hoger; of kies snellere class.
   - Overweeg node-type met snellere (NVMe) disks voor I/O-zware apps.
4. Werkload-tuning
   - Verminder parallelisme/gelijktijdigheid (backup/batch/cronjobs spreiden).
   - Voor databases: batch/fsync-tuning, query-optimalisatie.
5. Tijdelijke mitigatie
   - Verplaats zware pods naar andere nodes (affinity/taints) of `cordon/drain` probleemnode.
6. Validatie
   - Alert gaat naar Resolved; grafieken van bovenstaande queries dalen zichtbaar.

## Routing
- Slack via default receiver; herhaalinterval ingesteld op 24h (ruisreductie).

## Test
- Genereer I/O op een testpod (bijv. `fio`, `dd`) en observeer de queries hierboven. (Niet op productie draaien.)


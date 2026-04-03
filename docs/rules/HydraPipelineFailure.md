# HydraPipelineFailure

## Symptom

Grafana Alerting fires `HydraPipelineFailure` — Hydra pipeline pods are logging ERROR-level
messages containing "pipeline" failures.

Alert arrives in the `team-platform-slack` Slack channel.

## Possible Causes

1. **Upstream data source unavailable** — the pipeline source (API, database, message queue)
   is down or returning errors.
2. **Configuration error** — a recent config change introduced invalid pipeline parameters
   (wrong endpoint, missing credentials, schema mismatch).
3. **Resource exhaustion** — the pipeline pod is running out of memory or CPU, causing
   processing failures.
4. **Network issue** — the pod cannot reach a downstream service due to DNS, NetworkPolicy,
   or ingress/egress rules.

## Resolution Steps

1. **Check the logs** — open Grafana Explore, select Loki datasource, query:
   ```logql
   {namespace=~"hydra.*"} |= "ERROR" |= "pipeline"
   ```
2. **Identify the failing pod** — narrow down with pod label:
   ```logql
   {namespace="<namespace>", pod="<pod>"} |= "ERROR"
   ```
3. **Check pod status** — look for restarts, OOMKills, pending state:
   ```bash
   kubectl get pods -n <namespace> -l app=hydra
   kubectl describe pod <pod> -n <namespace>
   ```
4. **Check upstream dependencies** — verify the data source the pipeline reads from is
   healthy.
5. **Check recent changes** — review Git history and ArgoCD sync status for recent
   deployments to the Hydra namespace.

## Escalation

If the root cause is not clear from logs and pod status, escalate to the platform team
with the LogQL query results and pod describe output.

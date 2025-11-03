# CreateContainerConfigError

- Bron: `rules/pods/rules-createconfig.yaml`
- Alert: `CreateContainerConfigError`
- Severity: `warning`
- Labels: `team=platform`

## Wat betekent dit
Een container blijft hangen met reden `CreateContainerConfigError` (vaak door ontbrekende `ConfigMap`, `Secret`, foute env/args/volumes). Als dit 5 minuten aanhoudt, gaat de alert af.

## Trigger (expressie)
- `sum by (namespace,pod,container)(kube_pod_container_status_waiting_reason{reason="CreateContainerConfigError"} == 1) > 0` (for: 5m)

## Actie / runbook
1. Check de pod events en container status:
   ```bash
   kubectl -n <ns> describe pod <pod>
   kubectl -n <ns> get cm,secret | grep -i <naam>
   ```
2. Controleer mounts, envFrom, imagePullSecrets, en referenced namen.
3. Fix de referentie of maak de ontbrekende resource aan, daarna herstart/rollout.

## Verwachte routing
- Default receiver: Slack `#k8s-alerts` via Alertmanager.

## Test
- Maak een pod/deployment met een niet-bestaande `ConfigMap` referentie:
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: cfgerr-test
    namespace: monitoring
  spec:
    containers:
    - name: c
      image: busybox
      command: ["sh","-c","sleep 3600"]
      volumeMounts:
      - name: missing
        mountPath: /cfg
    volumes:
    - name: missing
      configMap:
        name: does-not-exist
  ```
  Wacht >5m en controleer de alert, verwijder daarna de testpod:
  ```bash
  kubectl -n monitoring delete pod cfgerr-test
  ```


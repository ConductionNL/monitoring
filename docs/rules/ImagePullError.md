# ImagePullError

- Bron: `prometheus/rules/images/rules-imagepull.yaml`
- Alert: `ImagePullError`
- Severity: `warning`

## Betekenis
Image kan niet worden opgehaald (ErrImagePull/ImagePullBackOff) >10m.

## Trigger
- `sum by (namespace,pod,container) (kube_pod_container_status_waiting_reason{reason=~"ErrImagePull|ImagePullBackOff"} == 1) > 0` (for: 10m)

## Runbook
1. Check image naam/tag en registry toegang.
2. Controleer imagePullSecrets en netwerk.

## Verwachte routing
- Slack default receiver.

## Test (non-prod)
- Gebruik een niet-bestaande image-tag in een testpod en wacht 10m.


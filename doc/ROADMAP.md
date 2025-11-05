# Roadmap / TODO

- Expose Alertmanager externally (secure):
  - Ingress + TLS; set `alertmanager.alertmanagerSpec.externalUrl`.
  - AuthN/AuthZ in front (oauth2-proxy/OIDC) + IP allowlist.
  - Rate limits, HSTS; NetworkPolicy to restrict access.
- CI-friendly cluster access:
  - Create dedicated ServiceAccount + minimal RBAC (namespaces: `monitoring`, `argocd`).
  - Issue stable kubeconfig/secret for GitHub Actions; rotate via CI-only credentials.
- Tighten alert noise:
  - Daily (24h) repeats for certificate alerts; review other noisy rules.
  - Namespace exclusions for test (e.g., `monitoring`) where sensible.
- Argo Events hardening:
  - Image pinning/digest, PodSecurity; failure backoff and dedupe.
  - Slack/Sentry on failed autofix jobs.
- Runbook coverage:
  - Expand runbooks in `doc/rules/` (CPUThrottlingHigh, NodeDiskIOSaturation, …).

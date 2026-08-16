# Roadmap

v1 (current) delivers the full commit-to-prod path with security gates,
approvals, smoke tests, and rollback. Planned increments, roughly in order of
value:

## Security depth

- [ ] **DAST** — OWASP ZAP baseline scan against the dev deployment as a
      post-deploy gate (the platform currently stops at SAST + image scan).
- [ ] **SBOM + attestations** — Syft SBOM per image, attached to the digest;
      Cosign keyless signing so AKS admission can verify provenance.
- [ ] **Gatekeeper/Azure Policy for AKS** — constraint templates enforcing
      digest-only images from our registries, PSS-restricted, resource limits.
- [ ] **Key Vault private endpoints + `default_action = Deny`** — removes the
      documented CKV_AZURE_189 suppression.
- [ ] **Microsoft Defender for DevOps** — surface repo/pipeline findings in
      Defender for Cloud alongside runtime alerts.

## Delivery capabilities

- [ ] **PR preview environments** — namespace-per-PR deploys on the dev
      cluster (chart already supports it via release-name parameterization),
      torn down on PR close.
- [ ] **Progressive delivery** — canary or blue/green on prod via Argo
      Rollouts or Flagger, replacing the plain rolling update.
- [ ] **Scheduled drift detection** — nightly `terraform plan` run that files
      a work item when live infrastructure diverges from state.
- [ ] **Automated dependency updates** — Renovate for pip pins, base-image
      digest, scanner versions, and Terraform providers, flowing through the
      same PR gates.

## Operations

- [ ] **Observability integration** — wire the AKS clusters into the sibling
      azure-monitoring-platform stack (Container Insights, alert tiers,
      dashboards); re-evaluate the CKV_AZURE_4 suppression then.
- [ ] **Deployment metrics** — DORA-style tracking (lead time, deploy
      frequency, MTTR, change-failure rate) from pipeline + environment data.
- [ ] **Load smoke** — a short k6 burst after staging deploys to catch
      latency regressions before the prod approval is requested.

## Deliberately out of scope

- GitFlow / release branches — see
  [docs/branching-strategy.md](docs/branching-strategy.md).
- Multi-region active/active — the prod ACR is already Premium
  (geo-replication capable); pursue only with a real availability target.
- Docker Content Trust — digest pinning + (planned) Cosign covers integrity
  with a simpler trust model.

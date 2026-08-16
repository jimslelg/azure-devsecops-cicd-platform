# Runbook: Rollback

**When to use:** a deployed revision of orders-api is unhealthy or wrong in
any environment. **Goal:** restore the previous known-good revision first,
diagnose second.

## Layer 0 — did the platform already handle it?

Check the pipeline run before acting:

- `helm upgrade --atomic` reverts automatically if the rollout never became
  healthy — the deploy step fails but the environment is already back on the
  previous revision.
- If smoke tests failed, the stage's `RollbackOnFailure` job has already run
  `helm rollback --wait` and verified rollout status.

In both cases the environment should be healthy; confirm (Layer 1, step 3)
and move to diagnosis.

## Layer 1 — manual Helm rollback (minutes)

1. Get credentials (any identity with `Azure Kubernetes Service RBAC Cluster
   Admin` on the cluster):

   ```bash
   az aks get-credentials --resource-group rg-devsecops-<env> --name aks-devsecops-<env>
   kubelogin convert-kubeconfig -l azurecli
   ```

2. Inspect release history — revisions map 1:1 to pipeline runs:

   ```bash
   helm -n orders history orders-api
   ```

3. Roll back (previous revision, or pass an explicit number):

   ```bash
   helm -n orders rollback orders-api --wait --timeout 5m
   kubectl -n orders rollout status deployment/orders-api
   curl -sf http://<service>/healthz && curl -sf http://<service>/version
   ```

   `/version` must now report the **old** git SHA — that is the proof the
   rollback took.

Alternatively, run the standalone rollback via the pipeline (auditable, no
local kubectl): re-run the failed stage's `RollbackOnFailure` job, or invoke
the `templates/deploy/helm-rollback.yml` template from a manual run.

## Layer 2 — the rollback didn't fix it

Likely a data/schema/config problem rather than a bad image:

1. Do **not** keep rolling back further blindly.
2. Check whether an infrastructure change coincided
   (`git log -- terraform/`, infra pipeline history).
3. Fix forward on `hotfix/<slug>` through the normal PR + full pipeline —
   gates are never skipped, approvals can be expedited instead.

## Infrastructure rollback

Terraform changes roll back through git, never the portal:

```bash
git revert <bad-commit>
git push origin main   # via PR — infra pipeline plans/approves/applies the revert
```

If the portal had to be touched during an incident, back-port the change to
Terraform the same day; the next plan run will otherwise flag drift.

## After any rollback

- Announce in the release channel: what rolled back, from/to revision, why.
- Open an issue linking the failed run; the bad image digest stays in ACR
  for forensics (it can never deploy — the gate is in the pipeline).
- Add a regression test or smoke-test assertion that would have caught it.

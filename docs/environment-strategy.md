# Environment Strategy

Three long-lived environments — `dev`, `staging`, `prod` — modeled as
**Azure DevOps Environment resources**, each mapped to its own Azure resource
group, Terraform state file, and variable group. Promotion always flows
dev → staging → prod within a single pipeline run; there is no way to deploy
to prod except by promoting the exact artifact that passed staging.

## Environment matrix

| Dimension | dev | staging | prod |
|---|---|---|---|
| Purpose | continuous integration target | production rehearsal | live traffic |
| Resource group | `rg-devsecops-dev` | `rg-devsecops-staging` | `rg-devsecops-prod` |
| Terraform state key | `dev.terraform.tfstate` | `staging.terraform.tfstate` | `prod.terraform.tfstate` |
| Variable group | `vg-devsecops-dev` | `vg-devsecops-staging` | `vg-devsecops-prod` |
| ADO Environment | `devsecops-dev` | `devsecops-staging` | `devsecops-prod` |
| AKS sizing | 1 × `Standard_B2s` | 2 × `Standard_D2s_v5` | 3 × `Standard_D4s_v5`, 3 zones |
| ACR SKU | Basic | Standard | Premium (geo-replication ready) |
| Deploy approval | none (automatic) | 1 approver | 2 approvers, separate group |
| Terraform apply approval | 1 approver | 1 approver | 2 approvers |
| Data | synthetic | anonymized | real |

## Azure DevOps Environments and checks

Each ADO Environment carries its gates as **resource checks**, configured in
the portal (Pipelines → Environments → … → Approvals and checks):

- **devsecops-dev** — no approval; exclusive lock (one deploy at a time).
- **devsecops-staging** — approval (platform team, any 1); exclusive lock.
- **devsecops-prod** — approval (release managers, 2 required, requester
  cannot approve their own run); business-hours check (deploys 09:00–16:00
  local, override documented in the runbook); exclusive lock.

Keeping checks on the environment resource (not in YAML) means:

- Policy changes are audited portal events, independent of code review.
- Every pipeline that targets the environment inherits the gates — a new
  pipeline cannot accidentally bypass prod approval.

## Variable groups

One variable group per environment plus one shared group. Secret values are
**not stored in Azure DevOps** — each environment group is linked to that
environment's Key Vault, so rotation happens in the vault and pipelines pick
it up automatically. See [variable-groups.md](variable-groups.md) for the
full inventory.

| Group | Backed by | Holds |
|---|---|---|
| `vg-devsecops-shared` | ADO (non-secret) | ACR name, service connection names, scanner thresholds |
| `vg-devsecops-<env>` | Key Vault `kv-devsecops-<env>` | per-env endpoints, app secrets, SonarQube token |

## Isolation rules

1. **State isolation** — one Terraform state per environment in a shared
   storage account container; the pipeline selects the key via
   `-backend-config`. No cross-environment data sources.
2. **Identity isolation** — each environment has its own user-assigned
   managed identity and federated credential; the dev identity has no RBAC
   on staging or prod resource groups.
3. **Blast-radius isolation** — a bad `terraform apply` in dev cannot touch
   prod: separate resource groups, separate identities, separate state.
4. **Config parity** — the same Terraform modules and the same Helm chart
   deploy every environment; only `tfvars` / `values-<env>.yaml` differ.
   Anything that only exists in prod is a documented exception.

## Ephemeral environments (future)

PR-scoped preview environments (namespace-per-PR on the dev cluster) are on
the [roadmap](../ROADMAP.md) — the Helm chart is already parameterized by
release name to support this.

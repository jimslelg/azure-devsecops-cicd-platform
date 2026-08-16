# Variable Groups

Four groups: one shared (plain ADO variables, nothing secret) and one per
environment (linked to that environment's Key Vault, so secrets are stored
and rotated in the vault — never in Azure DevOps).

## `vg-devsecops-shared` (ADO-stored, non-secret)

| Variable | Example value | Used by |
|---|---|---|
| `imageRepository` | `orders-api` | Package + deploy stages |
| `acrLoginServerDev` | `acrdevsecopsdev.azurecr.io` | Package, Deploy_dev, staging import source |
| `acrLoginServerStaging` | `acrdevsecopsstaging.azurecr.io` | Deploy_staging, prod import source |
| `acrLoginServerProd` | `acrdevsecopsprod.azurecr.io` | Deploy_prod |
| `sonarServiceConnection` | `sonarqube-connection` | Build stage, PR validation |

Values come from `terraform output acr_login_server` per environment.

## `vg-devsecops-<env>` (Key Vault–linked: `kv-devsecops-<env>-****`)

| Variable | Kind | Notes |
|---|---|---|
| `azureServiceConnection` | plain | Name of that env's OIDC service connection (e.g. `devsecops-dev-connection`) |
| `aksResourceGroup` | plain | `rg-devsecops-<env>` |
| `aksClusterName` | plain | `aks-devsecops-<env>` |
| `workloadIdentityClientId` | plain | `terraform output workload_identity_client_id` |
| `sonarToken` | **secret** (vault) | SonarQube analysis token; rotated in the vault |
| `githubPat` | **secret** (vault, prod only) | Fine-grained PAT, contents:write only, used solely to push release tags |

Plain per-env values could live in ADO directly; they are kept alongside the
secrets so each environment has exactly one group to reason about.

## Creation (one-time, CLI)

```bash
az pipelines variable-group create \
  --name vg-devsecops-shared \
  --variables imageRepository=orders-api \
              acrLoginServerDev=acrdevsecopsdev.azurecr.io \
              acrLoginServerStaging=acrdevsecopsstaging.azurecr.io \
              acrLoginServerProd=acrdevsecopsprod.azurecr.io \
              sonarServiceConnection=sonarqube-connection

# Per environment: create the group in the UI and link it to the Key Vault
# (Library → + Variable group → "Link secrets from an Azure key vault"),
# using that env's OIDC service connection. Vault-linked groups cannot be
# fully created via CLI today.
```

## Required RBAC beyond Terraform's defaults

Terraform grants each environment's pipeline identity `AcrPush` on its own
registry and `Key Vault Secrets User` on its own vault. Two cross-environment
grants are needed for digest-preserving promotion (`az acr import`):

| Identity | Extra role | Scope | Why |
|---|---|---|---|
| `id-devsecops-staging-pipeline` | `AcrPull` | dev ACR | import dev → staging |
| `id-devsecops-prod-pipeline` | `AcrPull` | staging ACR | import staging → prod |

These are deliberate one-way, pull-only grants: promotion flows forward, and
no environment can push backward into another's registry.

## Security rules

1. **No secret ever lives in ADO variables or YAML** — vault-linked only.
2. Groups are authorized per-pipeline, not "open to all pipelines".
3. Secret rotation happens in Key Vault; pipelines pick up the new value on
   the next run with zero pipeline changes.
4. `githubPat` exists only in the prod vault and is scoped to pushing tags on
   this one repository.

# Setup Guide

Everything outside this repo that must exist for the pipelines to run.
One-time, in order. Names below match what the YAML and Terraform expect.

## 1. Bootstrap Terraform state (once, manually)

The state backend is the only resource not managed by this repo's Terraform
(chicken-and-egg):

```bash
az group create --name rg-devsecops-tfstate --location canadacentral
az storage account create --name stdevsecopstfstate \
  --resource-group rg-devsecops-tfstate --sku Standard_LRS \
  --allow-blob-public-access false --min-tls-version TLS1_2
az storage container create --name tfstate --account-name stdevsecopstfstate \
  --auth-mode login
```

## 2. Bootstrap identities (first apply only)

The pipeline identities are created *by* Terraform, so the very first
`terraform apply` per environment runs with your own (human) credentials:

```bash
cd terraform
terraform init -backend-config=environments/dev/backend.hcl
terraform apply -var-file=environments/dev/dev.tfvars
```

Grant each created `id-devsecops-<env>-pipeline` identity:

- `Contributor` + `User Access Administrator` on `rg-devsecops-<env>`
- `Storage Blob Data Contributor` on the state storage account
- `AcrPull` on the previous environment's ACR (staging→dev, prod→staging;
  see [variable-groups.md](variable-groups.md))

## 3. Azure DevOps project wiring

1. **GitHub service connection** — connect the ADO project to
   `jimslelg/azure-devsecops-cicd-platform`.
2. **Azure service connections** (×3): Project settings → Service connections
   → Azure Resource Manager → **Workload identity federation (manual)**.
   Name them `devsecops-<env>-connection`, point each at the matching
   `id-devsecops-<env>-pipeline` client ID, and register the issuer/subject
   ADO displays as that identity's federated credential (Terraform pre-creates
   the expected subject; adjust if your org/project names differ).
3. **SonarQube service connection** named `sonarqube-connection`
   (requires the SonarQube extension from the marketplace).
4. **Environments**: create `devsecops-dev`, `devsecops-staging`,
   `devsecops-prod` and add checks per
   [environment-strategy.md](environment-strategy.md): approvals (0/1/2),
   exclusive lock on all three, business hours on prod.
5. **Variable groups** per [variable-groups.md](variable-groups.md), linking
   each env group to its Key Vault. Authorize each group for the two
   pipelines that use it.
6. **Pipelines** (×3): New pipeline → GitHub → this repo → existing YAML:
   `pipelines/pr-validation-pipeline.yml`,
   `pipelines/infrastructure-pipeline.yml`,
   `pipelines/application-pipeline.yml`.

## 4. SonarQube

- Project key `azure-devsecops-cicd-platform` (matches
  `sonar-project.properties`).
- Quality gate "devsecops": coverage ≥ 80%, 0 new blocker/critical issues,
  security hotspots 100% reviewed. Set as the project's gate.
- Analysis token stored as `sonarToken` in each env Key Vault.

## 5. GitHub branch protection

On `main`: require PR with 1 approval, require the PR validation check,
require linear history, forbid force pushes — full list in
[branching-strategy.md](branching-strategy.md).

## 6. First run

1. Run the infrastructure pipeline; approve dev → staging → prod applies.
2. Run the application pipeline; it deploys dev automatically, then waits on
   the staging approval.
3. Verify: `curl http://<service>/version` reports the commit you just built.

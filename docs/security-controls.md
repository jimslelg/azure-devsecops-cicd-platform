# Security Controls Matrix

Every control, where it runs, what it blocks, and how to suppress a finding
legitimately. "Blocking" means the pipeline fails and nothing downstream runs.

| # | Control | Tool (pinned) | Runs in | Blocks on | Suppression path |
|---|---|---|---|---|---|
| 1 | Secret scanning | Gitleaks 8.18.4 | PR validation (full history) | any finding | `.gitleaks.toml` allowlist + owner/reason comment |
| 2 | Unit tests + coverage | pytest 8.2.2 | PR validation, app Build | failure or coverage < 90% | none — fix the tests |
| 3 | SAST + quality gate | SonarQube (server gate) | PR validation, app Build | gate fail: new blockers/criticals, coverage < 80% | resolve in Sonar UI with justification |
| 4 | IaC scanning | Checkov 3.2.140 | PR validation, infra Validate | any unsuppressed failure | `.checkov.yaml` skip-check + owner/reason comment |
| 5 | Dependency/misconfig scan | Trivy 0.53.0 (fs) | PR validation | HIGH/CRITICAL | `.trivyignore` + CVE, owner, reason, expiry |
| 6 | Container image scan | Trivy 0.53.0 (image, by digest) | app Package | HIGH/CRITICAL (fixed) | `.trivyignore` + CVE, owner, reason, expiry |
| 7 | Terraform plan review | human + plan artifact | infra Apply gate | approver rejection | n/a |
| 8 | Deployment approval | ADO Environment checks | every deploy/apply stage | missing approval | portal-audited policy change |
| 9 | Smoke tests + revision assert | in-cluster curl | after every deploy | endpoint failure or wrong `/version` | none |
| 10 | Automatic rollback | Helm `--atomic` + rollback job | on any deploy failure | n/a (recovery control) | n/a |

## Supply-chain posture

- **Base image pinned by digest** in `app/Dockerfile` — rebuilds are
  reproducible and un-poisonable by tag mutation.
- **App dependencies pinned exactly** (`requirements.txt`), installed from
  wheels built in the same Dockerfile — no network installs in the runtime
  stage.
- **One digest from scan to prod**: push → scan → deploy all reference
  `repo@sha256:…`; `az acr import` preserves it across registries.
- **Scanner binaries fetched from pinned release URLs**; versions upgrade
  only via reviewed PRs.

## Identity posture

- Pipelines authenticate with **workload identity federation** — no client
  secrets, no PATs (except the tag-push PAT, prod vault, contents:write only).
- ACR **admin user disabled**; push/pull via role assignments only.
- AKS **local accounts disabled**; kubeconfig access flows through Entra +
  Azure RBAC; pods reach Key Vault via workload identity, not mounted secrets.
- Cross-environment RBAC is one-way and pull-only (see
  [variable-groups.md](variable-groups.md)).

## Suppression policy

A suppression is a **risk acceptance**, so every entry must record: what
(rule/CVE), who owns it, why it is acceptable, and when it expires (if
temporary). Reviewers reject unjustified entries; expired entries are
treated as findings. The three suppression files ship nearly empty on
purpose — an empty suppression file is the healthy state.

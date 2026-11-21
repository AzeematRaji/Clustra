# .github/workflows

GitHub Actions workflows for building the application images and for Terraform. Nothing is defined yet; this file records what belongs here so the boundaries are settled before the first workflow is written.

## Planned workflows

| Workflow | File (proposed) | Trigger | Purpose |
|---|---|---|---|
| Mirror images | `app-mirror-images.yml` | manual dispatch | Mirror the pinned upstream AKS Store Demo images into the shared ACR with commit-SHA tags. No building from source. |
| Terraform PR checks | `terraform-pr.yml` | pull request | `fmt -check` and `validate` for every changed root, then a plan for each changed production root, posted as a PR comment. A change under `terraform/modules/` checks every root. Staging is checked but never planned. |
| Terraform apply/destroy | `terraform-apply.yml` | manual dispatch | Plan one root (apply or destroy, optionally limited to space-separated targets such as `module.documentdb`), publish the plan to the run summary, then apply that exact plan after approval on the `production` environment. Only the five deployed roots are selectable. |
| Observability deploy | `observability-deploy.yml` | push to `main` touching `docker/`, manual dispatch | Sync `docker/` configuration to the observability VM and run Docker Compose. |

## Setup these workflows need

Nothing runs against Azure until all of this exists. Until then, PR checks run fmt and validate only, and the apply workflow stops at its precondition step.

| Item | Kind | Value | From |
|---|---|---|---|
| `terraform/.terraform-version` | File | Pinned Terraform version | #5 |
| `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` | Repo variables | The CI identity used for OIDC | #11 |
| `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `TF_STATE_CONTAINER` | Repo variables | The state backend | #6 |
| `TF_PLAN_PASSPHRASE` | Repo secret | Random string used to encrypt the saved plan artifact | Anyone with repo admin |
| `production` | Environment | Required reviewers: both of us. Deployment branch: `main` only | Repo admin |

The CI identity needs a federated credential for each subject the workflows use:

- `repo:AzeematRaji/Clustra:pull_request` for PR plans.
- `repo:AzeematRaji/Clustra:ref:refs/heads/main` for the plan job of the apply workflow.
- `repo:AzeematRaji/Clustra:environment:production` for the apply job.

## Rules

- One workflow invocation targets one Terraform root. The seven roots have independent state and must not be applied together.
- Apply is manual, runs only from `main`, takes the root name as an input, and applies the exact plan shown in the run summary. The plan file is encrypted before it is stored as an artifact, because it can contain sensitive values and artifacts on a public repo are readable by others.
- Azure authentication uses OpenID Connect workload identity federation. No client secrets or storage account keys are stored in the repository.
- Real `.tfvars` values and state credentials come from GitHub environment secrets or Azure, never from committed files.
- Module targets are for tearing down and recreating one component on purpose (cost control, drills). They are not a substitute for scoped roots, and every targeted run needs a reviewed plan.
- The observability deploy workflow only ships `docker/` configuration to the VM. It never changes Terraform-managed infrastructure.
- Image tags must be immutable (commit SHA). Do not rely on a moving `latest` tag for deployment.

## Not here

- Application runtime configuration and secrets. Those come from Key Vault through workload identity.
- Manual `terraform apply` from a workstation against production. Local applies are acceptable for staging and for the bootstrap step only.

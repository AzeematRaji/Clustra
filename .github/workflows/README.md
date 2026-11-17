# .github/workflows

GitHub Actions workflows for building the application images and for Terraform. Nothing is defined yet; this file records what belongs here so the boundaries are settled before the first workflow is written.

## Planned workflows

| Workflow | File (proposed) | Trigger | Purpose |
|---|---|---|---|
| Mirror images | `app-mirror-images.yml` | manual dispatch | Mirror the pinned upstream AKS Store Demo images into the shared ACR with commit-SHA tags. No building from source. |
| Terraform checks | `terraform-checks.yml` | pull request | `terraform fmt -check` and `terraform validate` for every changed root under `terraform/infrastructure/`. |
| Terraform plan | `terraform-plan.yml` | pull request | Produce a plan per affected root and publish it for review. |
| Terraform apply/destroy | `terraform-apply.yml` | manual dispatch | Apply a reviewed plan, or destroy, for one named root, with an optional module target (for example, tear down only the DocumentDB pair). |
| Observability deploy | `observability-deploy.yml` | push to `main` touching `docker/`, manual dispatch | Sync `docker/` configuration to the observability VM and run Docker Compose. |

## Rules

- One workflow invocation targets one Terraform root. The seven roots have independent state and must not be applied together.
- Apply is manual, takes the root name as an input, and uses the plan produced from the same commit that was reviewed.
- Azure authentication uses OpenID Connect workload identity federation. No client secrets or storage account keys are stored in the repository.
- Real `.tfvars` values and state credentials come from GitHub environment secrets or Azure, never from committed files.
- Module targets are for tearing down and recreating one component on purpose (cost control, drills). They are not a substitute for scoped roots, and every targeted run needs a reviewed plan.
- The observability deploy workflow only ships `docker/` configuration to the VM. It never changes Terraform-managed infrastructure.
- Image tags must be immutable (commit SHA). Do not rely on a moving `latest` tag for deployment.

## Not here

- Application runtime configuration and secrets. Those come from Key Vault through workload identity.
- Manual `terraform apply` from a workstation against production. Local applies are acceptable for staging and for the bootstrap step only.

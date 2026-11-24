# Terraform and provider version constraints

- **Status:** Accepted
- **Date:** 2026-11-21
- **Related:** AGENTS.md (Terraform conventions), [Naming and tagging](naming-and-tagging.md), [ADR 0001](../decisions/0001-region-selection.md)

## Decision

Every root configuration uses these constraints.

| Component | Constraint | Notes |
|---|---|---|
| Terraform CLI | `~> 1.17.2` | Patch updates within 1.17 only. Move to the next minor deliberately. |
| `hashicorp/azurerm` provider | `~> 5.12` | 5.12 or newer, below 6.0. Newest release reviewed: 5.12.0 (2026-10-29). |

Exact versions are fixed by the `.terraform.lock.hcl` file in each root, which is committed.

Locked versions (fill in after the first `terraform init` in Phase 1):
- Terraform: `___`
- azurerm: `___`

## Why these versions

- **DocumentDB geo-replica.** `azurerm_mongo_cluster` supports `create_mode = "GeoReplica"` and the `preview_features` argument. The `GeoReplicas` preview feature must be enabled when the primary cluster is created, and changing it later forces replacement.
- **Front Door Standard.** The `azurerm_cdn_frontdoor_*` resources are maintained in 5.x.
- **AKS.** 5.10.0 fixed a perpetual diff when `kubernetes_version` is given as `{major}.{minor}`.
- **Why 5.x and not 4.x.** This is a new project with no existing state, so there is no migration cost, and 5.x is the current major version.
- **Why not floating versions.** Provider major upgrades remove and change resources. They happen only through a reviewed pull request (see AGENTS.md).

## Standard block

Put this in `versions.tf` in every root, and use the same constraints in every root.

```hcl
terraform {
  required_version = "~> 1.17.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.12"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}
```

Any other provider a root needs (for example `random`) is pinned the same way and listed in this file.

## AzureRM 5.x behaviour to know

- **No resource providers are registered automatically.** We registered the ones we use during Phase 0. If a plan fails with "resource provider not registered", register that provider by hand (`az provider register --namespace <name>`) and record it here.
- **Deprecated resources and properties from 4.x are removed.** Check that any example or module targets 5.x.

## Lock file

Commit `.terraform.lock.hcl` in every root. Generate hashes for every platform we run on, so local runs and GitHub Actions agree:

```bash
terraform init
terraform providers lock -platform=darwin_arm64 -platform=linux_amd64
```

Make sure `.gitignore` does not exclude the lock file.

## Upgrading

1. Open a branch and change the constraint, or run `terraform init -upgrade` in the root.
2. Run `terraform validate` and review the plan for replacements or deletions.
3. Update the lock file for all platforms and the "Locked versions" section above.
4. Merge by pull request. Never upgrade a major version incidentally.

## Open items


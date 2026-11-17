# terraform/bootstrap

One-time setup for the remote Terraform state backend and for resources that must exist before any Terraform-managed infrastructure.

This is deliberately outside the infrastructure Terraform manages: the backend that stores state cannot depend on the state it stores.

## Expected contents

| Path | Purpose |
|---|---|
| `bootstrap.sh` | Idempotent Azure CLI script creating the state resource group, storage account, container and access controls. |
| `backend.hcl.example` | Example of the shared backend partial configuration: resource group, storage account, container, `use_azuread_auth`. |
| `backend-keys.md` | The mapping from deployment root to backend key. |
| `README.md` | This file: what the bootstrap creates and the manual steps around it. |

## What the bootstrap creates

- A dedicated resource group for state, separate from every environment resource group.
- One storage account with blob versioning and soft delete enabled.
- One container for state blobs.
- RBAC for the humans and pipelines that run Terraform: blob data contributor scoped to the container, not account keys.

## Backend keys — one per root (proposed)

| Root | Key |
|---|---|
| `infrastructure/global/front-door` | `global/front-door.tfstate` |
| `infrastructure/shared/acr` | `shared/acr.tfstate` |
| `infrastructure/shared/observability` | `shared/observability.tfstate` |
| `infrastructure/environments/prod/region-1` | `prod/region-1.tfstate` |
| `infrastructure/environments/prod/region-2` | `prod/region-2.tfstate` |
| `infrastructure/environments/staging/region-1` | `staging/region-1.tfstate` |
| `infrastructure/environments/staging/region-2` | `staging/region-2.tfstate` |

A key must not change after its root has been applied; changing it orphans the existing state.

## Rules

- Authenticate with Azure AD, not storage account access keys.
- State locking is mandatory. Do not run concurrent applies against one key.
- Do not move this bootstrap into the same root as the infrastructure it backs.
- This directory holds no secrets. Any value that would be secret belongs in a secret store, not a committed file.

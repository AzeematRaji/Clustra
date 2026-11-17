# terraform/infrastructure

Independently deployable Terraform root configurations. Every directory here that holds a root has its own backend key and its own state, and is applied on its own.

| Path | Scope | Deployed initially |
|---|---|---|
| `global/front-door/` | Global Front Door profile and routing | Yes |
| `shared/acr/` | Shared container registry | Yes |
| `shared/observability/` | Region 1 observability VM and supporting resources | Yes |
| `environments/prod/region-1/` | Production Region 1: network, AKS, Key Vault, database primary | Yes |
| `environments/prod/region-2/` | Production Region 2: network, AKS, Key Vault, database replica | Yes |
| `environments/staging/region-1/` | Staging regional deployment | No |
| `environments/staging/region-2/` | Temporary staging regional deployment | No |

Seven planned state boundaries. Five are expected to be active initially.

## Rules

- One root, one state. Never manage the same resource from two roots.
- A root may consume another root's outputs. It must never modify another root's resources.
- Each root holds its own `versions.tf`, `providers.tf`, backend configuration, `variables.tf`, `main.tf` and `outputs.tf`.
- Roots do not share `.tfvars` files. Real values are supplied at apply time from a secret store or environment secrets.
- Creation order: state backend first, then shared services, then regional environments, then the global root that points at them.
- A root that exists is not a root that is deployed. Staging in particular stays unapplied until it is needed.

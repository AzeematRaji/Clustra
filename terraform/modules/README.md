# terraform/modules

Reusable Terraform child modules. Modules hold no state of their own; they are called by the roots under `../infrastructure/`.

| Module | Purpose |
|---|---|
| `networking/` | VNet, subnets, NSGs, route tables, private DNS and private endpoints for one region. |
| `aks/` | AKS cluster, node pools, identity, workload identity and cluster add-ons. |
| `key-vault/` | Key Vault, RBAC assignments and secret layout for one environment. |
| `documentdb/` | An Azure DocumentDB cluster, either a primary or a cross-region replica. |
| `container-registry/` | The shared ACR. |
| `front-door/` | Front Door profile, endpoints, routes, origin groups, origins, health probes and WAF. |
| `virtual-machine/` | The observability VM, its NIC, disks, identity and network rules. |
| `observability/` | Observability-specific Azure resources, if they warrant a module at all. |

Each module directory contains its own `README.md` describing purpose, planned inputs, planned outputs and boundaries.

## Rules

- Providers and backends belong to roots, never to modules. A module must not configure either.
- Do not pass secret values through module variables; they would be written to state. Use Key Vault references and managed identities.
- Anything a module creates that a caller would not expect to pay for or operate must be an explicit, documented input.
- Keep interfaces small and conventional. Prefer a clear input over a clever abstraction.
- Mark a module's status honestly in its README. A placeholder is not an implementation.

# infrastructure/environments

One root per environment and region. Each root owns everything regional for that environment: network, cluster, Key Vault, database resources and its telemetry integration.

| Path | Environment | Initial deployment |
|---|---|---|
| `prod/region-1/` | Production, Region 1 | Yes |
| `prod/region-2/` | Production, Region 2 | Yes |
| `staging/region-1/` | Staging, Region 1 | No |
| `staging/region-2/` | Staging, Region 2 — temporary | No |

## Rules

- A regional root must not manage resources owned by a shared root (ACR, observability VM) or the global root (Front Door).
- The DocumentDB primary and its cross-region replica are owned together by `prod/region-1`. The replica is in Region 2's region but Region 1's resource group, and `prod/region-2` owns only the private endpoint into it. This is the one deliberate exception to "a root owns only its own region", because replication topology belongs to the primary.
- Environment and region are baked into the path. Do not add a single `allow_env` switch that builds one environment inside another environment's root.
- Production and staging never share a VNet, Key Vault, cluster or state.
- Address spaces must not overlap anywhere in this tree. Changing one after the fact means rebuilding the network, so validate the plan before the first apply.
- A staging root existing in the repository is not a reason to deploy it. Staging is applied when there is something to learn from it.
- Regional failure, database promotion and failback are operational procedures documented in `docs/runbooks/`, not Terraform state changes performed by these roots.

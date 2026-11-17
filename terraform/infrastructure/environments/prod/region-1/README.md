# prod/region-1

**Root:** deployment root · **State:** own remote backend key (`prod/region-1.tfstate`, proposed) · **Initially deployed:** yes (PLAN Phases 2, 4, 6)

Production Region 1. The primary application region and the region that holds the authoritative database.

## Owns

- VNet, subnets, NSGs and private DNS for Region 1, via `modules/networking`.
- The production AKS cluster, its node pools and workload identity, via `modules/aks`.
- The Region 1 Key Vault and its access model, via `modules/key-vault`.
- The DocumentDB M30 primary cluster, via `modules/documentdb`.
- **The Region 2 cross-region read replica cluster**, also via `modules/documentdb`. Replication topology is a property of the primary, so both clusters belong to this root. The replica lives in Region 2 but in this root's resource group.
- `AcrPull` for this cluster's identity on the shared ACR.
- Private endpoints to both DocumentDB clusters in this region's VNet, and this region's private DNS zone for them.
- This region's telemetry export configuration toward the observability VM.

## Does not own

- The ACR, the observability VM or Front Door.
- Front Door origins. This root outputs the ingress endpoint; the global root consumes it as a variable.
- The Region 2 VNet, cluster, Key Vault or private endpoints. Those belong to `prod/region-2`.
- Promotion and failback. Those are documented operational procedures, not applies in this root.

## Inputs from other roots

| Input | Source |
|---|---|
| `acr_id` / `login_server` | `shared/acr` |
| Observability ingestion endpoint and CA | `shared/observability` |

## Outputs consumed elsewhere

- Regional ingress hostname / origin endpoint, for `global/front-door`.
- Ingress egress CIDRs, for the observability root's allowed sources.
- `documentdb_primary_id` and `documentdb_replica_id`, so `prod/region-2` can create private endpoints in its own VNet.

Connection strings are deliberately **not** outputs: they embed the administrator credentials. Credentials live in Key Vault and reach workloads through the Secrets Store CSI driver.

## Database configuration

| Setting | Value | Reversible |
|---|---|---|
| `compute_tier` | `M30` — the floor for cross-region replication | **No** |
| `preview_features` | `["GeoReplicas"]` on the primary | **No** |
| `create_mode` | `Default` on the primary, `GeoReplica` on the replica | No |
| `high_availability_mode` | `ZoneRedundantPreferred` on the primary; not supported on the replica | Yes |
| `public_network_access` | `Disabled`, reached through private endpoints | Yes |
| `authentication_methods` | `NativeAuth` — the application uses username and password | No |
| `storage_size_in_gb` / `shard_count` | Must match on both clusters | No downward |

## Notes

- Address space must not overlap Region 2 or staging. Validate before the first apply; changing a VNet range means rebuilding it.
- If the observability VM joins this VNet, this root is applied before `shared/observability`.
- The database pair is the single authoritative writer for the whole platform. Anything that could promote, delete or re-seed it needs explicit human approval and a recovery plan.
- M10–M25 are not an option: they do not support replication, and a cluster cannot be scaled back down to them once at M30.
- Do not create Front Door resources here.

## Status

Placeholder. No Terraform written yet.

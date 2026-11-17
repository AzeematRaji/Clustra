# modules/documentdb

Creates one Azure DocumentDB cluster — either a primary or a cross-region replica.

Wraps `azurerm_mongo_cluster`. Two consumers (primary and replica) justify the module.

## Planned inputs

| Input | Purpose |
|---|---|
| `name`, `resource_group_name`, `location` | Placement. The replica is created in the primary's resource group, in the replica region. |
| `compute_tier` | `M30` minimum. Burstable tiers cannot replicate. |
| `create_mode` | `Default` for the primary, `GeoReplica` for the replica. |
| `source_server_id` / `source_location` | Set for the replica only. |
| `preview_features` | `["GeoReplicas"]` on the primary. Must be set at creation. |
| `high_availability_mode` | `ZoneRedundantPreferred` or `Disabled`. Not supported on replicas. |
| `administrator_username`, `administrator_password` | Primary only. The replica inherits them. |
| `authentication_methods` | `NativeAuth`, because the application uses username and password. |
| `storage_size_in_gb`, `shard_count`, `storage_type` | Must match across primary and replica. |
| `public_network_access` | Default to `Disabled`; reach the cluster through private endpoints. |
| `tags` | Common tags. |

## Planned outputs

- `id` — used by the caller to create private endpoints, and by the Region 2 root for its own.
- `name`, `location`
- `replication_role` — whether this cluster is the primary or the replica, for assertions.

**No connection string outputs.** The provider's `connection_strings` attribute substitutes the real administrator username and password, so exporting it exports a credential. Credentials belong in Key Vault.

## Constraints

- `compute_tier` cannot be lowered below M30 once raised. Treat the tier as a one-way decision, not a tunable.
- `create_mode`, `preview_features`, `source_server_id`, `storage_size_in_gb` and `shard_count` force resource replacement when changed.
- The replica cannot have in-region HA or point-in-time restore.
- Storage can be increased but never decreased.
- Promotion changes roles outside Terraform. Expect drift after a drill; review plans rather than applying them.

## Boundaries

- Does not create private endpoints, private DNS zones or VNet links. Those belong to the networking module in the region that owns the VNet.
- Does not create databases, collections or indexes.
- Does not write credentials to Key Vault. Secret population is a separate, explicit step.
- Does not promote, fail over or fail back. Those are operational procedures.

## Status

Placeholder. Not implemented.

# modules/container-registry

Creates the single shared Azure Container Registry.

## Planned resources

- ACR at the Basic or Standard tier, in a dedicated shared-services resource group.
- Retention policy for untagged manifests.
- Network access rules, once the decision on public versus private access is made.

## Planned inputs

| Input | Purpose |
|---|---|
| `location` | Home region of the registry. |
| `resource_group_name`, `name` | Placement and globally unique registry name. |
| `sku` | Basic or Standard. |
| `tags` | Common tags. |

## Planned outputs

- `acr_id`
- `login_server`
- `resource_group_name`

## Boundaries

- Does not enable geo-replication. A second replica is a cost and availability decision that must be revisited explicitly, not switched on to remove a warning.
- Grants no pull permission by default. `AcrPull` for each cluster identity is assigned in the regional root that owns that identity, so the grant cannot outlive or outscope the identity.
- Does not build, tag or push images. That is the CI workflow in `.github/workflows/`.
- Cross-region pulls affect pod start and scale-out time, not request latency for already-running pods. Measure and record the Region 2 pull behaviour rather than assuming it.

## Status

Placeholder. Not implemented.

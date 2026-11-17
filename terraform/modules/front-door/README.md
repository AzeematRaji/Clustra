# modules/front-door

Creates the global Azure Front Door profile and its routing.

## Planned resources

- Front Door profile and endpoint(s), with custom domains and managed certificates.
- One production origin group. Optionally one staging origin group.
- Origins pointing at each region's ingress endpoint, with explicit priority, weight and health-probe settings.
- Routes with agreed host header, protocol, forwarding and caching behaviour.
- Health probes that reflect application readiness, not just ingress-controller liveness.
- WAF policy and origin access protection.

## Planned inputs

| Input | Purpose |
|---|---|
| `resource_group_name` | Owning resource group. |
| `sku` | `Standard_AzureFrontDoor` (agreed). Premium only if Private Link origins or managed WAF rules become a reviewed requirement. |
| `origins` | Per-region hostname, priority, weight, health-probe path and headers. |
| `enable_staging_route` | Narrowly scoped optional staging route. Defaults to `false`. |
| `tags` | Common tags. |

## Planned outputs

- `profile_id`
- `endpoint_hostnames`
- `origin_group_ids`

## Boundaries

- Routes to regional ingress endpoints, never directly to pods.
- Staging must never be added to the production origin group.
- The staging flag must not be able to recreate or reconfigure production resources. If a change would do so, the design is wrong.
- Do not assume a 50/50 traffic split. Weights, priorities and health probes are explicit configuration, and the observed behaviour is validated and recorded.
- Does not manage the regional ingress controller or the regional TLS on the origin side.

## Status

Placeholder. Not implemented.

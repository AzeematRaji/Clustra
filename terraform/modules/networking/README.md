# modules/networking

Creates the network foundation for one region.

## Planned resources

- Virtual network with a caller-supplied, non-overlapping address space.
- Subnets: AKS node pools, ingress (if the load balancer needs a dedicated subnet), private endpoints.
- Network security groups and rules covering only the required paths.
- Route table where egress behaviour must be explicit.
- Private DNS zones and virtual network links for private endpoints.

## Planned inputs

| Input | Purpose |
|---|---|
| `location` | Region for all resources. |
| `resource_group_name` | Owning resource group. |
| `vnet_address_space` | Must not overlap any other region. |
| `subnet_prefixes` | Map of subnet name to CIDR. |
| `tags` | Common tags. |

## Planned outputs

- `vnet_id`
- `subnet_ids` — map keyed by subnet name
- `private_dns_zone_ids`

## Boundaries

- Does not peer VNets. Peering or another connectivity mechanism is a separate, deliberately reviewed decision.
- Does not create firewalls, VPN or ExpressRoute gateways.
- Does not assume cross-region reachability. The absence of a path is the default, and any required path is documented in `docs/networking/`.
- VNet address space is effectively immutable: changing it means rebuilding the network. Validate the ranges before the first apply, and record the plan.
- The default NSG posture is deny inbound. Every opened port is justified by a documented path.

## Status

Placeholder. Not implemented — created as part of the repository layout in Phase 1.

# shared/acr

**Root:** deployment root · **State:** own remote backend key (`shared/acr.tfstate`, proposed) · **Initially deployed:** yes (PLAN Phase 3)

The single shared Azure Container Registry that both production clusters pull from.

## Owns

- The ACR, its resource group and its SKU.
- Registry-level settings: retention for untagged manifests, network access rules.
- Nothing about clusters or their identities.

## Does not own

- ACR pull role assignments for cluster identities. Each regional root assigns `AcrPull` to the identity it owns.
- Image builds, tags or pushes. Those come from CI.
- Geo-replication. Not enabled initially; adding a replica is a cost and availability decision to revisit explicitly.

## Inputs from other roots

None. This is one of the first roots applied.

## Outputs consumed elsewhere

- `acr_id` and `login_server`, used by each regional root for image pulls.

## Notes

- Cross-region pulls affect pod start and scale-out time, not settled request latency. Measure the Region 2 pull behaviour and record it in `docs/testing/`.
- Keep the SKU cost-appropriate (Basic or Standard) and record the trade-off that comes with it.
- Destroying this root breaks both clusters' ability to start new pods. Treat it as a production-affecting action.

## Status

Placeholder. No Terraform written yet.

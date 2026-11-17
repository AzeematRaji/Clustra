# staging/region-1

**Root:** deployment root · **State:** own remote backend key (`staging/region-1.tfstate`, proposed) · **Initially deployed:** no (PLAN Phase 9, optional; not planned)

Staging environment in Region 1. The same shape as production Region 1, at smaller scale and with staging-specific configuration.

## Owns

- Staging VNet, subnets, NSGs and private DNS, with an address space that does not overlap any production range.
- The staging AKS cluster and node pools, sized down for cost.
- The staging Key Vault.
- A staging DocumentDB cluster at M30, if staging needs a database. M30 is the floor for replication, so a cheaper tier is not available. Create the replica only for drill windows and destroy it afterwards.

## Does not own

- The shared ACR. Staging pulls from the same registry and shares its images.
- The observability VM. Staging may export telemetry there under the same authentication rules, or not at all in the first cut.
- Production Front Door routing. Any staging route is a scoped addition owned by `global/front-door`.

## Inputs from other roots

| Input | Source |
|---|---|
| `acr_id` / `login_server` | `shared/acr` |
| Observability ingestion endpoint, if used | `shared/observability` |

## Notes

- Do not copy the production replica topology unless the exercise needs it. Staging exists to test a specific thing.
- Keep DNS names and address space clearly distinct from production so a mistake fails visibly.
- Applying or destroying this root must not touch production or shared state. Verify that before the first apply.

## Status

Placeholder. No Terraform written yet. Deliberately unapplied.

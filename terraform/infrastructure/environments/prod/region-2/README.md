# prod/region-2

**Root:** deployment root · **State:** own remote backend key (`prod/region-2.tfstate`, proposed) · **Initially deployed:** yes (PLAN Phases 2, 4, 6)

Production Region 2. A second active application region, and the home of the DocumentDB cross-region replica.

## Owns

- VNet, subnets, NSGs and private DNS for Region 2, via `modules/networking`.
- The production AKS cluster, its node pools and workload identity, via `modules/aks`.
- The Region 2 Key Vault and its access model, via `modules/key-vault`.
- Private endpoints to both DocumentDB clusters (the Region 1 primary for writes, and the replica), and this region's private DNS zone for them. The VNets are not peered; these endpoints are how Region 2 reaches the database.
- `AcrPull` for this cluster's identity on the shared ACR.

## Does not own

- **The replica cluster itself.** It is owned by `prod/region-1`, because replication topology is a property of the primary. This root only connects to it privately.
- The Region 1 primary, and any promotion of either cluster. Promotion is a documented, approved operational procedure.
- Front Door origins. This root outputs the endpoint; the global root consumes it.
- Any shared or global resource.

## Inputs from other roots

| Input | Source |
|---|---|
| `acr_id` / `login_server` | `shared/acr` |
| `documentdb_primary_id` / `documentdb_replica_id` | `prod/region-1` |
| Observability ingestion endpoint and CA | `shared/observability` |

## Outputs consumed elsewhere

- Regional ingress hostname / origin endpoint, for `global/front-door`.
- Ingress egress CIDRs, for the observability root's allowed sources.

## Notes

- Region 2 writes travel to the Region 1 primary. Cross-region latency is expected; measure it rather than assuming it.
- Applications must not write to the replica. It is read-only until promoted.
- The replica inherits its administrator credentials from the primary, so no separate password is set here. It does **not** inherit firewall or private-endpoint configuration, which is why this root creates its own private endpoints.
- If the database pair is torn down with a targeted run in `prod/region-1`, destroy this root's DocumentDB private endpoints first and recreate them afterwards.
- Replication lag, promotion, recovery and failback are separate documented concerns in `docs/runbooks/`.
- No automatic failover is assumed until it is explicitly configured and tested. Provisioning a replica does not provide transparent failover.
- This root depends on Region 1's database existing. Apply after it.

## Status

Placeholder. No Terraform written yet.

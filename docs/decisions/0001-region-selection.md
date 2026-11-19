# ADR 0001: Region selection

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

Clustra needs two production regions running AKS, a DocumentDB (MongoDB-compatible)
primary with one cross-region read replica, and Azure Front Door Standard in front.
There is no data-residency or latency requirement; the database holds demo data only.

## Decision

- **Region 1 (primary/writer):** Canada Central
- **Region 2 (replica):** East US 2

## Reasons

1. Both regions have three availability zones, so both AKS clusters can be built the same way.
2. DocumentDB lets the replica live in any chosen region, so the two regions do not
   need to be an Azure region pair.
3. No residency constraint, so there is no reason to keep both regions in Canada.
4. Canada Central is close to the operator; East US 2 is a large region with broad
   service coverage.
5. Replicating across two countries gives more realistic latency and replication-lag
   measurements for Phase 6 and Phase 8.

## Alternatives considered

- **Canada Central + Canada East:** rejected mainly because Canada East has no
  availability zones, which would make the two regions unequal.

## Evidence (checked 2026-11-19)

- AKS versions listed in both regions (1.31.13 to 1.37.1).
- `Standard_D2s_v5` has no restrictions in either region.
- vCPU quota was 4 per region on the trial subscription; raised to 10 per region
  after upgrading to Pay-As-You-Go and requesting an increase.
- DocumentDB M30 offered in both regions; East US 2 offered as replica region.
- Front Door Standard offered (global service).
- The `documentdb` Azure CLI extension exposes `--preview-features` on
  `az documentdb mongocluster create`, which is how the GeoReplicas preview feature
  is enabled at creation.

## Consequences

- The regions are not an Azure region pair, so Azure's paired-region features
  (such as paired staged updates and geo-redundant storage pairing) do not apply.
- Cross-region data transfer is billed; to be included in the budget estimate.
- GeoReplicas is a preview feature; behaviour or availability may change.
- Preview feature names are free-form strings, so the exact value (`GeoReplicas`)
  must be verified when the cluster is created.
- The subscription must stay on Pay-As-You-Go to keep the raised quota.
- Pricing differences between the two regions are not yet verified.

## Follow-ups

- Confirm that Terraform can set the GeoReplicas preview feature at creation
  (or whether the CLI or another provider is needed) before Phase 6.
- Check pricing for both regions and the Front Door Standard base fee.
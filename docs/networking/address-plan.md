# Network address plan

- **Status:** Proposed (confirm the network model when Phase 2 is built)
- **Date:** 2026-11-20
- **Related:** [ADR 0001](../decisions/0001-region-selection.md), PROJECT.md (Regional networking), PLAN.md (Phases 0 and 2)

## Principles

1. All ranges come from the private `10.0.0.0/8` space and **nothing overlaps**: VNets, pod ranges and service ranges are all unique. The VNets are not peered initially, but unique ranges mean peering can be added later without renumbering.
2. Only the two production regions are deployed. Staging ranges are **reserved only**; staging is not deployed.
3. AKS uses **Azure CNI Overlay**: nodes get IPs from the VNet subnet, pods get IPs from a separate pod range.
4. Azure reserves 5 addresses in every subnet. "Usable" below already excludes them.

## VNet address spaces

| Environment | Region | VNet range | Status |
|---|---|---|---|
| Production, region-1 | Canada Central | `10.10.0.0/16` | Deployed in Phase 2 |
| Production, region-2 | East US 2 | `10.20.0.0/16` | Deployed in Phase 2 |
| Staging, region-1 | Canada Central (assumed to mirror prod) | `10.30.0.0/16` | Reserved, not deployed |
| Staging, region-2 | East US 2 (assumed to mirror prod) | `10.40.0.0/16` | Reserved, not deployed |

`10.50.0.0/16` to `10.99.255.255` is kept free for future use.

## Subnets

Same layout in every VNet.

| Subnet | Purpose | Prod region-1 | Prod region-2 | Staging region-1 | Staging region-2 | Usable IPs |
|---|---|---|---|---|---|---|
| `snet-aks` | AKS node pools | `10.10.0.0/24` | `10.20.0.0/24` | `10.30.0.0/24` | `10.40.0.0/24` | 251 |
| `snet-ingress` | Ingress / internal load balancer frontends | `10.10.1.0/26` | `10.20.1.0/26` | `10.30.1.0/26` | `10.40.1.0/26` | 59 |
| `snet-private-endpoints` | Private endpoints (DocumentDB primary and replica, Key Vault) | `10.10.2.0/26` | `10.20.2.0/26` | `10.30.2.0/26` | `10.40.2.0/26` | 59 |
| `snet-observability` | Observability VM (region-1 only; reserved elsewhere) | `10.10.3.0/27` | `10.20.3.0/27` | `10.30.3.0/27` | `10.40.3.0/27` | 27 |
| (reserved) | Future use | `10.10.4.0/22` | `10.20.4.0/22` | `10.30.4.0/22` | `10.40.4.0/22` | 1019 |

Notes:
- `snet-observability` is only created in prod region-1. The prod region-2 range is reserved but unused.
- All staging subnets are reserved only.

## AKS cluster ranges (Azure CNI Overlay)

| Cluster | Node subnet | Pod CIDR | Service CIDR | DNS service IP |
|---|---|---|---|---|
| Prod region-1 | `10.10.0.0/24` | `10.100.0.0/16` | `10.200.0.0/16` | `10.200.0.10` |
| Prod region-2 | `10.20.0.0/24` | `10.101.0.0/16` | `10.201.0.0/16` | `10.201.0.10` |
| Staging region-1 (reserved) | `10.30.0.0/24` | `10.102.0.0/16` | `10.202.0.0/16` | `10.202.0.10` |
| Staging region-2 (reserved) | `10.40.0.0/24` | `10.103.0.0/16` | `10.203.0.0/16` | `10.203.0.10` |

- The pod CIDR must not overlap the node subnet or any connected network. Each node takes a `/24` slice of its cluster's pod CIDR.
- Overlay allows the same pod range to be reused across clusters. We use unique ranges anyway to keep peering possible later.

## Sizing rationale

- **`snet-aks` /24:** far more than the planned node count, leaving room for upgrade surge nodes and growth without renumbering.
- **`snet-private-endpoints` /26:** each private endpoint uses one address; this covers both DocumentDB clusters, Key Vault and future endpoints.
- **`snet-observability` /27:** a single VM today, with room for supporting resources.
- **Reserved /22:** unallocated space in each VNet for future subnets.

## Validation

No overlaps among the 12 top-level ranges (4 VNets, 4 pod CIDRs, 4 service CIDRs), every subnet lies within its VNet, and no two subnets in a VNet overlap.

## Open items

- Confirm Azure CNI Overlay as the AKS network model when Phase 2 and Phase 4 are built. A pod-subnet model would need much larger subnets.

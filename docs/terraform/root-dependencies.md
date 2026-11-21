# Terraform root dependencies

- **Status:** Proposed
- **Date:** 2026-11-21
- **Related:** [Naming and tagging](../conventions/naming-and-tagging.md), [Address plan](../networking/address-plan.md), AGENTS.md (Terraform layout and state boundaries)

What each deployment root hands to the others, how the values are passed, and the order in which roots are applied and destroyed. Staging roots are left out because they are not deployed.

## How values are passed between roots

Roots do not read each other's state. A consuming root takes the **name** of the resource it needs as an input variable, and looks the resource up with a `data` source. Because every name is deterministic under the naming conventions, the inputs are short, readable and contain no subscription IDs.

```hcl
variable "acr_name" {
  description = "Name of the shared container registry, owned by shared/acr."
  type        = string
  default     = "crclustrasharedcac"
}

data "azurerm_container_registry" "shared" {
  name                = var.acr_name
  resource_group_name = "rg-clustra-shared-cac-acr"
}
```

The producing root still declares the value as an `output`, so it is visible after apply and a reviewer can confirm it matches.

Fall back to passing a resource ID as a variable only where no data source exists. Use `terraform_remote_state` only if both options fail, and record why.

## Hand-offs

| Value | Produced by | Consumed by | Phase | How |
|---|---|---|---|---|
| Container registry (`acr_id`, `login_server`) | `shared/acr` | `prod/region-1`, `prod/region-2` (AcrPull role assignment) | 3–4 | Registry name → data source |
| Observability subnet (`snet-observability`) | `prod/region-1` | `shared/observability` (VM network interface) | 2–3 | VNet and subnet name → data source |
| AKS egress public IPs (`pip-clustra-prod-<region>-egress`) | `prod/region-1`, `prod/region-2` | `shared/observability` (NSG allowlist for nginx) | 2–3 | Public IP name → data source |
| Ingress public IPs (`pip-clustra-prod-<region>-ingress`) | `prod/region-1`, `prod/region-2` | `global/front-door` (origin host names) | 5 | Public IP name → data source |
| DocumentDB primary and replica | `prod/region-1` | `prod/region-2` (private endpoints in its VNet) | 6 | Cluster names → data source, or IDs as variables if no data source is available |

### Values that are not Terraform hand-offs

These are consumed by Kubernetes configuration or CI, not by another root, so they create no dependency between roots:

- **Front Door profile ID** (`X-Azure-FDID`). Output by `global/front-door` and set in each region's ingress configuration.
- **Observability ingestion host name and CA.** Output by `shared/observability` and set in the Alloy configuration in each cluster.
- **Registry login server.** Used by image mirroring and Kubernetes manifests.
- **Secrets** (DocumentDB credentials, nginx ingestion credentials). These are never outputs. They are kept in each regional Key Vault and mounted through the Secrets Store CSI driver.

Keeping these out of Terraform inputs avoids cycles. Without that, `prod/region-1` would need the observability endpoint while `shared/observability` needs `prod/region-1`'s subnet, and the regional roots would need the Front Door ID while Front Door needs their ingress IPs.

## Static public IPs owned by the regional roots

The two public IP hand-offs work only if Terraform creates those IPs, rather than AKS creating them on its own:

- **Egress:** the regional root creates `pip-clustra-prod-<region>-egress` and sets it as the cluster's outbound IP.
- **Ingress:** the regional root creates `pip-clustra-prod-<region>-ingress`, and the ingress controller's Service references it by name. The cluster identity needs Network Contributor on the resource group that holds the IP.

Without this, the IPs would only exist after a Kubernetes Service is created, and they would change whenever the Service was recreated.

## Apply order

```text
bootstrap
   │
   ├─► shared/acr
   │
   ├─► prod/region-1 (network, egress and ingress IPs)  ─┐
   ├─► prod/region-2 (network, egress and ingress IPs)  ─┤
   │                                                     ▼
   │                                          shared/observability
   │
   ├─► prod/region-1, prod/region-2 (AKS, Key Vault, AcrPull)   needs shared/acr
   │
   ├─► global/front-door                                   needs both ingress IPs
   │
   └─► prod/region-1 (DocumentDB pair) ─► prod/region-2 (DocumentDB private endpoints)
```

| Step | Root | Requires |
|---|---|---|
| 1 | `terraform/bootstrap` | Nothing (Azure CLI script) |
| 2 | `shared/acr` | Bootstrap |
| 3 | `prod/region-1`, `prod/region-2`: networking and public IPs | Bootstrap |
| 4 | `shared/observability` | Region 1 subnet, both egress IPs |
| 5 | `prod/region-1`, `prod/region-2`: AKS, Key Vault, AcrPull | `shared/acr` |
| 6 | `global/front-door` | Both ingress IPs, and ingress serving the health path |
| 7 | `prod/region-1`: DocumentDB pair | Region 1 private DNS zone |
| 8 | `prod/region-2`: DocumentDB private endpoints | DocumentDB pair |

Steps 3, 5, 7 and 8 are the same regional roots applied again as later phases add resources. They are not separate roots.

## Destroy order

Reverse of the apply order. Two cases matter in practice:

- **DocumentDB teardown for cost** (targeted run): destroy Region 2's DocumentDB private endpoints first, then the pair in `prod/region-1`. Recreate in the opposite order.
- **Full teardown:** `global/front-door` → `shared/observability` → `prod/region-2` → `prod/region-1` → `shared/acr`. Destroying `shared/acr` while clusters are running stops new pods from starting.

## Open items

- Confirm that the pinned AzureRM version (issue #5) has a data source for `azurerm_mongo_cluster`. If it does not, `prod/region-2` takes the two cluster IDs as variables.
- Confirm the ingress controller can attach to a public IP in the regional resource group, as opposed to the AKS node resource group, when the ingress is built in Phase 5.

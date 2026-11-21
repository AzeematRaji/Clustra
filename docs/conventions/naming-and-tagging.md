# Naming, tagging and resource-group conventions

- **Status:** Accepted
- **Date:** 2026-11-20
- **Related:** [Address plan](../networking/address-plan.md), [ADR 0001](../decisions/0001-region-selection.md), AGENTS.md (Terraform conventions)

## 1. Naming pattern

```
<type>-clustra-<env>-<region>[-<purpose>]
```

| Part | Values |
|---|---|
| `type` | Resource abbreviation, see the table below |
| `clustra` | Project name |
| `env` | `prod`, `stg` (staging), `shared` (shared and global services) |
| `region` | `cac` (Canada Central), `eus2` (East US 2), `glb` (global) |
| `purpose` | Optional, only when there is more than one of a type (for example `data`, `acr`, `obs`) |

Rules:
- Lowercase only. Hyphens as separators, except where the service forbids them (container registry, storage account, AKS node pools), in which case drop the hyphens.
- Child resources scoped to a parent (subnets, node pools) use short names without the project, env or region, because the parent already carries them.
- Several services require globally unique names (Key Vault, container registry, storage account). If a name is taken, append a short suffix such as `01` or a few random characters. Record the final name in the root's README.
- Key Vault names stay reserved after deletion until purged, so plan for this during destroy and recreate drills.

### Abbreviations and examples

| Resource | Abbreviation | Example |
|---|---|---|
| Resource group | `rg` | `rg-clustra-prod-cac` |
| Virtual network | `vnet` | `vnet-clustra-prod-cac` |
| Subnet | `snet` | `snet-aks`, `snet-ingress`, `snet-private-endpoints`, `snet-observability` |
| Network security group | `nsg` | `nsg-clustra-prod-cac-aks` |
| AKS cluster | `aks` | `aks-clustra-prod-cac` |
| AKS node pools | `npsystem`, `npuser` | `npsystem`, `npuser` |
| AKS node resource group | `rg` | `rg-clustra-prod-cac-aksnodes` |
| Key Vault | `kv` | `kv-clustra-prod-cac` |
| Private endpoint | `pep` | `pep-clustra-prod-cac-docdb-primary` |
| DocumentDB cluster | `docdb` (our own) | `docdb-clustra-prod-cac` (primary), `docdb-clustra-prod-eus2` (replica) |
| Managed identity | `id` | `id-clustra-prod-cac-aks` |
| Public IP | `pip` | `pip-clustra-prod-cac-egress` |
| Virtual machine | `vm` | `vm-clustra-shared-cac-obs` |
| Container registry | `cr` (no hyphens) | `crclustrasharedcac` |
| Storage account | `st` (no hyphens) | `stclustratfstatecac` |
| Front Door profile | `afd` | `afd-clustra-shared-glb` |

## 2. Tags

Every resource that supports tags gets exactly these five. Azure does not copy resource group tags down to resources, so tag each resource.

| Tag | Value | Notes |
|---|---|---|
| `project` | `clustra` | |
| `environment` | `prod`, `staging` or `shared` | |
| `region` | The Azure region where the resource actually lives, for example `canadacentral`, `eastus2`, or `global` | The DocumentDB replica is owned by the Region 1 root but lives in East US 2, so it gets `eastus2` |
| `managed-by` | `terraform` | Anything created by hand in the portal should say `manual` |
| `owner` | GitHub username `azeematraji` | No email addresses or personal data (this repo is public) |

Terraform notes:
- Define the tags once per root as `local.common_tags`, and pass them to every module through a `tags` variable.
- `managed-by` contains a hyphen, so it must be quoted in a map: `"managed-by" = "terraform"`.
- Override a single value with `merge(local.common_tags, { region = "eastus2" })` where a resource lives elsewhere.

## 3. Resource groups and ownership

Each root creates and owns its resource groups and puts resources only in groups it owns. A root never places resources in another root's group.

| Root | Resource groups it owns | What lives there |
|---|---|---|
| `terraform/bootstrap` | `rg-clustra-tfstate-cac` | Remote state storage account and container |
| `infrastructure/global/front-door` | `rg-clustra-shared-glb-afd` | Front Door profile, endpoints, origin groups, routes (the group needs a location; use Canada Central) |
| `infrastructure/shared/acr` | `rg-clustra-shared-cac-acr` | Container registry |
| `infrastructure/shared/observability` | `rg-clustra-shared-cac-obs` | VM, disk, network interface, NSG, public IP |
| `infrastructure/environments/prod/region-1` | `rg-clustra-prod-cac` | VNet, subnets, AKS, Key Vault, private endpoints, private DNS zones |
| | `rg-clustra-prod-cac-data` | Both DocumentDB clusters (primary in Canada Central, replica in East US 2) |
| | `rg-clustra-prod-cac-aksnodes` | AKS node resources (created by AKS; name set in Terraform) |
| `infrastructure/environments/prod/region-2` | `rg-clustra-prod-eus2` | VNet, subnets, AKS, Key Vault, private endpoints to both DocumentDB clusters, private DNS zones |
| | `rg-clustra-prod-eus2-aksnodes` | AKS node resources |
| `infrastructure/environments/staging/region-1` | `rg-clustra-stg-cac`, `rg-clustra-stg-cac-data` | Reserved, not deployed |
| `infrastructure/environments/staging/region-2` | `rg-clustra-stg-eus2` | Reserved, not deployed |

Notes:
- The Region 2 private endpoints to the Region 1 primary belong to the Region 2 root, in `rg-clustra-prod-eus2`.
- The observability VM's network interface lives in the observability group but attaches to a subnet in the Region 1 VNet, passed in as an input (see the open item in the address plan).

## 4. Terraform state

One storage account and container (`tfstate`), one blob per root, with keys mirroring the root path:

`global/front-door.tfstate`, `shared/acr.tfstate`, `shared/observability.tfstate`, `prod/region-1.tfstate`, `prod/region-2.tfstate`, `staging/region-1.tfstate`, `staging/region-2.tfstate`

## 5. Open items

- Confirm the allowed characters and length for DocumentDB cluster names before Phase 6.
- Confirm the final globally unique names for Key Vaults, the registry and the state storage account when they are created.
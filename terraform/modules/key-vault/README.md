# modules/key-vault

Creates one Key Vault per regional environment and the access model around it.

## Planned resources

- Key Vault using Azure RBAC for data-plane authorisation, with soft delete and purge protection enabled.
- Private endpoint and private DNS integration where private networking is required.
- Role assignments for operators, the workload identity and the CSI driver identity.

## Planned inputs

| Input | Purpose |
|---|---|
| `location`, `resource_group_name` | Placement. |
| `name` | Globally unique vault name. |
| `subnet_id`, `private_dns_zone_id` | Private endpoint placement, when enabled. |
| `allowed_ip_ranges` | Only if public access is deliberately retained, with a stated reason. |
| `tags` | Common tags. |

## Planned outputs

- `key_vault_id`
- `key_vault_uri`
- `private_endpoint_id`

## Boundaries

- Does not write secret values from Terraform. Secrets are written by an operator or the application; a secret in Terraform configuration is a secret in state.
- Uses RBAC or access policies, never both.
- Outputs no secret value, key or connection string.
- Public network access is off by default. Re-enabling it requires a reviewed requirement.
- Purge protection means an accidental deletion is not quickly reversible. Do not apply this module to a throwaway environment without deciding the trade-off first.

## Status

Placeholder. Not implemented.

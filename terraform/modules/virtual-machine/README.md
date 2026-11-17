# modules/virtual-machine

Creates the Region 1 observability VM.

## Planned resources

- Linux VM with a system-assigned managed identity.
- NIC in a dedicated observability subnet, with an NSG allowing only the intended sources.
- OS disk plus separate data disks for Prometheus, Loki and Grafana storage.
- SSH through Azure AD, not a shared-key login.
- A cloud-init or custom-script extension that prepares Docker and the Compose stack location.

## Planned inputs

| Input | Purpose |
|---|---|
| `location`, `resource_group_name` | Placement. |
| `subnet_id` | Supplied by the networking module. |
| `size` | Cost-appropriate for the stack. |
| `data_disk_sizes_gb` | Per-signal storage sizing. |
| `admin_username` | Operator name for Azure AD SSH. |
| `tags` | Common tags. |

## Planned outputs

- `vm_id`
- `private_ip_address`
- `identity_principal_id`
- `data_disk_ids`

## Boundaries

- Does not deploy the Compose stack. That is `docker/` configuration applied to the host.
- Does not create dashboards or datasources. Those are provisioned files in `docker/grafana/`.
- No public SSH. Telemetry ingestion ports open only to approved AKS egress ranges, over TLS.
- The VM is an accepted single point of failure in the initial design. Do not present its outputs as a highly available endpoint.
- Disk sizing is an input, not a default. Decide the retention the stack actually needs and size for it.

## Status

Placeholder. Not implemented.

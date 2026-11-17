# shared/observability

**Root:** deployment root · **State:** own remote backend key (`shared/observability.tfstate`, proposed) · **Initially deployed:** yes (PLAN Phase 3)

The Region 1 VM that hosts the central observability stack.

## Owns

- The observability VM, its NIC, disks, managed identity and NSG.
- The observability subnet, if it is scoped to this root rather than to the region network module.
- Storage sizing and lifecycle for Prometheus, Loki and Grafana data.
- The VM's public IP and the NSG rules that allow ingestion (to nginx, HTTPS only) from the AKS clusters' egress IPs only.

## Does not own

- The Compose stack contents. Prometheus, Alloy, Loki, Grafana and OpenTelemetry Collector configuration lives in `../../../docker/` and is applied on the host.
- Dashboards and datasources, provisioned as files in `docker/grafana/`.
- Regional AKS clusters or their egress ranges, which arrive as inputs.

## Inputs from other roots

| Input | Source |
|---|---|
| Subnet ID | `environments/prod/region-1`, if the VM joins the regional VNet |
| Allowed source CIDRs for ingestion | Production regional roots' egress ranges |

## Notes

- This VM is an accepted single point of failure in the initial design. Do not describe the platform as fully highly available while observability is centralised here.
- Telemetry delivery must not block application request handling. Buffering and retry live on the sender side.
- The stack needs out-of-band health visibility: if the collector or Loki is down, that must be observable somewhere other than the stack itself.
- Retention and disk sizing are inputs. Decide the retention the platform actually needs instead of accepting defaults that fill the disk quietly.
- Applying this root requires the Region 1 network (and therefore that regional root) to exist first.

## Status

Placeholder. No Terraform written yet.

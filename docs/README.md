# docs/

Durable project documentation that does not belong in `PROJECT.md` or `PLAN.md`.

## Planned subdirectories

Created when there is content to put in them; listed here so the shape is agreed in advance.

| Path | Purpose |
|---|---|
| `runbooks/` | Operational procedures: forced and graceful promotion, service-managed failover, failback, regional failover, observability recovery, certificate renewal. |
| `decisions/` | Lightweight ADRs recording material decisions and the reasoning behind them. |
| `diagrams/` | Architecture and network diagrams in a diffable format, not binary screenshots. |
| `networking/` | VNet address plans, subnet tables, peering intent, DNS resolution and NSG rules. |
| `testing/` | Failure-injection and recovery exercise records, with observed routing behaviour, latency, replication lag, RTO and RPO. |

## Rules

- `PROJECT.md` holds architecture, goals and scope. `PLAN.md` holds phase order and completion. Do not duplicate either here.
- Record the observed result of a test, not the expected result. If a step was skipped, say so.
- Anything that a future operator would need at 3am belongs in a runbook, with the actual command and the expected output.
- No credentials, connection strings, tenant IDs, subscription IDs or Terraform state contents.

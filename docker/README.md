# docker/

Docker Compose configuration for the centralized observability stack running on the Region 1 VM.

## Expected contents

Laid out to mirror the stack, so a component's configuration has exactly one home.

| Path | Purpose |
|---|---|
| `compose.yaml` | Single Compose definition for the whole stack. |
| `nginx/` | Reverse proxy: the only public entry point. TLS termination, authentication and routing to the ingestion backends. |
| `prometheus/` | `prometheus.yml`, recording and alerting rules, scrape targets. |
| `loki/` | Loki configuration and retention settings. |
| `alloy/` | Alloy pipeline configuration, if the VM runs an Alloy agent. |
| `otel-collector/` | OpenTelemetry Collector receiver, processor and exporter configuration. |
| `grafana/` | Provisioned datasources and dashboards, so they are reproducible rather than hand-built. |
| `env.example` | Non-sensitive example of the variables the stack expects. |

## Boundaries

- This directory is configuration, not infrastructure. The VM, disks, network rules, DNS and certificates are Terraform under `terraform/infrastructure/shared/observability/`.
- One collection path per signal. Decide whether Prometheus scrapes targets directly or Alloy collects on its behalf, and do not run both for the same target.
- Ingestion endpoints require TLS and authentication, and are restricted to the approved AKS egress ranges. nginx is the only container that publishes a port publicly; backends and Grafana are reachable only through it or not at all.
- Telemetry delivery must never block application request handling.
- Components are the ones agreed in `PROJECT.md`: Prometheus, Alloy, Loki, Grafana and OpenTelemetry Collector. Tempo is optional and not selected; do not add a trace backend without recording that decision.
- Retention and storage sizing are explicit values, not defaults. The VM's data disks are the limit.
- No secrets in this directory. Credentials arrive through environment files that are not committed, or through the VM's managed identity where the component supports it.

# modules/observability

Optional module for observability-specific Azure resources, if the stack needs more than a plain VM.

`PROJECT.md` lists this module, but it is not yet established that it earns its place: Prometheus, Loki, Grafana and the OpenTelemetry Collector are Compose configuration in `docker/`, not Azure resources.

## Candidate reasons to create it

- Storage accounts or managed disks that must be sized and lifecycle-managed together with the stack rather than with a generic VM.
- Central alerting routes (Action Groups) for the stack's own health, so a failure of the observability host is visible outside that host.
- A trace backend, only if one is actually selected.

## Boundaries

- Must not duplicate `modules/virtual-machine`. If it only wraps a VM, it should not exist.
- Must not introduce a second collection path for a signal that another component already owns.
- Must not claim high availability. The stack is centralised in Region 1 by design for now.

## Status

Placeholder. Decide whether this module is needed during Phase 3, before writing any code. If it is not needed, delete the directory rather than leaving an empty abstraction.

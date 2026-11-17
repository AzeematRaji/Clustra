# app/

The demo workload: **AKS Store Demo** (`Azure-Samples/aks-store-demo`). A polyglot, event-driven microservices app: orders, products, a queue, a document database and an optional AI service.

The platform in `terraform/` is the deliverable. This application exists to generate realistic traffic, telemetry and regional behaviour so the platform can be exercised and observed.

## Strategy: reference upstream, never vendor

Upstream is pinned by commit SHA and checked out in CI. No fork, no submodule, no `git subtree`.

- The repository stays infrastructure-focused, which is its purpose.
- Upstream fixes arrive as a one-line SHA bump with a reviewable diff.
- A public repository needs no PAT: `actions/checkout` with `repository:` and `ref:` is enough.

Record the pinned SHA and the date it was chosen in this file whenever it is bumped.

## Images: mirror into ACR, do not build

Upstream publishes public images on GHCR and MCR. The pipeline pulls each image at its pinned tag, retags it immutably, and pushes it to the shared ACR.

```text
pull upstream image  ->  retag with commit SHA  ->  push to ACR
```

Why not build the source:

- The ACR learning objective is about kubelet pull permissions, ACR authentication and cross-region pull behaviour. That needs images **in our registry**, not source builds.
- Building here would mean a seven-service, four-toolchain CI matrix for no learning gain.

**Upgrade path, documented but not taken:** build from source at the pinned SHA if the application ever needs code changes. If that happens, revisit the no-fork decision in the same change.

## Manifests: owned here, plain YAML, no Helm

Upstream's `aks-store-all-in-one.yaml` is the reference, not the deployment. Our manifests and patches live in this directory.

Plain manifests or Kustomize overlays, deliberately not a Helm chart: easier to read, easier to diff, easier to teach from. Revisit only if the manifest count grows past what a reader can hold in their head.

### What our overlays must change

- Namespace, so the app is clearly separated from system workloads.
- Image references, rewritten to the ACR login server with immutable commit-SHA tags. No `latest`.
- Database URI, injected from Key Vault through the CSI driver. It is never a Terraform output, because the provider's connection string embeds the administrator credentials.
- RabbitMQ, which stays in-cluster per region.
- Key Vault CSI volume mounts for the `ai-service` credentials, avoiding any secret in a manifest.
- Resource requests and limits, so scheduling and scaling behaviour is predictable.
- Observability wiring for Alloy: scrape annotations, log collection, OTLP export.

## Services

| Service | Language | Role |
|---|---|---|
| `store-front` | Vue.js | Customer-facing web app for placing orders. |
| `store-admin` | Vue.js | Employee web app for viewing the order queue and managing products. |
| `order-service` | JavaScript | Accepts orders and publishes them to the queue. |
| `makeline-service` | Go | Consumes the queue and completes orders against the database. |
| `product-service` | Rust | CRUD operations on products. |
| `virtual-customer` | Rust | Scheduled order simulation. |
| `virtual-worker` | Rust | Scheduled order-completion simulation. |
| `ai-service` | Python | Optional generative text and image creation, used by `store-admin`. |
| RabbitMQ | — | In-cluster order queue, one per region. |

Four languages means four build toolchains if we ever build from source, and three separate runtime concerns for telemetry collection.

## Observability: Alloy, no code changes

Collection is agent-based through Grafana Alloy running in-cluster. No OpenTelemetry SDK is added to the services, and the application source is not modified.

Accepted consequence: there are **no application-level distributed traces**. Alloy sees node, container and log signals, and eBPF auto-instrumentation can produce network-level spans, but business-level spans would require code changes and therefore a fork. Record this as a stated limitation rather than a gap to close later.

## Traffic generation

`virtual-customer` and `virtual-worker` are **user simulators, not load generators**: they act at a human cadence with sleeps between actions. They are useful for keeping each region's data populated and for exercising the end-to-end order path.

They do not produce load, and they never exercise Front Door when run inside a cluster.

Load generation for the active-active experiments is a separate concern and remains an open decision: a real generator aimed at the Front Door hostname, controlled on demand, versus in-cluster Kubernetes jobs. Whatever is chosen, load aimed at Front Door must originate outside the cluster, or Front Door's distribution and failure behaviour is never observed.

## Boundaries

- No secrets, connection strings or `.env` files. Credentials arrive from Key Vault through workload identity, and the database endpoint arrives as Terraform output.
- No cluster-level concerns here: ingress controller, namespace creation, resource quotas and network policy belong to the regional Terraform roots.
- The database is a managed Azure service, so there is no database StatefulSet or PVC here. RabbitMQ keeps that learning: it is still an in-cluster StatefulSet with a zone-pinned `ReadWriteOnce` disk.
- Application read/write strategy is configured here but decided in `PROJECT.md`. Writes go to the single primary region; the second region holds a synced replica.

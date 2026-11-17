# Clustra — Multi-Region Azure Infrastructure

> Working project name: **Clustra** (`clustra-infra`). The name is provisional until repository/domain availability is checked.

## Overview

Clustra is an infrastructure-focused project that provisions a multi-region Azure platform for demonstrating global application delivery, Kubernetes operations, regional database replication, disaster recovery and centralized observability.

A sample microservices application will be deployed to the platform to generate realistic traffic and make regional routing, telemetry and failure scenarios observable. The application is a demonstration workload; the primary deliverable is the infrastructure and the operational understanding gained from it.

## Goals

- Provision two production AKS clusters in separate Azure regions.
- Use Azure Front Door as the global HTTP/HTTPS entry point and route requests to regional ingress endpoints.
- Run both production regions as active application-serving regions.
- Use separate regional VNets and Key Vaults.
- Share a single ACR initially, without geo-replication, to control cost.
- Centralize metrics, logs and application telemetry on a self-hosted observability VM in Region 1.
- Learn and demonstrate Azure DocumentDB primary/read-replica replication, failover and recovery.
- Keep the Terraform code organized into reusable modules and independently deployable root configurations.
- Keep the staging structure in place without deploying it; staging is not planned for this project.

## Non-goals

- Building a production-grade multi-cloud platform.
- Introducing a hub-and-spoke network unless a concrete requirement justifies it.
- Implementing multi-writer replication between regions.
- Making every shared component highly available in the initial cost-conscious deployment.
- Building a bespoke microservices product.
- Enabling ACR geo-replication in the initial deployment.
- Treating active-active application traffic as proof of active-active data writes.

## Target architecture

```text
                         Internet users
                               |
                         Azure Front Door
                         /             \
                Regional origin 1   Regional origin 2
                       |                  |
                 Ingress / LB        Ingress / LB
                       |                  |
                  AKS Region 1       AKS Region 2
                  Production         Production
                       |                  |
                       +------ writes ---+
                              |
                    DocumentDB Primary
                         Region 1
                              |
                    Asynchronous replica
                         Region 2

       Shared services:
       - Azure Container Registry (one registry; no geo-replication initially)
       - Central observability VM in Region 1
       - - Prometheus, Alloy, Loki, Grafana, OpenTelemetry Collector
       - Optional trace backend to be selected if required

       Regional services:
       - One VNet per region
       - One AKS cluster per production region
       - One Key Vault per regional environment
       - DocumentDB primary and cross-region replica
```

### Application traffic

Azure Front Door **Standard** is the global entry point. It routes HTTP/HTTPS requests to the public endpoint of each region's ingress controller/load balancer. The ingress controller routes requests to Kubernetes Services, which route to Pods.

Standard does not support Private Link origins, so origins are protected by allowing only the `AzureFrontDoor.Backend` service tag at the network layer and rejecting requests whose `X-Azure-FDID` header does not match this Front Door profile. Until the application is deployed, a minimal health-check workload behind each ingress gives the probes a real ingress → Service → Pod path to check.

Both production AKS clusters actively serve application traffic. Traffic distribution is controlled by Front Door origin-group configuration, health probes and routing/weight settings; it should not be assumed to be exactly 50/50.

### Regional networking

Each region has its own VNet and non-overlapping address space. The VNets are **not peered** initially.

- **AKS → DocumentDB:** each regional VNet gets its own private endpoints to both the primary and the replica cluster, with a private DNS zone linked to that VNet. A private endpoint can target a resource in another region, so Region 2 workloads reach the Region 1 primary privately over the Azure backbone without peering and without exposing the database publicly. Endpoints to both clusters are needed so the global read-write connection string still resolves privately after a promotion. Whether the global hostname resolves correctly through private DNS must be validated in Phase 6.
- **AKS → observability VM:** decided. The VM exposes a public ingestion endpoint. An nginx reverse proxy in the Docker Compose stack is its only public entry point: it terminates TLS, requires authentication and forwards to the ingestion backends (OTel Collector, Loki, Prometheus remote-write). The NSG allows ingestion only from the AKS clusters' stable egress IPs. Grafana and the backends are not exposed directly. Region 1 may use the same path or reach the VM privately, depending on where the VM is placed.
- **Revisit peering** if more cross-region private paths appear, for example scraping from the VM into Region 2, or if private endpoints become harder to manage than one peering link.

### Database model

The database is Azure DocumentDB (with MongoDB compatibility), the service formerly named vCore-based Azure Cosmos DB for MongoDB. It implements the MongoDB wire protocol, so the application's MongoDB drivers connect without code changes.

The initial design is:

- Region 1: DocumentDB primary cluster, M30, read/write.
- Region 2: cross-region read replica cluster, read-only until promoted.
- Replication: asynchronous, one secondary region.
- Application writes: directed to the primary through the global read-write connection string.
- Reads: initially use the primary for simplicity and consistency; per-region replica reads may be evaluated later.

This is active-active application serving with a single authoritative write database. It is not multi-writer database architecture. Both clusters are owned by the Region 1 Terraform root, because the replication topology is a property of the primary.

The project explicitly studies:

1. Replication and replication lag.
2. Forced promotion, graceful promotion and service-managed failover, and the RPO each implies.
3. Recovery and safe return to the intended topology.

Constraints, verified against current Azure documentation:

- Cross-region replication requires M30 or higher on both clusters. Burstable tiers (M10, M20, M25) and the free tier do not support replication.
- A cluster scaled to M30 or higher cannot be scaled back down to a burstable tier.
- Replica clusters do not support point-in-time restore or in-region high availability.
- Replication requires the `GeoReplicas` preview feature enabled when the primary is created.
- Storage size and shard count are inherited and cannot be changed on the replica.
- Service-managed failover must be enabled before an outage; it cannot be enabled retroactively.

Service-managed failover is disabled initially so that manual promotion is practised deliberately. It is enabled during Phase 8 to compare behaviour.

Staging will not be deployed during this project, so promotion and failover drills run against the production database pair while it holds only demo data. Each drill needs explicit approval and a runbook, and the intended topology is restored afterwards, by a reviewed plan or by destroying and recreating the pair.

Connection strings embed the administrator credentials, so they are never passed between Terraform roots. Credentials live in Key Vault and are delivered to workloads through the Secrets Store CSI driver.

### Observability

A single VM in Region 1 hosts the central observability stack using Docker Compose:

- Prometheus — metrics storage and querying.
- Grafana Alloy — telemetry collection/processing/forwarding where appropriate.
- Loki — log aggregation.
- Grafana — dashboards and visualization.
- OpenTelemetry Collector — OTLP receiving and telemetry processing/export.

Applications in both AKS clusters may export telemetry to a securely reachable OTLP endpoint on the VM. Alloy may also run as an agent in AKS if Kubernetes node, container or log collection requires it. Define ownership of collection pipelines to avoid duplicate telemetry.

A trace storage backend such as Grafana Tempo may be added if distributed trace storage is required; it is not a mandatory initial component until confirmed.

The observability VM is a single point of failure in the initial design. Telemetry delivery must not block application request handling.

## Infrastructure scopes and Terraform state

The repository separates reusable modules from independently deployable Terraform roots.

### Planned roots

| Root | Scope | Initial deployment |
|---|---|---|
| `terraform/infrastructure/global/front-door` | Global Front Door profile, origin groups and routes | Yes |
| `terraform/infrastructure/shared/acr` | Shared container registry | Yes |
| `terraform/infrastructure/shared/observability` | Region 1 observability VM and supporting resources | Yes |
| `terraform/infrastructure/environments/prod/region-1` | Production Region 1 network, AKS, Key Vault and regional resources | Yes |
| `terraform/infrastructure/environments/prod/region-2` | Production Region 2 network, AKS, Key Vault and regional resources | Yes |
| `terraform/infrastructure/environments/staging/region-1` | Optional staging regional deployment | No |
| `terraform/infrastructure/environments/staging/region-2` | Temporary optional staging regional deployment | No |

There are seven planned independent state boundaries. Five are expected to be active initially. Each root has a separate remote backend key/state. The remote state backend is bootstrapped separately.

The global Front Door root may later add a separate staging hostname/route and staging origin group. Staging regional infrastructure remains independently managed in its own state. Staging must never be included in the production origin group.

### Intended repository layout

```text
clustra/
├── .github/
│   └── workflows/                  image build/push, Terraform checks, plan and apply
├── app/                            demo workload, or the pinned reference to it
├── docker/                         observability stack Compose configuration
├── docs/                           runbooks, decisions, diagrams, network plans, test records
├── terraform/
│   ├── bootstrap/                  remote state storage
│   ├── modules/
│   │   ├── networking/
│   │   ├── aks/
│   │   ├── key-vault/
│   │   ├── container-registry/
│   │   ├── front-door/
│   │   ├── virtual-machine/
│   │   └── observability/
│   └── infrastructure/
│       ├── global/
│       │   └── front-door/
│       ├── shared/
│       │   ├── acr/
│       │   └── observability/
│       └── environments/
│           ├── prod/
│           │   ├── region-1/
│           │   └── region-2/
│           └── staging/
│               ├── region-1/
│               └── region-2/
├── AGENTS.md
├── PLAN.md
└── PROJECT.md
```

Modules should be introduced when they represent a meaningful reusable capability. Avoid building abstractions before the first concrete use case is understood.

## Key technology choices

- Infrastructure as Code: Terraform.
- Cloud: Microsoft Azure.
- Kubernetes: Azure Kubernetes Service (AKS).
- Global application delivery: Azure Front Door Standard.
- Container registry: Azure Container Registry.
- Secrets: Azure Key Vault, with AKS Workload Identity and Secrets Store CSI integration evaluated.
- Messaging: RabbitMQ, running in-cluster in each region.
- Database: Azure DocumentDB (with MongoDB compatibility), a Region 1 M30 primary and Region 2 cross-region replica.
- Observability: Prometheus, Grafana Alloy, Loki, Grafana and OpenTelemetry Collector on a Docker Compose VM.
- Application: AKS Store Demo (`Azure-Samples/aks-store-demo`), referenced by pinned commit SHA rather than vendored, with manifests owned in `app/`.
- Optional AI integration: Azure AI Foundry, treated as an optional application/platform extension rather than a prerequisite for the core infrastructure.

## Cost and scope controls

- Do not enable ACR geo-replication initially. A single registry can serve image pulls from both regions; cross-region pulls affect deployment/scaling time, not normal request latency after images are running. Revisit if registry regional resilience becomes a requirement.
- Use appropriately small development/test SKUs and storage allocations.
- Keep staging undeployed; it is not planned for this project.
- Tear down the DocumentDB pair through the targeted Terraform workflow when not in use (it holds demo data only), and stop AKS clusters between working sessions.
- The observability VM is centralized in Region 1 initially.
- Track costs for AKS node pools, the DocumentDB M30 primary and replica, Front Door, ACR, VM/storage, networking and data transfer. The database pair is the second-largest line item after AKS nodes.
- Validate service-tier requirements and regional availability before selecting SKUs.

## Important operational risks

- Region 2 application writes depend on connectivity to the Region 1 DocumentDB primary.
- Cross-region writes introduce additional latency.
- Asynchronous replication can lose the most recent unreplicated transactions during a failure, depending on replication lag and failure conditions.
- Promotion requires an explicit runbook and testing. The global read-write connection string follows the new primary automatically, but anything using a self connection string must be updated by hand.
- Backup history restarts at promotion, so point-in-time recovery to a time before the switch is unavailable on the promoted cluster.
- High availability must be re-enabled on a promoted replica, and Terraform reports drift after any promotion drill.
- The RabbitMQ queue is in-cluster per region, so queued orders do not cross regions.
- The application has no conflict resolution, which is why multi-region database writes are excluded.
- The observability VM is a single point of failure.
- A single ACR without geo-replication is a dependency on its home region for uncached image pulls.
- Front Door health checks must represent application-serving health, not merely ingress-controller process health.
- Stateful application sessions, background jobs, scheduled tasks and idempotency need consideration when both regions serve traffic.

## Reference documentation

- [Azure Front Door documentation](https://learn.microsoft.com/azure/frontdoor/)
- [AKS documentation](https://learn.microsoft.com/azure/aks/)
- [AKS multi-region architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-multi-region/aks-multi-cluster)
- [Azure DocumentDB cross-region replication](https://learn.microsoft.com/azure/documentdb/cross-region-replication)
- [Azure DocumentDB cross-region failover modes](https://learn.microsoft.com/azure/documentdb/failover-modes)
- [Azure DocumentDB service limits and quotas](https://learn.microsoft.com/azure/documentdb/limitations)
- [AKS Store Demo](https://github.com/Azure-Samples/aks-store-demo)
- [Azure Container Registry geo-replication](https://learn.microsoft.com/azure/container-registry/container-registry-geo-replication)
- [AKS Secrets Store CSI Driver](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver)
- [Grafana Alloy documentation](https://grafana.com/docs/alloy/latest/)
- [OpenTelemetry documentation](https://opentelemetry.io/docs/)
- [Terraform remote state](https://developer.hashicorp.com/terraform/language/state/remote)

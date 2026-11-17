# PLAN.md

## Purpose

This is the high-level delivery roadmap for Clustra. It identifies the intended order of work and the outcomes expected from each phase. It is not a resource-by-resource implementation specification.

Do not mark a phase complete until its outcome has been implemented and validated.

Progress is tracked on the GitHub Project board: each phase is an epic issue, and its tasks are sub-issues.

## Phase 0 — Confirm prerequisites and bootstrap

**Outcomes**
- Confirm the two Azure regions and verify required services/SKUs are available in both (AKS, DocumentDB M30 with `GeoReplicas`, Front Door Standard).
- Choose non-overlapping VNet address spaces and initial subnet ranges, including private-endpoint subnets.
- Establish naming, tagging and resource-group conventions.
- Select Terraform and AzureRM provider versions.
- Create the remote Terraform state backend and its access controls independently of the infrastructure it will manage.
- Establish a cost budget and alerts.

**Learning focus**
- Terraform remote backends and state locking.
- Azure resource hierarchy, subscriptions, resource groups and RBAC.

## Phase 1 — Repository and Terraform foundations

**Outcomes**
- Create the agreed repository layout. *(Done: directories and boundary READMEs exist.)*
- Establish independent Terraform roots and backend keys for the seven planned deployment boundaries.
- Implement only the first required reusable modules as concrete needs emerge.
- Add GitHub Actions workflows for formatting, validation and plan review on pull requests, authenticated to Azure with OIDC.
- Add a manually dispatched apply/destroy workflow that targets one root, with an optional module target so a single component (for example the DocumentDB pair) can be torn down and recreated on its own.
- Document root-to-root dependencies and required outputs.

**Learning focus**
- Terraform modules versus root configurations.
- Remote state, outputs, dependency boundaries and safe state ownership.
- Terraform plan review, targeted operations and drift detection.

## Phase 2 — Regional networking

**Outcomes**
- Provision a separate VNet in each production region.
- Create the required AKS, ingress, private-endpoint and supporting subnets.
- Ensure address spaces do not overlap.
- Do not peer the VNets initially. Cross-region access to DocumentDB uses private endpoints created in each region's own VNet (see `PROJECT.md`, Regional networking).
- Create a private DNS zone for DocumentDB in each region, linked to that region's VNet.
- Give each AKS cluster a stable egress IP, so the observability VM can allowlist it. Region 2 telemetry reaches the VM through a public, IP-restricted, TLS-authenticated nginx endpoint (see `PROJECT.md`).
- Establish routing and network security rules for the required service-to-service paths.

**Learning focus**
- Azure VNet and subnet design.
- Private endpoints across regions, and when peering becomes necessary.
- Private DNS, route tables and NSGs.
- AKS network models and IP planning.

## Phase 3 — Shared platform services

**Outcomes**
- Provision one shared ACR without geo-replication initially.
- Configure access for both AKS clusters using managed identity and least privilege.
- Provision the Region 1 observability VM.
- Deploy the agreed observability stack with Docker Compose, with all configuration in `docker/` and changes delivered to the VM by a GitHub Actions workflow.
- Secure telemetry ingestion from both regions: nginx in the Compose stack terminates TLS and enforces authentication, and the NSG allows only the AKS egress IPs.
- Define data retention, storage capacity, backup and recovery expectations for observability data.

**Learning focus**
- ACR authentication and AKS image-pull permissions.
- Docker Compose operations on an Azure VM, deployed from CI.
- Prometheus, Alloy, Loki, Grafana and OpenTelemetry Collector responsibilities.
- OTLP protocols, TLS, authentication and telemetry pipelines.

## Phase 4 — Production regional AKS foundations

**Outcomes**
- Provision the production AKS cluster in Region 1.
- Provision the production AKS cluster in Region 2.
- Configure cluster identity, node pools, networking, monitoring integration and baseline security.
- Provision a separate Key Vault for each regional environment.
- Configure AKS Workload Identity and the Secrets Store CSI integration as appropriate.
- Confirm both clusters can pull images from the shared ACR.
- Confirm both clusters can securely export telemetry to the central observability VM.

**Learning focus**
- AKS cluster and node-pool design.
- Workload Identity and Azure RBAC.
- Key Vault CSI integration.
- Cluster upgrades, autoscaling and regional availability.

## Phase 5 — Regional application ingress and global traffic

**Outcomes**
- Deploy a regional ingress solution to each production AKS cluster.
- Deploy a minimal health-check workload (a small HTTP Deployment and Service) behind each ingress, so Front Door probes exercise the full ingress → Service → Pod path before the real application exists. Replace the probe target with an application endpoint in Phase 7.
- Establish stable regional origin endpoints.
- Provision Azure Front Door **Standard** with a production origin group containing both regional origins.
- Protect origins: restrict ingress to the `AzureFrontDoor.Backend` service tag and reject requests whose `X-Azure-FDID` header does not match this profile.
- Configure routing, origin weights/priorities, health probes and TLS.
- Validate normal traffic distribution and regional origin failure behaviour.

**Learning focus**
- Azure Front Door profiles, endpoints, routes, origin groups, origins and health probes.
- Front Door origin health and load-balancing behaviour.
- AKS ingress and Kubernetes Service routing.
- TLS and origin access protection without Private Link.

## Phase 6 — DocumentDB provisioning and replication

**Outcomes**
- Provision an Azure DocumentDB primary cluster in Region 1 at M30, with `preview_features = ["GeoReplicas"]` set at creation.
- Provision the cross-region read replica in Region 2, owned by the Region 1 root.
- Create private endpoints to both clusters in both regional VNets, with private DNS records, and disable public network access.
- Store credentials in each regional Key Vault and deliver them through the Secrets Store CSI driver.
- Verify that writes from both regions reach the primary through the global read-write connection string.
- Measure cross-region write latency and replication lag, and make lag observable.
- Exercise tearing down and recreating the database pair through the targeted workflow, including the order relative to Region 2's private endpoints.

Promotion and failover drills are not part of this phase; they are in Phase 8.

**Learning focus**
- Azure DocumentDB asynchronous cross-region replication and replica lag.
- Global read-write versus self connection strings.
- Private endpoints and DNS for a resource in another region.
- Cross-region network latency.

**Constraints**

- Replication requires M30 or higher on both clusters. Burstable tiers (M10–M25) and the free tier do not support it.
- A cluster scaled to M30 or higher cannot be scaled back down to a burstable tier.
- Replica clusters do not support point-in-time restore or in-region high availability.
- Storage size and shard count must match the primary and cannot be changed on the replica.

## Phase 7 — AKS Store Demo application

**Outcomes**
- Pin the upstream AKS Store Demo repository to a commit SHA and record it.
- Mirror the upstream images into the shared ACR with immutable commit-SHA tags. Do not build from source.
- Own the manifests and overlays in `app/` as plain YAML or Kustomize.
- Deploy the application to both production AKS clusters, with RabbitMQ in-cluster per region.
- Configure application secrets through Key Vault and the Secrets Store CSI driver.
- Configure database connectivity through the global read-write connection string.
- Point the Front Door health probe at an application endpoint and retire the placeholder health-check workload.
- Collect telemetry with Grafana Alloy running as an agent, without modifying application source.
- Generate load with `virtual-customer` and `virtual-worker` in-cluster, and with an external probe at the Front Door hostname.
- Verify that both regional deployments serve requests and that Front Door distributes traffic between them.

**Application**

AKS Store Demo (`Azure-Samples/aks-store-demo`): a polyglot, event-driven microservices sample. Go, JavaScript, Rust and Vue services over RabbitMQ and a document database, with an optional AI service.

**Accepted limitations**
- Because the application source is not modified, there are no application-level distributed traces. Alloy provides node, container and log signals; eBPF at best adds network-level spans.
- `virtual-customer` and `virtual-worker` are user simulators, not load generators. They exercise the order path but create no real load, and in-cluster traffic never exercises Front Door.

**Learning focus**
- Kubernetes application deployment and service discovery.
- Agent-based telemetry collection without code changes.
- Application configuration and secret delivery through Key Vault.
- Image supply chain: mirroring, immutable tagging and ACR pull permissions.
- Load generation and traffic distribution testing.

## Phase 8 — Reliability validation and project close-out

**Outcomes**
- Run controlled regional application failure tests.
- Run database drills: graceful promotion (zero data loss), forced promotion (possible data loss), and service-managed failover (enabled before the drill). Record RPO, RTO and the differences between them.
- Document the failback procedure, including that backup history restarts at promotion, so point-in-time recovery to before the switch is unavailable.
- Test observability behaviour when the central VM or network path is unavailable.
- Test image-pull behaviour when the ACR home region is unavailable, where safely feasible.
- Record observed traffic routing, latency, replication lag, recovery time and limitations.
- Review security exposure, IAM/RBAC, secrets, backups, retention and costs.
- Update architecture diagrams, runbooks and project documentation.

**Safety requirement:** database drills run against the production database pair only while it holds demo data, never real data. Each drill needs explicit human approval, a written runbook and a recovery plan. After a drill, restore the intended topology by reviewing the Terraform plan, or by destroying and recreating the database pair through the targeted workflow; never apply a post-drill plan blindly.

**Learning focus**
- Failure injection and resilience testing.
- Forced versus graceful promotion versus service-managed failover, and the RPO each implies.
- Operational runbooks.
- RPO/RTO measurement.
- Cost and reliability trade-offs.

## Phase 9 — Staging (optional)

Staging is not planned to be deployed during this project. The staging roots exist to keep the structure and boundaries honest. This phase is only started if a concrete need appears, and `AGENTS.md` and `PROJECT.md` are updated first.

**Outcomes (if started)**
- Configure staging-specific AKS, VNet, Key Vault and application settings in the staging Region 1 root.
- Add a separate staging hostname/route and staging origin group to the existing Front Door profile.
- Ensure staging origins cannot receive production traffic.
- Optionally provision staging Region 2 for a temporary multi-region test, then destroy only that staging root.
- Verify that staging lifecycle operations do not modify production or shared resource states.

## Definition of done

The initial project is considered complete when:

- Both production AKS clusters are deployed in separate regions and can serve the demo application.
- Azure Front Door routes traffic to both healthy regional origins and responds correctly to a regional application-origin failure.
- Both clusters can pull images from the shared ACR.
- Each regional environment has its own VNet and Key Vault.
- Both clusters can send telemetry to the central observability VM.
- DocumentDB primary/replica replication is verified and replication lag is observable.
- A controlled database failover and recovery exercise has been documented and completed.
- Terraform roots have independent remote states and changes are scoped to the intended state.
- Cost, security limitations and remaining single points of failure are documented.

## Working rules

- Deliver one phase at a time; avoid provisioning the entire platform in one large Terraform root.
- Keep production and staging in separate roots and states.
- Do not deploy staging merely because its directory exists.
- Do not enable ACR geo-replication unless the cost/availability decision is revisited.
- Tear down or stop costly components when not in use: destroy the DocumentDB pair through the targeted workflow while it holds no real data, and stop AKS clusters between working sessions.
- Do not describe the application layer as fully highly available until database, network, identity, background processing and observability dependencies have been considered.
- Update this plan and `PROJECT.md` when material scope or architecture decisions change.

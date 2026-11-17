# AGENTS.md

## Purpose

This repository provisions and documents a multi-region Azure platform used to demonstrate active-active application delivery, regional Kubernetes infrastructure, database replication and disaster recovery, and centralized observability.

## Working principles

- Prefer clear, conventional Terraform over clever abstractions.
- Make the smallest change that correctly addresses the task.
- Keep infrastructure changes reviewable and scoped to one deployment root wherever practical.
- Do not introduce additional services, modules, environments, regions, or architectural patterns without a stated requirement.
- Explain important trade-offs and operational consequences; do not present a design choice as settled when it is still open.
- Do not claim that infrastructure has been deployed, tested, or validated unless the relevant command or Azure operation was actually run and its result is available.
- For YAML files, always use **block sequence** style (standard hyphen notation) for all YAML lists. Never use inline flow sequences (`[...]`).


## Architecture boundaries

The intended architecture is:

- Two Azure regions, each with its own VNet and production AKS cluster.
- Both production AKS clusters actively serve application traffic.
- One Azure Front Door profile provides the global HTTP/HTTPS entry point and routes traffic to regional ingress origins.
- One shared Azure Container Registry (ACR), initially without geo-replication to control cost.
- One centralized observability VM in Region 1, running Docker Compose. Our observability stack of Prometheus, Grafana, Alloy, Loki and maybe OTel collector will run there via docker compose, managed via config files that will live on repo and changes to the VM deployed via github actions.
- Each regional AKS environment has its own Key Vault and secrets integration.
- Azure DocumentDB (with MongoDB compatibility) is planned as a Region 1 M30 primary and a Region 2 cross-region read replica. Replication, failover and recovery are explicit learning objectives. Both clusters are owned by the Region 1 root.
- Staging is planned for Region 1 only initially. A Region 2 staging deployment may be provisioned temporarily for testing and then destroyed. Note, staging is only considered to keep structure. We will not deploy a staging environment throught this project. If it will later be deployed, this section will be updated.
- The demo microservices application is a workload for exercising the platform, not the main product being developed.

Do not assume that active-active application traffic means active-active database writes. The agreed initial database model has one authoritative writable primary and a read-only replica.

## Repository layout

```text
.github/workflows/   CI: application image build/push, Terraform checks, plan and apply
app/                 the demo microservices workload, or the pinned reference to it
docker/              Docker Compose configuration for the Region 1 observability stack
docs/                runbooks, decisions, diagrams, network plans, test records
terraform/
  bootstrap/         remote state storage, created outside Terraform-managed infrastructure
  modules/           reusable child modules
  infrastructure/    independently deployable root configurations
```

Every directory above contains a `README.md` stating what belongs there and what does not. Read it before adding files.

## Terraform layout and state boundaries

Use independently deployable Terraform root configurations. Reusable child modules belong under `terraform/modules/`; deployment roots belong under `terraform/infrastructure/`.

Expected deployment roots and independent state boundaries:

1. `terraform/infrastructure/global/front-door`
2. `terraform/infrastructure/shared/acr`
3. `terraform/infrastructure/shared/observability`
4. `terraform/infrastructure/environments/prod/region-1`
5. `terraform/infrastructure/environments/prod/region-2`
6. `terraform/infrastructure/environments/staging/region-1`
7. `terraform/infrastructure/environments/staging/region-2`

There are seven planned state boundaries, but only five are expected to be applied initially: Front Door, ACR, observability, production Region 1 and production Region 2. Staging roots remain available but unapplied until needed.

Rules:

- Give each root its own remote backend key/state. Do not combine unrelated roots into one state.
- Do not use Terraform workspaces as a substitute for these environment/region deployment roots.
- Bootstrap the remote state storage independently of the infrastructure it stores (`terraform/bootstrap/`).
- Keep backend configuration and state credentials out of source control. Use Azure storage for remote backend.
- Use outputs and explicit inputs to communicate between roots. Use `terraform_remote_state` only when necessary, and expose only the minimum non-sensitive outputs required.
- Do not output secrets, credentials, private keys, or sensitive connection strings.
- Do not make one root manage resources owned by another root.
- Avoid broad environment switches such as a single `allow_env` flag that conditionally creates an entire environment inside another environment's root. Staging should have its own root and state.
- A narrowly scoped feature flag may be used for optional Front Door staging routes/origins, provided it does not cause production resources to be recreated or coupled to staging lifecycle.

## Terraform conventions

- Pin Terraform and provider versions using the repository's established version constraints. Do not upgrade major versions incidentally.
- Declare input variables with descriptions, types and appropriate validation.
- Add descriptions to outputs.
- Use consistent, descriptive resource names and tags.
- Apply common tags where supported, including project, environment, region, managed-by and owner.
- Keep secrets out of `.tf`, `.tfvars`, plans committed to Git, command history and CI logs.
- Commit non-sensitive example variable files only. Use a secure secret-management mechanism for sensitive values.
- Prefer managed identities and workload identity federation over long-lived credentials.
- Use separate resource groups or clearly defined resource ownership boundaries where appropriate.
- Avoid hard-coded resource IDs when they can be passed as explicit inputs.
- Do not add a module for a single trivial resource unless it provides a meaningful reusable interface.
- Do not introduce provisioners unless there is no reasonable native alternative and the reason is documented.
- Format Terraform consistently and validate changes before proposing them.

## Networking and security

- Each Azure region has its own VNet and non-overlapping address space.
- The VNets are not peered initially. Do not assume they can communicate. Cross-region access to DocumentDB uses private endpoints in each region's own VNet; do not add peering without a reviewed decision.
- Document required cross-region paths, DNS resolution, routing and network security rules.
- Restrict observability ingestion endpoints to approved sources and use TLS and authentication where supported.
- Do not expose DocumentDB, Kubernetes control-plane access, Key Vault or observability backends publicly without an explicit reviewed requirement.
- Prefer private endpoints/private networking where supported and appropriate for the learning scope.
- Use AKS Workload Identity and the Key Vault Secrets Store CSI Driver where appropriate; do not place secrets in Kubernetes manifests or Terraform outputs.
- Treat Front Door origin protection and origin health-check design as explicit security/reliability tasks.

## Observability

The initial observability host is one VM in Region 1, deployed with Docker Compose. The planned components are Prometheus, Grafana Alloy, Loki, Grafana and the OpenTelemetry Collector. A trace backend such as Tempo may be evaluated if required; do not assume it is already selected.

Avoid duplicate collection pipelines. Define which component collects, processes and exports each signal. Application instrumentation is separate from collector placement: applications may export OTLP telemetry to a securely reachable collector endpoint on the VM.

Design for telemetry buffering/retries and graceful degradation if the central observability endpoint is unavailable. Do not make application request success depend on synchronous telemetry delivery.

The goal for this will be to have all configs in the repo, mounted as files , that is the promwtheus, grafana config files and dahs bords and rules files, and then all related changes made deplpyed to the server via github actions workflow.

## Database requirements

- The database is Azure DocumentDB (with MongoDB compatibility), the service formerly named vCore-based Azure Cosmos DB for MongoDB, managed through `azurerm_mongo_cluster`.
- Region 1 holds an M30 primary cluster; Region 2 holds a cross-region read replica. Replication requires M30 or higher on both clusters; burstable tiers and the free tier do not support it.
- Both clusters are owned by the `infrastructure/environments/prod/region-1` root, because the replication topology is a property of the primary. Each regional root owns the private endpoints (to both clusters) and private DNS in its own VNet.
- The primary is authoritative for writes. The replica is read-only until promoted and does not support point-in-time restore or in-region high availability.
- Do not configure applications to write to the replica.
- Applications use the global read-write connection string so writes follow a promoted cluster. Anything using a self connection string must be updated by hand after promotion.
- Connection strings embed the administrator credentials and must never be Terraform outputs. Keep credentials in Key Vault and deliver them through the Secrets Store CSI driver.
- Replication requires the `GeoReplicas` preview feature enabled at primary creation. Do not assume it can be added to an existing cluster.
- Treat replication lag, promotion, connection routing, recovery and failback as separate concerns.
- Service-managed failover is disabled by default so manual promotion is practised. Do not claim automatic failover unless it is explicitly configured, supported and tested.
- Do not implement destructive failover or failback operations without explicit human approval and a recovery plan. Because staging is not deployed, drills run against the production pair only while it holds demo data, never real data.
- After any promotion, expect Terraform drift: cluster roles swap, and high availability must be re-enabled on the promoted cluster. Review the plan; never apply it blindly after a drill.
- The database pair may be destroyed and recreated with a module-targeted workflow run to control cost while it holds no real data. This still needs explicit authorization. Destroy Region 2's DocumentDB private endpoints first and recreate them after the pair is back.

## Front Door and application routing

- Front Door uses the Standard tier and routes to public regional ingress endpoints; it does not route directly to Kubernetes Pods.
- Protect origins with the `AzureFrontDoor.Backend` service tag and an `X-Azure-FDID` header check, since Standard has no Private Link origins.
- Keep production and staging routing logically isolated, even if they share one Front Door profile.
- Staging must not be added to the production origin group.
- Health probes should reflect application readiness sufficiently to avoid routing traffic to a region that cannot serve the application.
- Document origin priority/weight, health-probe path, protocol, host header and origin access protection.
- Do not assume a 50/50 traffic split unless the configuration explicitly implements and validates it.

## Change safety and commands

Before proposing Terraform changes:

1. Inspect the relevant root, modules and documentation.
2. Identify which state boundary owns the affected resources.
3. Check whether another root consumes outputs from the affected root.
4. Make the smallest scoped change.
5. Run formatting and validation for the affected root when tooling is available.
6. Review the plan for unintended replacement, deletion, public exposure or cross-environment impact.
7. Summarize the change, validation performed, risks and any manual steps.

Never run `terraform apply`, `terraform destroy`, database promotion, replica deletion, failback, or other destructive/production-changing operations without explicit authorization from the user.

Do not apply a plan merely because it was generated. Plans must be reviewed by a human before application.

## Documentation and collaboration

- Update `PROJECT.md` when an architectural decision changes.
- Update `PLAN.md` when phase order, scope or completion status changes.
- Record material decisions and their rationale in a lightweight ADR/decision log if the repository adopts one.
- Keep documentation aligned with the actual Terraform layout.
- Do not silently change agreed architecture. Present alternatives and ask for a decision when a change affects cost, availability, security, state ownership or operational complexity.

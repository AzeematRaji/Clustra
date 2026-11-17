# global/front-door

**Root:** deployment root · **State:** own remote backend key (`global/front-door.tfstate`, proposed) · **Initially deployed:** yes (PLAN Phase 5)

The global Azure Front Door profile: the single HTTP/HTTPS entry point that routes traffic to the regional ingress endpoints.

## Owns

- Front Door **Standard** profile, endpoint(s) and custom domains.
- The production origin group, and the origins within it with their priorities, weights and health probes.
- Routes and the forwarding, host header and caching behaviour they apply.
- WAF policy (custom rules; managed rule sets need Premium) and origin access protection via the `X-Azure-FDID` header check, paired with an `AzureFrontDoor.Backend` service-tag NSG rule in the regional roots.
- Optionally a staging route and staging origin group.

## Does not own

- Regional ingress controllers, Kubernetes Services or pods. Those belong to the regional roots.
- AKS clusters, VNets, Key Vaults or the ACR.
- DNS zone delegation for the custom domain, unless that is explicitly decided here.

## Inputs from other roots

| Input | Source |
|---|---|
| Production regional origin endpoints | `environments/prod/region-1`, `environments/prod/region-2` outputs |
| Staging origin endpoint | `environments/staging/region-1` output, only if the staging route is enabled |

Passed as explicit variables. Revisit `terraform_remote_state` only if the manual hand-off becomes a real operational burden.

## Notes

- Applied after both production regional roots exist and expose an origin endpoint.
- Staging origins must never join the production origin group.
- Health probes must reflect application-serving readiness, not ingress-controller liveness.
- Weights and priorities are explicit. The traffic split is not assumed to be 50/50 and must be validated and recorded.
- A change here can affect every user of the platform. Plans for this root need human review before apply.

## Status

Placeholder. No Terraform written yet.

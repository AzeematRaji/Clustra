# modules/aks

Creates one AKS cluster and its node pools.

## Planned resources

- AKS cluster with a system node pool and a separate user node pool.
- Cluster managed identity and kubelet identity.
- Workload Identity: OIDC issuer and federated credentials for application pods.
- Monitoring integration as agreed (managed Prometheus / Container Insights). One collection path only.
- Secrets Store CSI Driver and the Key Vault provider add-on.

## Planned inputs

| Input | Purpose |
|---|---|
| `location`, `resource_group_name` | Placement. |
| `kubernetes_version` | Pinned, not `latest`. |
| `subnet_id` | Supplied by the networking module. |
| `system_node_pool`, `user_node_pools` | Sizing and autoscaling, per region. |
| `key_vault_id` | For the CSI integration. |
| `acr_login_server` and pull identity | Image pulls. |
| `tags` | Common tags. |

## Planned outputs

- `cluster_id`, `cluster_name`
- `oidc_issuer_url`
- `kubelet_identity_object_id`
- `cluster_identity_principal_id`

## Boundaries

- Does not create the VNet, subnets or the ACR.
- Does not deploy the application or an ingress controller.
- Does not silently grant ACR pull. The permission is expressed as an explicit input or assigned in the calling root, so it is visible where the dependency lives.
- No public API server endpoint unless a reviewed requirement says otherwise.
- Do not describe the cluster as highly available because it has multiple nodes; regional availability and zonal placement are separate decisions.

## Status

Placeholder. Not implemented.

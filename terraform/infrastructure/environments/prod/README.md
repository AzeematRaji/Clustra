# environments/prod

Production roots. Both regions actively serve application traffic through Front Door, while the authoritative database stays in Region 1.

| Root | Role |
|---|---|
| `region-1/` | Network, AKS, Key Vault, the DocumentDB primary and its cross-region replica, observability integration. |
| `region-2/` | Network, AKS, Key Vault, private endpoint and DNS for the DocumentDB replica. |

Region 2 is a traffic-serving region, not a warm standby, but its writes travel to the Region 1 primary. Treat that dependency, its latency and its failure behaviour as first-class production concerns.

These roots are applied only after the shared ACR exists, and the Front Door root is applied after them.

Changes here affect live traffic. Plans require human review before apply, including for "small" changes.

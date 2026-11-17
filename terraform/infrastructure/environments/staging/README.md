# environments/staging

Staging roots. They exist so staging capability is planned and reviewable, not so it gets deployed. Staging is not planned to be deployed during this project (PLAN Phase 9, optional).

| Root | Role |
|---|---|
| `region-1/` | Staging environment in Region 1. The primary staging target. |
| `region-2/` | Temporary staging Region 2, provisioned only for a multi-region staging test and then destroyed. |

## Rules

- These roots are not applied as part of normal work. Do not deploy staging because the directory exists.
- Staging has its own VNet, Key Vault, cluster and state. It never shares those with production.
- If staging must be visible in Front Door, that is a narrowly scoped staging route and staging origin group in `global/front-door`. Staging must never join the production origin group.
- Destroying a staging root must require no edits to production or shared state. If it does, the boundary is wrong and should be fixed before the exercise.
- Staging address spaces must not overlap production, so a misconfiguration fails loudly instead of quietly crossing environments.

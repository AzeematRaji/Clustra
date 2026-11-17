# infrastructure/shared

Roots for services used by more than one environment or region.

Currently: `acr/` and `observability/`.

These services are region-pinned in practice, so they are also single points of failure until a resilience decision is made. That trade-off is deliberate and cost-driven (`PROJECT.md`, Cost and scope controls).

## Rules

- A shared root must not depend on a specific environment's state. Shared services are built before the environments that consume them.
- If a shared service needs to grant permission to a regional identity, the grant is made in the regional root that owns the identity. Destroying that region then cannot leave a grant stranded in shared state.
- Shared roots must not be re-created casually. `acr` in particular holds the images every cluster depends on.

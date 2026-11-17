# staging/region-2

**Root:** deployment root · **State:** own remote backend key (`staging/region-2.tfstate`, proposed) · **Initially deployed:** no (PLAN Phase 9, optional; not planned)

Temporary staging Region 2. Provisioned only to exercise multi-region behaviour in staging, then destroyed on its own.

## Owns

- Its own small VNet, subnets and NSGs, with a non-overlapping address space.
- A staging AKS cluster sized for the specific test.
- Whatever other regional pieces that test needs.

## Does not own

- Anything in production, and nothing in `staging/region-1` either. Destroying this root must be a single safe operation.
- Front Door production origins. At most it appears in a staging origin group, owned by `global/front-door`.

## Inputs from other roots

| Input | Source |
|---|---|
| `acr_id` / `login_server` | `shared/acr` |
| Staging Region 1 ingress hostname, only if the test needs cross-region routing | `staging/region-1` |

## Notes

- This root is expected to be destroyed. Before creating it, confirm the exercise, the cost ceiling, and that teardown needs no edits to production or shared state.
- Everything created here must be removed by `terraform destroy` on this root alone. A resource created by hand is a defect to fix, not a footnote in the teardown.
- No data here needs to survive. No backup, retention or disaster-recovery expectation attaches to this root.
- Do not promote anything to production from here, and do not reuse production secrets.

## Status

Placeholder. No Terraform written yet. Deliberately unapplied.

# terraform/

All infrastructure as code for Clustra.

```text
terraform/
├── modules/          reusable child modules, no state of their own
├── bootstrap/        remote state storage, created outside Terraform-managed infrastructure
└── infrastructure/   independently deployable root configurations
    ├── global/       global-scope roots
    ├── shared/       cross-region shared services
    └── environments/ per-environment, per-region roots
```

## Rules

- Every deployment root under `infrastructure/` has its own remote backend key and its own state. Never combine roots, and never use Terraform workspaces as a substitute for them.
- Reusable code lives in `modules/`. A module must earn its place through a genuine reusable interface or more than one concrete consumer. Do not build abstractions before the first use case is understood.
- Roots communicate through explicit inputs and outputs. Use `terraform_remote_state` only where the manual hand-off becomes a real burden, and expose only the minimum non-sensitive outputs.
- All roots pin the same Terraform and AzureRM provider version constraints. Do not upgrade a major version incidentally.
- Never commit state, plan files or real `.tfvars` values. See the repository root `.gitignore`.
- Bootstrap the state backend before the first root is applied.

## Order of work

See `PLAN.md`. Bootstrap first, then shared services, then regional environments, then the global root that points at them.

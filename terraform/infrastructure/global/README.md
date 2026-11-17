# infrastructure/global

Roots whose resources are global rather than regional: one instance serves every region and environment.

Currently: `front-door/`.

Only add a root here if the resource genuinely cannot be scoped to an environment or a region. Regional resources belong under `../environments/`; shared regional services under `../shared/`.

Global roots tend to be the ones with the widest blast radius and the fewest siblings, so they should change least often. Anything that would make this root re-create production routing needs a reviewed plan and a human decision, not a quick apply.

---
description: Plan and execute PrismSpec build slices with evidence
---

Use `prismspec/skills/prismspec-workflow/SKILL.md` as the controller, then delegate to `prismspec-planning`, `prismspec-implementation`, and `prismspec-debugging` as routed by artifacts.

`/build` is an intent command, not a new workflow stage. It means: get from an approved `spec.md` to completed planned task evidence without skipping review or final verification.

## Behavior

1. Run:

```bash
bash prismspec/bin/guide.sh $ARGUMENTS --json
```

2. If the guide returns `stage: specification`, stop and complete `/spec` first.
3. If the guide returns `stage: planning`, read `prismspec-planning` and write `plan.md`.
4. If the guide returns `stage: implementation`, read `prismspec-implementation` and execute only the next AC-traced slice.
5. If an unexplained failure appears, switch to `prismspec-debugging` before changing code.
6. After the slice, write task evidence and rerun the guide.
7. Stop at `review` unless the user explicitly asked to continue through review and verification.

## Auto Mode

`/build auto` may continue across multiple planned tasks only after the plan has been approved or approval is recorded in `spec.md`.

Auto mode removes human stepping between tasks; it does not remove gates:

- execute one task at a time;
- produce task evidence for each task;
- preserve TDD red/green evidence when `execution_mode: tdd`;
- stop on scope drift, dirty unrelated changes, unexplained failures, missing evidence, review blockers, or risky external actions;
- do not claim completion until `/verify` records fresh command evidence.

## Stop Conditions

- `spec.md` is scaffolded, unapproved, or missing testable ACs.
- `plan.md` is missing when implementation is requested.
- `tdd` work lacks red-test evidence.
- `task-complete` or task evidence lint refuses completion.
- The next action is `review` or `verification` and the user requested build only.

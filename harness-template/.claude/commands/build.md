Plan and execute PrismSpec build slices with evidence.

Execute `prismspec/skills/prismspec-workflow/SKILL.md` as the controller.

## Core behavior

1. Run `bash prismspec/bin/guide.sh $ARGUMENTS --json`.
2. If the stage is `planning`, read `prismspec/skills/prismspec-planning/SKILL.md` and write `plan.md`.
3. If the stage is `implementation`, read `prismspec/skills/prismspec-implementation/SKILL.md` and execute only the next AC-traced slice.
4. If an unexplained failure appears, switch to `prismspec/skills/prismspec-debugging/SKILL.md` before changing code.
5. Write task evidence for every completed slice.
6. Stop at review unless the user explicitly asks to continue through review and verification.

## Auto mode

`/build auto` may continue across multiple planned tasks only after the plan has been approved or approval is recorded in `spec.md`.

Auto mode still stops on scope drift, dirty unrelated changes, unexplained failures, missing evidence, review blockers, or risky external actions. It does not skip review or final verification.

User input: $ARGUMENTS

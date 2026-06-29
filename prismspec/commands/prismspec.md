---
description: Run the PrismSpec AI coding workflow from intent to verified evidence
---

Use `prismspec/skills/workflow/SKILL.md`.

## Behavior

1. Run:

```bash
bash prismspec/bin/guide.sh $ARGUMENTS --json
```

2. Read the `skill` path returned by the guide.
3. Execute that stage until its exit criteria are met.
4. Rerun the guide and continue when the next action is clear.
5. Stop only on verified completion, retry exhaustion, material user decision, or unsafe external action.

## Rules

- Follow Superpowers discipline where it exists: brainstorming/spec approval, writing plans, task review, strict TDD, and verification before completion.
- Use PrismSpec artifact paths: `context.md`, `spec.md`, `plan.md`, task evidence, `review-summary.json`, and `verify.md`.
- Do not skip `review` or `verify`.
- Do not silently downgrade `tdd` to `plan`.
- Do not claim completion without `verify.md` and command-backed evidence.
- Use `/capture` only for durable reusable knowledge after verification.

For artifact checks, run:

```bash
bash prismspec/bin/lint.sh <spec-dir>
```

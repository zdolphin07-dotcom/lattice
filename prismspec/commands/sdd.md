---
description: Run the PrismSpec guided workflow from intent to verified closeout
---

Use `prismspec/skills/sdd/SKILL.md`.

## Behavior

1. Run:

```bash
bash prismspec/bin/guide.sh $ARGUMENTS --json
```

2. Read the `skill` path returned by the guide.
3. Execute that stage until its exit criteria are met.
4. Rerun the guide and continue when the next action is clear.
5. Stop only on completion, retry exhaustion, material user decision, or unsafe external action.

## Rules

- Do not skip `verify`.
- Do not silently downgrade `tdd` to `plan`.
- Do not claim completion without `summary.md` and evidence.
- For artifact checks, run:

```bash
bash prismspec/bin/lint.sh <spec-dir>
```

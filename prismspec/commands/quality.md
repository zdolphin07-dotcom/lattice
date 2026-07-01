---
description: Run the PrismSpec Quality Gate: review first, then command-backed verification
---

Use `prismspec/skills/prismspec-workflow/SKILL.md` as the controller, then delegate to `prismspec-review` and `prismspec-verification`.

Quality Gate is one user-facing action with two evidence artifacts:

- `review.md` judges intent, diff, implementation evidence, test quality, and risk.
- `verify.md` records fresh command-backed verification evidence.

Run:

```bash
bash prismspec/bin/guide.sh $ARGUMENTS --from=review --json
```

If review fails or returns `cannot_verify`, stop and report blockers. If review passes, continue to verification and write `verify.md`.

---
description: Clarify PrismSpec engineering boundaries before formal specification
---

Use `prismspec/skills/prismspec-grilling/SKILL.md`.

Run the guide in specification mode:

```bash
bash prismspec/bin/guide.sh $ARGUMENTS --from=specification --json
```

Create or update a `status: clarifying` `spec.md` draft when the work needs durable recovery. Ask one engineering-boundary question at a time, include a recommended answer, and inspect the repo before asking anything local files can answer.

Do not write `plan.md`, implement code, or advance to `status: drafted`; `/spec` performs the formal specification step after clarification.

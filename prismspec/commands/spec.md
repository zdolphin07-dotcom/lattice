---
description: Create or update PrismSpec spec.md from a requirement
---

Use `prismspec/skills/prismspec-specification/SKILL.md`.

Run the guide with the specification stage:

```bash
bash prismspec/bin/guide.sh $ARGUMENTS --from=specification --json
```

Follow Superpowers brainstorming discipline, then write PrismSpec `spec.md` with Context Basis.

If the requirement is too ambiguous to write a formal spec, enter PrismSpec grilling mode first: use `prismspec/skills/prismspec-grilling/SKILL.md`, ask one engineering-boundary question at a time with a recommended answer, and keep the draft at `status: clarifying` until scope, ACs, execution mode, verification plan, and approval are concrete.

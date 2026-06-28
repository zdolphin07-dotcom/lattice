Capture a durable knowledge entry for the project context layer.

Execute `prismspec/skills/learn/SKILL.md`.

## Core behavior

1. Check existing project knowledge under `lattice/context/knowledge/` and the context map in `lattice/context/README.md`.
2. If the lesson comes from a run summary, prefer `lattice/kernel/context/summary-learn-draft.sh <spec-id>`.
3. Write a reviewable draft under `lattice/context/drafts/` or update the relevant file under `lattice/context/knowledge/`.
4. When governance is required, record review evidence with `knowledge-review.sh` before promotion.

## Knowledge file format

```markdown
---
owner: "project"
verified_at: "YYYY-MM-DD"
applies_to: ["domain-or-rule"]
---

# <One-line title>

**Keywords**: <comma-separated keywords>
**Core rule**: <one-line core conclusion>
**Source**: <date + source>
**Applies when**: <trigger context>
**Guidance**: <practical instruction>
```

## Notes

- Do not duplicate existing knowledge.
- Keep entries concise, sourced, non-secret, and discoverable from the context map.

User input: $ARGUMENTS

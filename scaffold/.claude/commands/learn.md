Capture a knowledge entry to `lattice/knowledge/`.

Execute `prismspec/skills/learn.md` when present; otherwise execute `lattice/skills/learn.md` knowledge capture flow.

## Core behavior

1. Check existing: `lattice/kernel/knowledge/loader.sh --list`
2. Generate knowledge file `lattice/knowledge/<slug>.md` (slug in kebab-case)
3. Update `lattice/knowledge/index.md`

## Knowledge file format

```markdown
# <One-line title>

**Keywords**: <comma-separated keywords>
**Core rule**: <one-line core conclusion>
**Source**: <date + source>
**Context**: <supplementary explanation>
```

## Notes

- Do not duplicate existing knowledge (check index.md first)
- One file per rule, keep it concise

User input: $ARGUMENTS

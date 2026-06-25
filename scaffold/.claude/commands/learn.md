Capture a knowledge entry to `specharness/knowledge/`.

Execute `specharness/skills/learn.md` knowledge capture flow.

## Core behavior

1. Check existing: `specharness/kernel/knowledge/loader.sh --list`
2. Generate knowledge file `specharness/knowledge/<slug>.md` (slug in kebab-case)
3. Update `specharness/knowledge/index.md`

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

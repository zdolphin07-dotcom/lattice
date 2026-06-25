# Skill: learn — Knowledge Capture

**Triggers**: `/learn`, capture, remember

## Capability

Capture discoveries/lessons into the local knowledge base `lattice/knowledge/`.

## Flow

1. Check existing: `lattice/kernel/knowledge/loader.sh --list`
2. Generate knowledge file: `lattice/knowledge/<slug>.md` (slug in kebab-case)
3. Update `lattice/knowledge/index.md`

## Knowledge File Format

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

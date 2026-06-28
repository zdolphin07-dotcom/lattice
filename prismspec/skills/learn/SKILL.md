---
name: prismspec-learn
description: Captures durable project knowledge discovered during PrismSpec work. Use when a run reveals reusable domain rules, decisions, pitfalls, verification lessons, or team conventions that should inform future specs.
---

# PrismSpec Learn

## Overview

Promote only durable lessons into knowledge. Keep one-off implementation details in `summary.md`.

## Inputs

- `summary.md`
- Verification or review findings.
- Existing `lattice/knowledge/` or `prismspec/knowledge/`.

## Workflow

1. Check existing knowledge before writing a new entry.
2. Decide whether the lesson is durable, reusable, and non-secret.
3. Write one concise knowledge entry per rule or pitfall.
4. Include trigger context, rule, source, and practical guidance.
5. Update the knowledge index.

## Knowledge Entry Shape

```markdown
# <Rule or pitfall title>

**Keywords**: <comma-separated keywords>
**Core rule**: <one-line rule>
**Source**: <spec id, date, review/verification source>
**Applies when**: <trigger context>
**Guidance**: <practical instruction>
```

## Outputs

- Knowledge file in `lattice/knowledge/` or `prismspec/knowledge/`.
- Updated `index.md`.

## Stop Conditions

- The lesson contains secrets, private user data, or raw production data.
- The lesson conflicts with existing knowledge.
- The lesson is only relevant to the current implementation detail.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Everything learned should be stored." | Noisy knowledge makes future agents worse. |
| "The summary can act as knowledge." | Summary is per-run; knowledge is reusable. |
| "Draft lessons can skip source." | Unsourced rules become unreviewable folklore. |
| "Secrets are okay if useful." | Secrets never belong in repo knowledge. |

## Red Flags

- Knowledge entry has no source.
- Entry describes what changed rather than what should guide future work.
- Index is not updated.
- One file mixes unrelated rules.

## Verification

- [ ] Existing knowledge was checked.
- [ ] New entry is concise and sourced.
- [ ] Index links the entry.
- [ ] No secrets or raw sensitive data are included.

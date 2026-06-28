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
- Existing `lattice/context/knowledge/`, `lattice/context/drafts/`, or `prismspec/knowledge/`.

## Workflow

1. Check existing knowledge before writing a new entry.
2. Decide whether the lesson is durable, reusable, and non-secret.
3. Write one concise knowledge entry per rule or pitfall.
4. Include trigger context, rule, source, and practical guidance.
5. Update the relevant knowledge file or context map.

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

- Knowledge draft in `lattice/context/drafts/`, promoted project knowledge in `lattice/context/knowledge/`, or standalone `prismspec/knowledge/`.
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
- Relevant knowledge file or context map is not updated.
- One file mixes unrelated rules.

## Verification

- [ ] Existing knowledge was checked.
- [ ] New entry is concise and sourced.
- [ ] Relevant context entry is discoverable from `lattice/context/README.md` or the appropriate knowledge file.
- [ ] No secrets or raw sensitive data are included.

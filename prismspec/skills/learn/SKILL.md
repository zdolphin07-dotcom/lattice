---
name: prismspec-learn
description: Captures durable project knowledge discovered during PrismSpec work. Use when a run reveals reusable domain rules, architecture decisions, pitfalls, verification lessons, context rules, or team conventions that should inform future specs; or when verify.md contains Knowledge Candidates.
---

# PrismSpec Knowledge Capture

## Overview

Promote only durable lessons into knowledge. Keep one-off implementation details in `verify.md` or legacy `summary.md`.

## Inputs

- `verify.md` or `summary.md`
- Verification or review findings.
- Existing `lattice/context/knowledge/`, `lattice/context/drafts/`, or `prismspec/knowledge/`.

## Workflow

1. Check existing knowledge before writing a new entry.
2. In Lattice-hosted mode, convert durable candidates from `verify.md` or legacy `summary.md` with the available learn draft helper.
3. Decide whether the lesson is durable, reusable, and non-secret.
4. Write one concise knowledge entry per rule or pitfall.
5. Include trigger context, rule, source, and practical guidance.
6. If running inside Lattice and promoting a draft, record reviewer evidence when governance is required.
7. Update the relevant knowledge file or context map.
8. If running inside Lattice, run `knowledge-lint.sh` before treating promoted knowledge as clean.

## Knowledge Entry Shape

```markdown
---
owner: "project"
verified_at: "YYYY-MM-DD"
applies_to: ["rule-or-domain"]
expires_at: "YYYY-MM-DD" # optional
---

# <Rule or pitfall title>

**Keywords**: <comma-separated keywords>
**Core rule**: <one-line rule>
**Source**: <spec id, date, review/verification source>
**Applies when**: <trigger context>
**Guidance**: <practical instruction>
```

## Outputs

- Knowledge draft in `lattice/context/drafts/`, promoted project knowledge in `lattice/context/knowledge/`, or standalone `prismspec/knowledge/`.
- Updated project context map or relevant knowledge file.
- Lattice reviewer event from `bash lattice/kernel/context/knowledge-review.sh approve <draft.md> --reviewer=<name> --reason=<reason> --conflicts-checked` when promotion review is required.
- Lattice advisory output from `bash lattice/kernel/context/knowledge-lint.sh --target=<knowledge-file>` when available.

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
- Knowledge file has no owner, verified_at, or applies_to metadata.
- Entry describes what changed rather than what should guide future work.
- Relevant knowledge file or context map is not updated.
- One file mixes unrelated rules.

## Verification

- [ ] Existing knowledge was checked.
- [ ] New entry is concise and sourced.
- [ ] Knowledge metadata has owner, verified_at, and applies_to.
- [ ] Lattice promotion has reviewer evidence when `--require-review` is used.
- [ ] Relevant context entry is discoverable from `lattice/context/README.md` or the appropriate knowledge file.
- [ ] `knowledge-lint.sh` has no unresolved warnings, or warnings are explicitly accepted by a reviewer.
- [ ] No secrets or raw sensitive data are included.

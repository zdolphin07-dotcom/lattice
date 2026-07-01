---
name: prismspec-context-engineering
description: Selects the minimum task-relevant project context for PrismSpec work and records it as Context Basis facts. Use when requirements depend on project knowledge, historical decisions, domain rules, hidden constraints, or when the agent is about to load broad documentation or code without a clear context target.
---

# PrismSpec Context Engineering

## Overview

Load the right context, not the most context. This support skill turns project knowledge, code, tests, schemas, prior specs, and external maps into selected facts that can change scope, ACs, risk, mode, or verification.

Context output belongs in `spec.md#Context Basis` or the task brief. Do not create a parallel context artifact unless the host already provides one.

## Inputs

- User requirement, current `spec.md`, or task brief.
- `lattice/context/README.md` and related project knowledge when running in Lattice-hosted mode.
- Relevant code, tests, schemas, contracts, prior specs, and docs.
- External references only when local facts are insufficient or time-sensitive.

## Workflow

1. State the decision that context must support: scope, AC, interface, invariant, mode, risk, or verification.
2. Read the context map first when present; do not start by bulk-loading docs.
3. Search for the smallest set of sources that can answer the decision.
4. Classify each candidate as adopted fact, excluded fact, conflict, assumption, or open question.
5. Record only selected facts with source categories and why they matter.
6. If facts conflict, stop before planning or implementation unless a safe default exists and is recorded.
7. If context is missing but the task is low risk, record the assumption and verification path.
8. If context is missing for high-risk behavior, escalate instead of guessing.

## Outputs

- `spec.md#Context Basis` entries: selected facts, constraints, conflicts, assumptions, open questions, and source categories.
- Task brief context section when implementation needs a local reminder.
- Optional knowledge search terms or follow-up context gaps.

## Stop Conditions

- Required domain, data, security, or compatibility facts are missing.
- Two trusted sources conflict and the choice changes behavior.
- Context discovery requires secrets, production data, or private material outside the project boundary.
- The agent is about to copy large docs into `spec.md` instead of selecting facts.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I should read the whole repo first." | Context engineering is decision-targeted; bulk loading dilutes attention. |
| "The wiki says enough." | Wiki facts must be mapped to the current code, tests, contracts, or owner when they affect behavior. |
| "I can keep context in the chat." | Future agents recover from `spec.md` and task briefs, not this conversation. |
| "More context is safer." | Irrelevant context hides the few constraints that matter. |
| "Conflicts can be resolved during implementation." | Conflicting facts change scope and risk; resolve or record before coding. |

## Red Flags

- Context Basis contains pasted long docs instead of selected facts.
- A high-risk assumption has no source or verification path.
- The spec mentions project constraints but does not cite where they came from.
- Historical specs or project knowledge are ignored for a similar change.
- Open questions are hidden in prose and not visible as blockers.

## Verification

- [ ] The context decision target is explicit.
- [ ] Context Basis records selected facts, exclusions/conflicts, assumptions, or explicit N/A.
- [ ] Each adopted fact has a source category and explains why it affects this spec.
- [ ] Conflicts or blockers are resolved, escalated, or recorded before planning.
- [ ] No secrets, raw production data, or bulk copied docs are included.

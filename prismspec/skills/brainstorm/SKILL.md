---
name: prismspec-brainstorm
description: Turns vague or new requirements into a durable PrismSpec spec.md. Use when starting a feature, project, bug fix, or significant change without an approved spec, or when /sdd routes to the brainstorm stage.
---

# PrismSpec Brainstorm

## Overview

Clarify just enough to write `context.md` and `spec.md`: intent, scope, acceptance criteria, context basis, risks, execution mode, and verification plan.

## Inputs

- User requirement or continuation request.
- `lattice/manifest.yaml` when present.
- Relevant code, tests, schemas, contracts, docs, and matched context knowledge only when they affect scope, AC, risk, or mode.
- Template from `prismspec/templates/`.

Read `prismspec/references/spec-quality-checklist.md` when drafting a full spec. Read `prismspec/references/mode-selection.md` when the mode is non-obvious.

## Workflow

1. Detect host paths with `prismspec/bin/guide.sh --json`.
2. Choose the smallest fitting template:
   - `spec-template-lite.md` for low-risk plan work.
   - `spec-template-service.md` for APIs, data, state, idempotency, compensation.
   - `spec-template-frontend.md` for UX, component states, accessibility.
   - `spec-template-tdd.md` for bugs, regressions, and high-risk behavior.
   - `spec-template.md` when no specialized template clearly fits.
3. Perform Context Discovery. Load only context that changes scope, AC, risk, interface, compatibility, or verification.
   - In Lattice-hosted mode, read `lattice/context/README.md` when present.
   - Follow the context map to relevant project knowledge, external references, historical specs, code, tests, schemas, and contracts.
   - Use `lattice/kernel/context/backends/knowledge.sh <keywords>` only as an optional curated-knowledge backend.
   - Write selected facts, constraints, conflicts, exclusions, and open questions to `context.md`.
4. Surface assumptions before writing irreversible decisions.
5. Ask only material questions. Do not interview for details the model can safely infer from local code.
6. Write `spec.md` in the target spec directory.
7. Record `execution_mode`, reason, and source.

## Outputs

- `context.md` with selected knowledge, code facts, conflicts, and open questions.
- `spec.md` with stable `AC-{n}` identifiers.
- Open questions only when they block planning or safe implementation.

## Stop Conditions

- Acceptance criteria cannot be made testable.
- The user request conflicts with existing contracts or knowledge.
- High-risk behavior exists but the user rejects TDD without accepting the tradeoff.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I will fill the spec after coding." | That is documentation, not specification. |
| "I should read the whole repo first." | Brainstorming needs bounded context, not full implementation detail. |
| "The default template is always fine." | Different risk shapes need different spec emphasis. |
| "Mode can be decided during coding." | Mode affects the plan and evidence requirements. |

## Red Flags

- ACs use vague words such as "fast", "nice", "good", or "works" without measurable meaning.
- Spec copies large context-knowledge sections instead of referencing the relevant rule or `context.md`.
- Scope includes implementation tasks that belong in `plan.md`.
- TDD-worthy work is marked `plan` without rationale.

## Verification

- [ ] `context.md` exists in the routed spec directory.
- [ ] `spec.md` exists in the routed spec directory.
- [ ] AC identifiers are stable and testable.
- [ ] Execution policy is recorded.
- [ ] Verification plan names concrete commands or gates.

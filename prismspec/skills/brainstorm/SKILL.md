---
name: prismspec-brainstorm
description: Turns vague or new requirements into durable PrismSpec context.md and spec.md artifacts. Use when starting a feature, bug fix, product change, refactor, or project without an approved spec; when acceptance criteria, scope, risk, context basis, or execution mode are unclear; or when /sdd routes to brainstorm.
---

# PrismSpec Brainstorm

## Overview

Clarify just enough to write `context.md` and `spec.md`: intent, scope, acceptance criteria, context basis, risks, execution mode, and verification plan.

## Inputs

- User requirement or continuation request.
- `lattice/manifest.yaml` when present.
- Relevant code, tests, schemas, contracts, docs, and matched context knowledge only when they affect scope, AC, risk, or mode.
- Template from `prismspec/templates/`.
- Context template from `prismspec/templates/context-template.md`.

Read `prismspec/references/spec-quality-checklist.md` when drafting a full spec. Read `prismspec/references/mode-selection.md` when the mode is non-obvious.

## Workflow

1. Detect host paths with `prismspec/bin/guide.sh --json`.
2. Choose the smallest fitting template:
   - `spec-template-lite.md` for low-risk plan work.
   - `spec-template-service.md` for APIs, data, state, idempotency, compensation.
   - `spec-template-frontend.md` for UX, component states, accessibility.
   - `spec-template-tdd.md` for bugs, regressions, and high-risk behavior.
   - `spec-template.md` when no specialized template clearly fits.
3. When `context.md` or `spec.md` does not exist yet, use `prismspec/bin/new.sh <spec-id> --template=<kind> --mode=<mode>` to create the initial directory and files, then fill them with real content.
4. If `spec.md` contains `scaffolded: true`, treat it as an unfinished template. Replace placeholders, fill `context.md`, and set `scaffolded: false` only after scope, ACs, risk, and mode are concrete enough for planning.
5. Perform Context Discovery with `prismspec/templates/context-template.md`. Load only context that changes scope, AC, risk, interface, compatibility, or verification.
   - In Lattice-hosted mode, read `lattice/context/README.md` when present.
   - Follow the context map to relevant project knowledge, external references, historical specs, code, tests, schemas, and contracts.
   - Use `lattice/kernel/context/backends/knowledge.sh <keywords>` only as an optional curated-knowledge backend.
   - Write selected facts, constraints, conflicts, exclusions, and open questions to `context.md`.
6. In Lattice-hosted mode, run `lattice/kernel/context/context-lint.sh <spec-id>` after `context.md` is written. Use `--strict` only when planning should be blocked by unresolved context gaps.
7. In Lattice-hosted mode, run `lattice/kernel/context/context-run.sh <spec-id> --strict` after `context.md` passes lint and has no blocking gaps.
8. Surface assumptions before writing irreversible decisions.
9. Ask only material questions. Do not interview for details the model can safely infer from local code.
10. Write `spec.md` in the target spec directory.
11. Record `execution_mode`, reason, and source.
12. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/spec-state-lint.sh <spec-id>` before leaving brainstorming.

## Outputs

- `context.md` with selected knowledge, code facts, conflicts, and open questions.
- `spec.md` with stable `AC-{n}` identifiers.
- Optional Lattice context-run JSON under `lattice/state/context-runs/`.
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
- [ ] Lattice context-lint passes when running in Lattice-hosted mode.
- [ ] Lattice context-run evidence exists when running in Lattice-hosted mode and no blocking context gaps remain.
- [ ] `spec.md` exists in the routed spec directory.
- [ ] Lattice spec-state-lint passes when running in Lattice-hosted mode.
- [ ] AC identifiers are stable and testable.
- [ ] Execution policy is recorded.
- [ ] Verification plan names concrete commands or gates.

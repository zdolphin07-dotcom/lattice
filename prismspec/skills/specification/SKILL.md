---
name: prismspec-specification
description: Turns vague or new requirements into durable PrismSpec context.md and spec.md artifacts. Use when starting a feature, bug fix, product change, refactor, or project without an approved spec; when acceptance criteria, scope, risk, context basis, or execution mode are unclear; or when /prismspec routes to specification.
---

# PrismSpec Specification

## Overview

Clarify just enough to write `context.md` and `spec.md`: intent, scope, acceptance criteria, context basis, risks, execution mode, and verification plan.

PrismSpec specification aligns with Superpowers `brainstorming`: explore context, ask one material question at a time, compare viable approaches, present a design, and get approval before planning or implementation. PrismSpec differs only in the artifact contract: the approved design is written to `context.md` and `spec.md`, not to `docs/superpowers/specs/`.

<HARD-GATE>
Do not plan, implement, scaffold, or modify production code until a non-scaffolded `spec.md` exists and the design is approved or the approval status is explicitly recorded with a reason.
</HARD-GATE>

## Inputs

- User requirement or continuation request.
- `lattice/manifest.yaml` when present.
- Relevant code, tests, schemas, contracts, docs, and matched context knowledge only when they affect scope, AC, risk, or mode.
- Template from `prismspec/templates/`.
- Context template from `prismspec/templates/context-template.md`.

Read `prismspec/references/superpowers-alignment.md` before changing the workflow shape. Read `prismspec/references/spec-quality-checklist.md` when drafting a full spec. Read `prismspec/references/mode-selection.md` when the mode is non-obvious.

## Workflow

1. Detect host paths with `prismspec/bin/guide.sh --json`.
2. Explore project context first: files, docs, recent changes, existing specs, and relevant project knowledge. Do not read the whole repo; read enough to understand scope and constraints.
3. If the request spans multiple independent subsystems, decompose it into separate specs and continue with the first spec only after the boundary is clear.
4. Ask one material question at a time. Prefer multiple-choice when it reduces friction, but do not interview for details the model can safely infer from local code.
5. When design choices matter, present 2-3 approaches with tradeoffs and a recommendation. For tiny low-risk changes, the design may be short, but the chosen behavior still needs explicit scope and ACs.
6. Choose the smallest fitting template:
   - `spec-template-lite.md` for low-risk plan work.
   - `spec-template-service.md` for APIs, data, state, idempotency, compensation.
   - `spec-template-frontend.md` for UX, component states, accessibility.
   - `spec-template-tdd.md` for bugs, regressions, and high-risk behavior.
   - `spec-template.md` when no specialized template clearly fits.
7. When `context.md` or `spec.md` does not exist yet, use `prismspec/bin/new.sh <spec-id> --template=<kind> --mode=<mode>` to create the initial directory and files, then fill them with real content.
8. If `spec.md` contains `scaffolded: true`, treat it as an unfinished template. Replace placeholders, fill `context.md`, and set `scaffolded: false` only after scope, ACs, risk, and mode are concrete enough for planning.
9. Perform Context Discovery with `prismspec/templates/context-template.md`. Load only context that changes scope, AC, risk, interface, compatibility, or verification.
   - In Lattice-hosted mode, read `lattice/context/README.md` when present.
   - Follow the context map to relevant project knowledge, external references, historical specs, code, tests, schemas, and contracts.
   - Use `lattice/kernel/context/backends/knowledge.sh <keywords>` only as an optional curated-knowledge backend.
   - Write selected facts, constraints, conflicts, exclusions, and open questions to `context.md`.
10. In Lattice-hosted mode, run `lattice/kernel/context/context-lint.sh <spec-id>` after `context.md` is written. Use `--strict` only when planning should be blocked by unresolved context gaps.
11. In Lattice-hosted mode, run `lattice/kernel/context/context-run.sh <spec-id> --strict` after `context.md` passes lint and has no blocking gaps.
12. Surface assumptions before writing irreversible decisions.
13. Present the selected design in readable sections scaled to complexity: intent, scope, approach, contract surface, risks, execution mode, and verification.
14. Get user approval for the design before planning. If approval is inferred from an explicit user instruction to proceed, record that in `spec.md`; if approval is skipped, record the reason and risk.
15. Write `spec.md` in the target spec directory.
16. Record `execution_mode`, reason, source, and approval status.
17. Self-review `context.md` and `spec.md` for placeholders, contradictions, ambiguity, scope creep, untestable ACs, missing mode, and missing verification.
18. If approval was not explicit, ask the user to review the written `spec.md` before planning.
19. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/spec-state-lint.sh <spec-id>` before leaving specification.

## Outputs

- `context.md` with selected knowledge, code facts, conflicts, and open questions.
- `spec.md` with stable `AC-{n}` identifiers, execution policy, and approval status.
- Optional Lattice context-run JSON under `lattice/state/context-runs/`.
- Open questions only when they block planning or safe implementation.

## Stop Conditions

- Acceptance criteria cannot be made testable.
- The user request conflicts with existing contracts or knowledge.
- High-risk behavior exists but the user rejects TDD without accepting the tradeoff.
- The design needs a user decision and no safe default exists.
- The request is too broad for one spec and the boundary cannot be decomposed.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I will fill the spec after coding." | That is documentation, not specification. |
| "I should read the whole repo first." | Brainstorming needs bounded context, not full implementation detail. |
| "The default template is always fine." | Different risk shapes need different spec emphasis. |
| "Mode can be decided during coding." | Mode affects the plan and evidence requirements. |
| "This is too simple to need approval." | Simple designs can be short, but implementation still needs an approved or explicitly recorded contract. |
| "Superpowers writes design docs, so PrismSpec should too." | PrismSpec writes the same approved design into `context.md` and `spec.md` to preserve one artifact contract. |

## Red Flags

- ACs use vague words such as "fast", "nice", "good", or "works" without measurable meaning.
- Spec copies large context-knowledge sections instead of referencing the relevant rule or `context.md`.
- Scope includes implementation tasks that belong in `plan.md`.
- TDD-worthy work is marked `plan` without rationale.
- Planning starts before design approval or recorded approval status.
- A non-trivial design choice has no alternatives/tradeoff rationale.
- One spec covers independent subsystems that should be separate specs.

## Verification

- [ ] `context.md` exists in the routed spec directory.
- [ ] Lattice context-lint passes when running in Lattice-hosted mode.
- [ ] Lattice context-run evidence exists when running in Lattice-hosted mode and no blocking context gaps remain.
- [ ] `spec.md` exists in the routed spec directory.
- [ ] Design approval is explicit or recorded with reason.
- [ ] Non-trivial approach tradeoffs are captured or intentionally skipped as low-risk.
- [ ] Lattice spec-state-lint passes when running in Lattice-hosted mode.
- [ ] AC identifiers are stable and testable.
- [ ] Execution policy is recorded.
- [ ] Verification plan names concrete commands or gates.

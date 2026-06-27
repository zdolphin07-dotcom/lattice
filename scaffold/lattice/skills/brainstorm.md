# Skill: brainstorm — Spec Brainstorming

**Triggers**: `/brainstorm`, brainstorm, clarify requirement, draft spec

## Capability

Turn a user intent into a persistent, reviewable Lattice spec. This is the first required stage of the Lattice AI Coding workflow.

Brainstorming is not casual discussion. It is a focused requirement and constraint convergence step whose only durable output is:

```text
lattice/specs/<spec-id>/spec.md
```

## Non-goals

- Do not implement code in this skill.
- Do not create a full technical essay when a compact spec is enough.
- Do not lock low-level implementation details unless they are one-way decisions.
- Do not skip knowledge loading for non-trivial changes.

## Required Context

Before writing `spec.md`:

1. Read `lattice/manifest.yaml`.
   - Use `specs.template` as the template path; projects may override it.
   - Use `specs.default_execution_mode` as the mode policy: `auto`, `plan`, or `tdd`.
   - If `prismspec/templates/` exists, choose the smallest fitting PrismSpec template before falling back to `specs.template`.
2. Inspect the relevant code/tests/schema/API contracts.
3. Run targeted knowledge retrieval:

```bash
bash lattice/kernel/knowledge/loader.sh <requirement keywords>
```

4. Ask only clarification questions that materially affect scope, acceptance, risk, or execution mode.

## Workflow

1. Identify intent: what problem is being solved and why.
2. Define scope: explicit in-scope and out-of-scope boundaries.
3. Load context: include only matched rules, decisions, pitfalls, and constraints needed for this task.
4. Define acceptance criteria: concrete, testable, numbered as `AC-{n}`.
5. Record design decisions: only one-way decisions that need human review.
6. Choose execution mode:
   - If the user explicitly specifies a mode for this spec, use it and record `Source: user-override`.
   - Else if `specs.default_execution_mode` is `plan` or `tdd`, use it and record `Source: project-default`.
   - Else choose intelligently and record `Source: model-selected`.
   - `plan`: normal implementation after plan review.
   - `tdd`: red-test-first implementation for bug fixes, core flows, money/security/permission/state-machine logic, concurrency, idempotency, or regression-prone behavior.
7. Write `lattice/specs/<spec-id>/spec.md`.

Template selection:

- `spec-template-lite.md`: low-risk Plan Mode work, docs, config, simple refactors.
- `spec-template-service.md`: backend API, data model, state transition, permission, idempotency, compensation.
- `spec-template-frontend.md`: UI flow, component behavior, user-facing interaction, accessibility, visual states.
- `spec-template-tdd.md`: bug fix, regression, core flow, security, permission, money, concurrency, idempotency.
- `spec-template.md`: default when no specialized template clearly fits.

If `plan` is selected and later planning/implementation discovers blocking risk, upgrade the spec to `tdd` before continuing. Do not silently downgrade `tdd` to `plan`; ask or record a user override.

## Output Format

```markdown
---
id: <spec-id>
status: drafted
execution_mode: plan | tdd
owner: <owner>
created_at: <timestamp>
updated_at: <timestamp>
---

# Spec: <title>

## Intent

## Scope

### In

### Out

## Context

## Acceptance Criteria

| # | When | Then | Verification |
|---|------|------|--------------|
| AC-1 | | | |

## Design Decisions

## Risk Notes

## Execution Policy

- Mode: plan | tdd
- Reason:
- Source: model-selected | project-default | user-override

## Verification Plan
```

## Exit Criteria

The spec is ready for planning only when:

- intent is clear;
- scope has explicit in/out boundaries;
- acceptance criteria are testable;
- required context is cited or summarized;
- design decisions are limited to one-way choices;
- `execution_mode` is set to `plan` or `tdd`.
- the mode source is recorded in `Execution Policy`.

User input: $ARGUMENTS

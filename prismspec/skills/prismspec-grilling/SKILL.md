---
name: prismspec-grilling
description: Clarifies engineering boundaries for vague PrismSpec work before a formal spec is drafted. Use when a request is too ambiguous to write spec.md safely, when /clarify is invoked, or when /spec needs one-question-at-a-time grilling before specification.
---

# PrismSpec Grilling

## Overview

Clarify engineering boundaries before writing a formal `spec.md`. This is the high-pressure Clarify mode inside PrismSpec: ask one material question at a time, give a recommended answer, inspect the repo before asking anything the code can answer, and preserve resolved facts in the current spec draft.

Grilling is not a new workflow stage. It belongs to Clarify and routes through the existing specification stage.

## Inputs

- User intent, rough change request, or `/clarify` arguments.
- `bash prismspec/bin/guide.sh --from=specification --json` output.
- Current `spec.md` when present, especially `status: clarifying` drafts.
- Relevant code, commands, templates, docs, prior specs, and project knowledge that affect scope, contracts, risks, or verification.
- `prismspec/skills/prismspec-specification/SKILL.md` when the draft is ready to become a formal spec.

## Workflow

1. Run `bash prismspec/bin/guide.sh $ARGUMENTS --from=specification --json` to resolve host, spec root, spec id, and current artifact state.
2. If no spec exists and the user intent is concrete enough to name, create a spec draft using `prismspec/bin/new.sh`, then set front matter to `status: clarifying` and keep `scaffolded: true`.
3. Inspect local files before asking questions that the repo can answer. Check existing commands, templates, scripts, contracts, and nearby docs when they affect the engineering boundary.
4. Focus questions on engineering boundaries first:
   - touched modules, commands, skills, templates, docs, scripts, gates, or adapters;
   - artifact contract changes;
   - router, lint, status, CI, or pipeline changes;
   - compatibility with existing specs and installed harnesses;
   - files or behaviors that must not change;
   - verification evidence that proves the boundary did not drift.
5. Ask exactly one material question at a time. Include a recommended answer and the tradeoff behind it.
6. Record resolved facts in `spec.md` instead of leaving them only in chat:
   - adopted facts and constraints go to Context Basis;
   - resolved choices go to scope, non-goals, contract surface, or execution policy notes;
   - unresolved blockers go to open questions or conflicts;
   - testable behavior becomes candidate ACs only when specific enough.
7. Stop when the next missing decision is genuinely a user choice, or when the draft is ready for `prismspec-specification` to turn it into `status: drafted`.

## Outputs

- A `spec.md` draft with `status: clarifying` when the work is not yet a formal spec.
- Updated Context Basis, open questions, resolved engineering decisions, and candidate ACs where available.
- One pending question with a recommended answer when user input is required.
- No `plan.md`, implementation, review, or verification artifacts.

## Stop Conditions

- The next decision changes scope, compatibility, workflow state, data, permissions, or verification and has no safe default.
- A local fact conflicts with the user request and the conflict changes the engineering boundary.
- The request is too broad for one spec and cannot be decomposed without user choice.
- The draft is ready for formal specification; switch to `prismspec-specification` instead of continuing to interview.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I can ask five questions at once." | Multiple questions blur priority and make decisions hard to recover. Ask one material question. |
| "The user can tell me which files are affected." | If the repo can answer it, inspect the repo first. Ask only for choices the code cannot make. |
| "A separate grilling document is clearer." | The durable recovery surface is `spec.md`; avoid a second source of truth by default. |
| "I should write final ACs now." | Candidate ACs are fine, but formal ACs belong in `status: drafted` after unresolved questions close. |

## Red Flags

- Questions are product-generic while engineering boundaries remain unknown.
- Chat contains resolved constraints that are not reflected in `spec.md`.
- `status: drafted` is set before execution mode, verification plan, and approval are concrete.
- The agent asks about file layout, commands, tests, or templates without checking the repo.
- Grilling drifts into planning or implementation.

## Verification

- [ ] Exactly one user-facing question is asked when input is needed.
- [ ] Each question includes a recommended answer.
- [ ] Repo-observable facts are inspected before asking the user.
- [ ] `status: clarifying` drafts keep unresolved questions visible.
- [ ] No planning or implementation artifacts are produced by grilling.

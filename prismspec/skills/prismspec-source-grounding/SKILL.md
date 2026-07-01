---
name: prismspec-source-grounding
description: Grounds external API, SDK, platform, model, library, and standard claims in current authoritative sources before PrismSpec decisions or implementation. Use when work depends on external products, changing APIs, framework behavior, cloud services, model capabilities, regulations, or any fact likely to be stale.
---

# PrismSpec Source Grounding

## Overview

Prevent stale or hallucinated external facts from entering a spec or implementation. Source grounding distinguishes observed facts from model inference and records only the facts needed for the current PrismSpec decision.

Prefer primary sources: official docs, source repositories, standards, release notes, or code in the installed dependency.

## Inputs

- The external claim or decision to verify.
- Current `spec.md`, `plan.md`, or task brief.
- Local dependency files when installed.
- Official documentation or primary sources when facts may have changed.

## Workflow

1. Name the claim that must be grounded.
2. Decide whether local repo facts are enough; if not, use current primary sources.
3. Capture the source, date observed, version, and the exact fact adopted.
4. Separate observed facts from inference or recommendation.
5. Record the impact on scope, interface, AC, mode, risk, or verification.
6. If sources conflict, prefer the current primary source and record the conflict.
7. If no source can confirm the claim, mark it unverified and avoid hardcoding it into the contract.

## Outputs

- Source-grounded fact in `spec.md#Context Basis`, task brief, or `verify.md` residual risk.
- Source URL/path, version/date observed, and adopted fact.
- Explicit unverified claim or conflict when grounding fails.

## Stop Conditions

- The claim affects high-risk behavior and cannot be verified.
- Sources conflict and no safe default exists.
- The only available source is outdated, third-party, or unrelated to the installed version.
- External verification requires credentials, paid access, or private data.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know this API from memory." | External APIs and models change; memory is not evidence. |
| "A blog post says it works." | Use official docs, source code, release notes, or installed dependency behavior first. |
| "The exact version probably does not matter." | Version drift is a common cause of broken generated code. |
| "I can cite the source later." | Source grounding must happen before the claim becomes a contract. |
| "The source is too long." | Extract only the fact that changes the current decision. |

## Red Flags

- Spec uses external API names without version or source.
- Implementation imports APIs not present in installed dependencies.
- Verification relies on behavior not documented or tested locally.
- A recommendation is presented as an observed fact.
- Current-date, pricing, model, legal, or platform claims are made without checking.

## Verification

- [ ] Every external claim that affects behavior has a source or is marked unverified.
- [ ] Adopted facts include source, version/date observed, and impact.
- [ ] Inferences are labeled separately from observed facts.
- [ ] Conflicts are recorded with the selected source and rationale.
- [ ] Unverified high-risk claims block planning or implementation.

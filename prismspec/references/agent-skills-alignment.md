# Agent Skills Alignment

PrismSpec treats Agent Skills as the packaging and quality standard for reusable agent capabilities. It treats Superpowers as the workflow discipline standard for AI coding.

## Alignment Rule

- Use Superpowers for proven AI coding workflow behavior.
- Use Agent Skills for skill naming, folder shape, trigger descriptions, progressive disclosure, bundled resources, and evals.
- Keep PrismSpec-specific value in durable artifacts, AC traceability, host-aware routing, evidence, and Lattice gates.

## Packaging Contract

Each PrismSpec skill is a standalone Agent Skills-compatible folder:

```text
prismspec/skills/prismspec-planning/
├── SKILL.md
├── agents/openai.yaml
└── evals/evals.json
```

Rules:

- Folder name matches frontmatter `name`.
- `SKILL.md` contains only the minimum workflow needed after the skill triggers.
- Frontmatter contains only `name` and `description`.
- `description` states what the skill does and when to use it.
- `agents/openai.yaml` is UI metadata, not workflow logic.
- `evals/evals.json` records should-trigger, should-not-trigger, and behavior assertions.
- Shared detailed guidance lives in `prismspec/references/`; deterministic helpers live in `prismspec/bin/` or Lattice kernel scripts.

## Product Block Contract

PrismSpec exposes four primary product blocks for host UIs and release planning:

```text
Clarify -> Spec -> Build -> Quality Gate
```

These are product surfaces, not necessarily one skill folder each. `skillpack.yaml` maps each block to the underlying Agent Skills-compatible folders and evidence gates:

- Clarify uses `prismspec-grilling` with `prismspec-specification`: Clarify focuses on engineering boundaries, context facts, assumptions, conflicts, and blocking questions; Spec focuses on approved scope, ACs, risk, mode, and verification plan.
- Clarify records its result in a `status: clarifying` `spec.md` and Context Basis rather than a separate required artifact, matching Agent Skills' preference for small, self-contained task outputs.
- Build composes `prismspec-planning`, `prismspec-implementation`, and `prismspec-debugging`; it risk-loads support skills such as context engineering, source grounding, doubt review, and interface design only when needed.
- Quality Gate composes `prismspec-review` and `prismspec-verification`: review inspects intent, diff, evidence, and risk before verification; verification proves the current repository state with fresh commands and Lattice delivery gates.

Host integrations should present the product blocks to users, then route through `prismspec/bin/guide.sh --json` and the canonical skill paths declared in `skillpack.yaml`.

The product block artifacts are the human-readable contract. Quality Gate still produces two artifacts, `review.md` and `verify.md`, because they answer different questions. Machine/process sidecars such as `review-summary.json`, `review-package.md`, task briefs, TDD/debug evidence, and eval run JSON can be collected by hosts, but they should not be promoted into separate user-facing stages.

## Commercial Release Bar

A PrismSpec skill is publishable only when:

1. Its trigger description is specific enough to avoid stage collisions.
2. Its body is under 500 lines and follows progressive disclosure.
3. It has explicit inputs, workflow, outputs, stop conditions, and verification.
4. It has evals for true positives, false positives, and behavior assertions.
5. It produces or validates a durable artifact.
6. It can fail closed without guessing, weakening tests, or skipping evidence.
7. It can be discovered from metadata alone, then safely activated with only the selected `SKILL.md` and referenced resources.

## What PrismSpec Does Not Copy

Agent Skills is not a full SDD workflow. PrismSpec does not copy arbitrary skill names from Agent Skills examples. It uses Agent Skills to make each workflow stage portable and inspectable. The user-facing model is:

```text
specification -> planning -> implementation(plan|tdd) -> quality gate
```

Internally, Quality Gate remains two stages so evidence stays auditable:

```text
review -> verification
```

Support skills such as `prismspec-debugging`, `prismspec-knowledge-capture`, `prismspec-context-engineering`, `prismspec-source-grounding`, `prismspec-doubt-review`, and `prismspec-interface-design` are invoked only when the main flow needs their specific discipline.

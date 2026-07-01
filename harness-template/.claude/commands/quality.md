Run the PrismSpec Quality Gate: review first, then command-backed verification.

Execute `prismspec/commands/quality.md`.

Quality Gate is one user-facing action with two evidence artifacts:

- `review.md` for read-only quality verdicts.
- `verify.md` for fresh command-backed verification evidence.

Stop if review fails or returns `cannot_verify`. Continue to verification only after review passes.

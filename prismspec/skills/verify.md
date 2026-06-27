# Skill: verify — PrismSpec Verification

**Triggers**: `/verify`, verify, run checks, run pipeline

## Capability

Run independent verification and write durable evidence.

## Workflow

1. If Lattice exists, run:

```bash
bash lattice/kernel/delivery/pipeline.sh
```

2. Otherwise detect and run the smallest meaningful local command set:
   - Node: `npm run build` when present, `npm run lint` when present, `npm test` when present.
   - Python: `ruff check .` when present, `pytest` when present.
   - Go: `go test ./...`.
   - Rust: `cargo test`.
3. Capture results in `verify.md` next to `spec.md`.
4. On failure, fix and re-run within the retry budget. Escalate only when blocked by missing user input or external state.

## Exit Criteria

- Verification commands and outcomes are recorded.
- Passing evidence exists, or failures are clearly escalated with concrete next steps.

# Layer 2: Context

The context layer supplies reliable project context to AI agents. The primary entry is `lattice/context/README.md`, not a shell command.

## Agent Flow

1. Read `lattice/context/README.md`.
2. Follow its context map to relevant project knowledge, external references, code, tests, schema, and historical specs.
3. Select only facts that affect scope, ACs, risk, interface, compatibility, or verification.
4. Write the selected basis to `lattice/specs/<spec-id>/context.md`.
5. Write `spec.md` from that context basis.

## Directory Contract

```text
lattice/context/
  README.md                    # Agent-readable context map
  external.md                  # External and central knowledge entry point
  knowledge/
    architecture.md
    rules.md
    pitfalls.md
    glossary.md
    decisions/
  drafts/                      # Candidate lessons before review
  sources.yaml                 # Optional machine-readable source policy
lattice/specs/<spec-id>/
  context.md                   # Per-spec context basis
```

## Optional Tooling

```bash
# Search curated project knowledge as a retrieval backend
lattice/kernel/context/backends/knowledge.sh auth rate-limit idempotency

# Compatibility wrapper for older docs/scripts
lattice/kernel/context/loader.sh auth rate-limit idempotency

# Sync optional central context knowledge cache
lattice/kernel/context/sync.sh pull
lattice/kernel/context/sync.sh push
lattice/kernel/context/sync.sh status
```

Shell scripts are deterministic helpers. They do not replace agent-led Context Discovery.

## Manifest

```yaml
kernel:
  layers:
    context: true

context:
  root: lattice/context
  map_file: lattice/context/README.md
  external_file: lattice/context/external.md
  sources_file: lattice/context/sources.yaml
  knowledge:
    dir: lattice/context/knowledge
    drafts_dir: lattice/context/drafts
  central:
    repo: ""
    cache_dir: lattice/context/.central
    mode: read-only
    conflict: project-wins
```

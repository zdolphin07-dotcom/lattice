# /init — Lattice Project Initialization

## Trigger

User says "initialize Lattice", "/init", or project root has no `lattice/manifest.yaml`.

## Flow

1. **Check existing state**: if `lattice/manifest.yaml` exists, ask to overwrite
2. **Collect project info**: language, framework, ORM, database
3. **Generate manifest.yaml**: based on answers
4. **Inject CLAUDE.md**: append `@import lattice/kernel/orchestrator/rules.md`
5. **Create directory structure**: specs/, plans/, knowledge/, requirements/
6. **Verify**: run `bash lattice/kernel/delivery/pipeline.sh --skip-spec --skip-integration`

## Output

- `lattice/manifest.yaml` — Project declaration
- `CLAUDE.md` — With @import
- Empty directory structure

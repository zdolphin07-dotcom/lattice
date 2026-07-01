# Cursor Adapter

Lattice works with [Cursor](https://cursor.com) in two layers:

1. A lightweight rules-file adapter that works today.
2. A future thin Cursor control plane that should discover Lattice runtime capabilities instead of hard-coding workflow details.

## Setup

1. Install Lattice into your project:

```bash
bash install.sh /path/to/your-project --init
```

2. Create `.cursor/rules` (or `.cursorrules`) and import Lattice rules:

```
# Include Lattice behavior rules
@file lattice/kernel/orchestrator/rules.md
```

3. Cursor will now follow Lattice phase rules when generating code.

4. Check the runtime capability declaration:

```bash
bash lattice/kernel/capabilities.sh --json
```

Adapters, MCP servers, and IDE plugins should treat this JSON as the discovery entry point for stages, tools, actions, gates, metrics, and reports.

## Usage

Cursor doesn't have a slash-command system like Claude Code, so invoke skills manually:

```
# In Cursor chat:
"Run bash lattice/kernel/delivery/pipeline.sh"
"Read lattice/context/README.md, then run bash lattice/kernel/context/backends/knowledge.sh <keywords> only if curated knowledge lookup is useful"
"Run bash lattice/kernel/delivery/gates/spec-lint.sh lattice/specs/my-spec/spec.md"
```

## Control Plane Contract

A Cursor plugin should stay thin. It should render a stable UI shell and delegate workflow details to the repo-local Lattice runtime:

| Concern | Owner |
|---------|-------|
| Status bar, sidebar, command palette, MCP registration | Cursor plugin |
| Workflow routing, gates, metrics, reports, policies | Lattice runtime |
| Capability, action, metric, and report schemas | Versioned Lattice protocol |
| Specs, context, eval runs, outcomes | Target project |

The stable adapter calls are:

- `capabilities()` -> `bash lattice/kernel/capabilities.sh --json`
- `guide()` -> `bash prismspec/bin/guide.sh --json`
- `execute_action(action_id, inputs)` -> adapter wrapper around runtime tools
- `query_evidence(scope, filters)` -> `eval-query.sh` and eval run files
- `record_outcome(input)` -> `outcome-link.sh record`

If a runtime is older and lacks `capabilities.sh`, adapters may fall back to `guide.sh --json`, `doctor.sh`, and the default PrismSpec stages. New gates and metrics should be rendered from capability/eval JSON when available, not baked into the plugin.

## Limitations

- No `.claude/commands/` — use natural language to trigger skills
- Cursor may not auto-detect `rules.md` changes — reload the window after setup
- Cursor's context window is smaller — curated knowledge results should be concise

# Cursor Adapter

Lattice works with [Cursor](https://cursor.com) via its rules file mechanism.

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

## Usage

Cursor doesn't have a slash-command system like Claude Code, so invoke skills manually:

```
# In Cursor chat:
"Run bash lattice/kernel/delivery/pipeline.sh"
"Read lattice/context/README.md, then run bash lattice/kernel/context/backends/knowledge.sh <keywords> only if curated knowledge lookup is useful"
"Run bash lattice/kernel/delivery/gates/spec-lint.sh lattice/specs/my-spec/spec.md"
```

## Limitations

- No `.claude/commands/` — use natural language to trigger skills
- Cursor may not auto-detect `rules.md` changes — reload the window after setup
- Cursor's context window is smaller — curated knowledge results should be concise

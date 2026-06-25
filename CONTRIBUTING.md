# Contributing to SpecHarness

Thanks for your interest in contributing!

## Development Setup

```bash
git clone https://github.com/user/specharness.git
cd specharness
```

No build step required — SpecHarness is pure Bash + YAML.

## Testing

```bash
# Syntax check all scripts
bash -n init.sh install.sh $(find scaffold -name '*.sh')

# ShellCheck (if installed)
shellcheck init.sh install.sh $(find scaffold -name '*.sh')

# Integration test in a sandbox
mkdir /tmp/test-project && cd /tmp/test-project && git init
bash /path/to/specharness/install.sh --init
bash specharness/kernel/delivery/pipeline.sh
```

## Pull Requests

1. Fork the repo and create a feature branch
2. Keep changes focused — one concern per PR
3. Run `bash -n` and `shellcheck` before submitting
4. All shell scripts must pass `bash -n` syntax validation
5. User-facing output must be in English

## Code Style

- Bash 4.0+ compatible
- Use `set -euo pipefail` in all scripts
- Functions prefixed with `_` for internal/library use
- All paths relative to project root via `_find_project_root()`
- No hardcoded paths — read from `manifest.yaml` via `yq`

## Adding a New Gate

1. Create `scaffold/specharness/kernel/delivery/gates/your-gate.sh`
2. Source `../../_lib.sh` for logging and manifest access
3. Exit 0 = pass, exit 1 = retryable failure, exit 2 = escalation
4. Add the gate to the default pipeline steps in `manifest.template.yaml`
5. Document in README.md

## Adding Language Support

1. Add detection logic in `init.sh`
2. Add test function regex in `manifest.template.yaml` under `testing.strategies`
3. If adding drift detection, implement in `drift-check.sh` with the existing plugin pattern
4. Update the language support matrix in README.md

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

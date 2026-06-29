# Contributing to Lattice

Thanks for your interest in contributing.

## Development Setup

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
```

No build step is required. Lattice is a repository-delivered framework built from Bash, Markdown, and YAML.

## Testing

```bash
# Syntax check all scripts
bash -n init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')

# ShellCheck, if installed
shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')

# Integration smoke test
bash tests/smoke-test.sh

# Runnable example and release readiness check
bash examples/go-gin-gorm/try-it.sh
bash tests/release-check.sh
```

For a target-project install test:

```bash
mkdir /tmp/lattice-test-project && cd /tmp/lattice-test-project && git init
bash /path/to/lattice/install.sh --init
bash lattice/kernel/delivery/pipeline.sh
```

## Pull Requests

1. Keep changes focused: one concern per PR.
2. Run syntax checks and smoke tests before submitting.
3. Preserve project-owned data during install and upgrade flows.
4. Keep public documentation Chinese-first, with English docs available where useful.
5. Keep CLI output stable and automation-friendly.

## Code Style

- Bash 4.0+ compatible.
- Use `set -euo pipefail` in executable scripts.
- Prefer project-root-relative paths discovered by helper functions.
- Do not hardcode user machine paths.
- Read project configuration from `manifest.yaml` when behavior is project-specific.

## Adding a Delivery Gate

1. Create `harness-template/lattice/kernel/delivery/gates/your-gate.sh`.
2. Source the shared library from the target-project layout.
3. Use exit code `0` for pass, `1` for retryable failure, and `2` for escalation.
4. Add the gate to `harness-template/lattice/manifest.template.yaml` when it should be enabled by default.
5. Document the gate in the README or design wiki.

## Adding Language Support

1. Add detection logic in `init.sh`.
2. Add command defaults to `harness-template/lattice/manifest.template.yaml`.
3. Add drift or contract checks only when they provide meaningful evidence.
4. Update the language support matrix in the README.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

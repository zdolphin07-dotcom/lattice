# Support

Lattice is currently an early preview project. It is suitable for non-critical repositories, team pilots, and new feature workflows while the contracts and verification coverage continue to mature.

## What To Include

For installation or workflow issues, include:

- operating system and shell;
- output of `bash --version`, `git --version`, and `yq --version`;
- the install command used;
- output of `bash lattice/kernel/doctor.sh` when available;
- the relevant `spec.md`, `plan.md`, `review.md`, or `verify.md` excerpt if the issue is about a workflow contract;
- whether the repository is public, private, or behind an internal Git server.

Do not include secrets, tokens, private customer data, or proprietary source code in public issues.

## Troubleshooting Quick Checks

| Symptom | Check |
|---------|-------|
| Remote install returns 404 | Confirm the GitHub repository and raw install URL are public and accessible without local credentials. |
| `yq` is missing | Install Mike Farah `yq` 4.x before running `init.sh`. |
| Shell version behaves unexpectedly | Use the system Bash first; if compatibility issues appear, install a newer Bash and rerun the checks. |
| Doctor fails after upgrade | Re-run `install.sh --upgrade --init` from the target repository and inspect `lattice/state/*-backups/`. |
| Pipeline skips most steps | Confirm `lattice/manifest.yaml` has project commands and `lattice/specs/<spec-id>/spec.md` exists. |

## Current Scope

Actively validated:

- repo-local install/init;
- PrismSpec artifact routing and linting;
- Lattice smoke test;
- Go/Gin/GORM runnable example;
- Bash-based delivery gates and eval summaries.

Still maturing:

- complex enterprise CI integrations;
- multi-person spec ownership;
- long-running governance and promotion workflows;
- language-specific drift parsing beyond the current example coverage.

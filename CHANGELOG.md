# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- `prismspec/skillpack.yaml` as the machine-readable PrismSpec skill pack contract.
- `lattice/kernel/doctor.sh` to verify installed Lattice/PrismSpec project health.
- `pipeline.sh --json-out[=<file>]` to write structured eval run evidence under `lattice/state/eval-runs/`.
- `--json-out[=<file>]` for AC coverage, drift check, and compliance gates, embedded into pipeline eval runs.
- GitHub Actions eval artifact workflow template installed by `init.sh --ci=github`.
- **PrismSpec** standalone spec-coding skill pack with guided `/sdd`, canonical `SKILL.md` files, templates, references, and workflow scripts.
- Chinese-first project entrypoint via the root `README.md`; English documentation moved to `README.en.md`.
- CI validation for PrismSpec skill frontmatter and PrismSpec shell scripts.
- Root `AGENTS.md` to make the repository easier for coding agents to navigate.

### Changed

- README and wiki now describe pipeline/gate eval JSON and GitHub Actions artifacts as implemented, with review/TDD evidence JSON as the next step.
- PrismSpec README now documents `context.md` in both standalone and Lattice-hosted artifact layouts.

### Fixed

- `/sdd` guide now requires actual verification evidence and no longer treats review packages as verification output.
- Public contribution docs now use Lattice naming and current paths.

## [1.0.0] — 2026-06-23

### Added

- **Engine-agnostic architecture**: Generic phase names (design → plan → implement → verify → deliver) replace engine-specific coupling. Workflow engine integration via adapter docs.
- **Configurable spec-lint**: `specs.required_sections[]` and `specs.risk_categories[]` in manifest.yaml — override defaults without touching kernel code.
- **Three-layer architecture**: Orchestrator (rules injection), Knowledge (context retrieval), Delivery (gate pipeline) — each independently pluggable.
- **5 delivery gates**: spec-lint, ac-coverage, drift-check, compliance, spec-lock.
- **AC tracing**: Acceptance Criteria numbering from spec through test naming to coverage verification.
- **Knowledge layer**: Keyword-based retrieval with synonym support, central repo sync.
- **Multi-language support**: Go (Gin/GORM), Node (Express/Prisma), Python (FastAPI/SQLAlchemy), Rust detection.
- **Agent skills**: `/init` (project setup), `/verify` (pipeline execution), `/learn` (knowledge capture).
- **Escalation protocol**: Exit code 2 triggers human intervention after retry exhaustion.
- **Adapter documentation**: Engine-specific integration guides under `docs/adapters/`.

### Fixed

- `_find_project_root()` now walks up directories instead of using hardcoded relative path.
- `run_cmd()` removed non-functional security check; documented trust model.
- `init.sh` fixed `local` keyword used outside function scope.
- `drift-check.sh` replaced `eval` with `bash -c` for plugin execution.

### Changed

- All CLI output in English (previously Chinese).
- Internal delivery variables standardized on the `SH_*` / `_SH_*` prefix.
- Spec template sections use English headers by default.
- Install paths standardized for the Lattice harness-template layout.

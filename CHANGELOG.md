# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- `prismspec/skillpack.yaml` as the machine-readable PrismSpec skill pack contract.
- `lattice/kernel/doctor.sh` to verify installed Lattice/PrismSpec project health.
- `pipeline.sh --json-out[=<file>]` to write structured eval run evidence under `lattice/state/eval-runs/`.
- `--json-out[=<file>]` for AC coverage, drift check, and compliance gates, embedded into pipeline eval runs.
- `eval-summary.sh` to render eval run JSON into Markdown for local review and CI Step Summary.
- `eval-history.sh` to aggregate eval run JSON files into a Markdown trend report.
- `eval-sink.sh` to publish eval runs, outcome links, and Markdown reports to a local central eval sink with per-project manifests and an index.
- `eval-dashboard.sh` to render a static HTML dashboard from the central eval sink.
- `eval-query.sh` to query central eval sink summaries, runs, and outcomes as Markdown or JSON.
- `outcome-link.sh` to link post-run review findings, rework, escaped defects, incidents, or success signals back to eval runs under `lattice/state/outcomes/`.
- `outcome-report.sh` to render outcome attribution signals, context references, severity distribution, and runs needing review.
- Loop state JSON under `lattice/state/loops/`, embedded into eval runs and summarized in eval reports.
- Failure category and default action fields in loop state, eval summaries, and escalation learn drafts.
- Configurable failure categories via `lattice/config/failure-categories.yaml`.
- `failure-category-lint.sh` and doctor integration for failure category config validation.
- Escalation knowledge drafts under `lattice/context/drafts/` when retry budget is exhausted.
- `learn-draft.sh` to promote or discard confirmed knowledge drafts with archived source drafts and audit events under `lattice/state/learn-promotions/`.
- `knowledge-review.sh` to record approve/reject reviewer decisions under `lattice/state/knowledge-reviews/`; `learn-draft.sh promote --require-review` can require approved review evidence with conflict checks.
- `summary-learn-draft.sh` to convert Knowledge Candidates into reviewable knowledge drafts.
- `knowledge-lint.sh` to flag missing metadata, missing sources, placeholders, conflict markers, expired entries, and duplicate headings in project knowledge.
- `pr-comment.sh` to create or update a stable GitHub PR comment from the eval Markdown summary.
- `install.sh --dry-run` and `install.sh --version` for safer install diagnostics.
- `tests/release-check.sh` as the maintainer release readiness command.
- `SECURITY.md`, `SUPPORT.md`, GitHub issue templates, and a pull request template for public project operations.
- `spec-state-lint.sh` to validate spec front matter and status-to-artifact readiness.
- `spec-status.sh` to advance spec lifecycle status with guarded transitions, stale-state protection, and JSON transition events.
- `spec-history.sh` to aggregate spec transition events into a Markdown lifecycle report.
- `plan-lint.sh` to validate AC-traced implementation plans before task execution starts.
- `task-next.sh` to resolve the next incomplete plan task as text or JSON for implementation recovery.
- `task-complete.sh` to mark individual plan tasks complete only after required task evidence exists.
- `task-evidence-lint.sh` to require brief, review package, and TDD evidence for completed implementation tasks.
- `summary-draft.sh` to generate `summary.md` completion drafts from spec, plan, verification, task evidence, and optional eval JSON.
- `review-summary.sh` and `tdd-evidence.sh` to capture process evidence as structured JSON.
- GitHub Actions eval artifact workflow template installed by `init.sh --ci=github`.
- **PrismSpec** standalone spec-coding skill pack with guided `/prismspec`, canonical `SKILL.md` files, templates, references, and workflow scripts.
- Chinese-first project entrypoint via the root `README.md`; English documentation moved to `README.en.md`.
- CI validation for PrismSpec skill frontmatter and PrismSpec shell scripts.
- Root `AGENTS.md` to make the repository easier for coding agents to navigate.

### Changed

- README and wiki now describe pipeline/gate eval JSON, central eval sink, loop state, outcome links/reports, configurable failure categories, failure category lint, escalation knowledge drafts, knowledge draft promotion/discard, knowledge governance lint, review/TDD process evidence, Markdown summaries/history, GitHub Actions artifacts, Step Summary, and PR comments as implemented.
- Default architecture and glossary knowledge templates now include `Source` columns for promotion governance.
- Default project knowledge templates now include `owner`, `verified_at`, and `applies_to` front matter.
- PrismSpec now treats `spec.md#Context Basis` as the default per-spec context contract instead of a separate `context.md` artifact.
- Plan lint now enforces a stricter task schema with AC coverage, mode/scope, evidence paths, done conditions, stable task order, and TDD red-test ordering.

### Fixed

- PrismSpec guide now requires actual verification evidence and no longer treats review packages as verification output.
- Public contribution docs now use Lattice naming and current paths.
- CI now runs the Go/Gin/GORM example and release readiness check in addition to smoke tests.

## [1.0.0] — 2026-06-23

### Added

- **Engine-agnostic architecture**: Generic phase names (design → plan → implement → verify → deliver) replace engine-specific coupling. Workflow engine integration via adapter docs.
- **Configurable spec-lint**: `specs.required_sections[]` and `specs.risk_categories[]` in manifest.yaml — override defaults without touching kernel code.
- **Three-layer architecture**: Orchestrator (rules injection), Knowledge (context retrieval), Delivery (gate pipeline) — each independently pluggable.
- **5 delivery gates**: spec-lint, ac-coverage, drift-check, compliance, spec-lock.
- **AC tracing**: Acceptance Criteria numbering from spec through test naming to coverage verification.
- **Knowledge layer**: Keyword-based retrieval with synonym support, central repo sync.
- **Multi-language support**: Go (Gin/GORM), Node (Express/Prisma), Python (FastAPI/SQLAlchemy), Rust detection.
- **Agent skills**: project setup, verification, and knowledge capture.
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

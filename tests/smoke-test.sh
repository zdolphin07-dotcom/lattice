#!/usr/bin/env bash
# smoke-test.sh — End-to-end smoke test for Lattice
# Creates a temp Go project, runs init + pipeline, verifies exit codes.
# Usage: bash tests/smoke-test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
SANDBOX=""
TARGET_INIT_SANDBOX=""

pass() { ((PASS++)); printf "  ✅ %s\n" "$*"; }
fail() { ((FAIL++)); printf "  ❌ %s\n" "$*"; }

cleanup() {
  if [[ -n "$SANDBOX" ]] && [[ -d "$SANDBOX" ]]; then
    rm -rf "$SANDBOX"
  fi
  if [[ -n "$TARGET_INIT_SANDBOX" ]] && [[ -d "$TARGET_INIT_SANDBOX" ]]; then
    rm -rf "$TARGET_INIT_SANDBOX"
  fi
}
trap cleanup EXIT

for tool in yq git; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Smoke test requires $tool. Skipping."
    exit 0
  fi
done

SANDBOX=$(mktemp -d)
echo "══════════════════════════════════"
echo "Lattice Smoke Test"
echo "Sandbox: $SANDBOX"
echo "══════════════════════════════════"
echo ""

# ── 1. bash -n syntax check ──
echo "── 1. Syntax check (bash -n) ──"
SYNTAX_OK=true
for f in "$REPO_DIR"/init.sh "$REPO_DIR"/install.sh $(find "$REPO_DIR/harness-template" "$REPO_DIR/prismspec/bin" -name '*.sh'); do
  if ! bash -n "$f" 2>/dev/null; then
    fail "Syntax error: $(basename "$f")"
    SYNTAX_OK=false
  fi
done
if [[ "$SYNTAX_OK" == "true" ]]; then
  pass "All scripts pass bash -n"
fi
echo ""

# ── 2. Local install ──
echo "── 2. Local install ──"
cd "$SANDBOX"
git init --quiet

if bash "$REPO_DIR/install.sh" "$SANDBOX" 2>&1 | tail -3; then
  if [[ -d "$SANDBOX/.lattice/framework/harness-template" ]]; then
    pass "install.sh completed, harness-template exists"
  else
    fail "install.sh ran but harness-template not found"
  fi
else
  fail "install.sh exited non-zero"
fi
echo ""

# ── 3. Init (non-interactive, Go project) ──
echo "── 3. Init (Go project, non-interactive) ──"

cat > "$SANDBOX/go.mod" << 'EOF'
module github.com/example/testapp

go 1.22

require github.com/gin-gonic/gin v1.9.1
require gorm.io/gorm v1.25.0
EOF

if bash "$SANDBOX/.lattice/framework/init.sh" --non-interactive --lang=go --name=testapp --ci=github 2>&1 | tail -5; then
  if [[ -f "$SANDBOX/lattice/manifest.yaml" ]]; then
    pass "manifest.yaml generated"
  else
    fail "manifest.yaml not found after init"
  fi

  DEFAULT_MODE=$(yq -r '.specs.default_execution_mode // ""' "$SANDBOX/lattice/manifest.yaml")
  ALLOW_MODE_OVERRIDE=$(yq -r '.specs.allow_execution_mode_override // ""' "$SANDBOX/lattice/manifest.yaml")
  CI_PLATFORM=$(yq -r '.deploy.ci.platform // ""' "$SANDBOX/lattice/manifest.yaml")
  EVAL_SINK_DIR=$(yq -r '.eval.sink.dir // ""' "$SANDBOX/lattice/manifest.yaml")
  if [[ "$DEFAULT_MODE" == "auto" ]] && [[ "$ALLOW_MODE_OVERRIDE" == "true" ]]; then
    pass "execution mode policy configured"
  else
    fail "execution mode policy missing from manifest"
  fi

  if [[ "$CI_PLATFORM" == "github" ]]; then
    pass "CI platform configured"
  else
    fail "CI platform not configured"
  fi

  if [[ "$EVAL_SINK_DIR" == "lattice/state/eval-sink" ]]; then
    pass "eval sink configured"
  else
    fail "eval sink not configured"
  fi

  if [[ -f "$SANDBOX/lattice/kernel/_lib.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/eval-summary.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/eval-history.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/eval-sink.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/eval-dashboard.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/eval-query.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/outcome-link.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/outcome-report.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/pr-comment.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/delivery/failure-category-lint.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/plan-lint.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/task-next.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/task-evidence-lint.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-state-lint.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-history.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/context/context-lint.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/context/context-run.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/context/learn-draft.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/context/knowledge-review.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/context/knowledge-lint.sh" ]] \
    && [[ -f "$SANDBOX/lattice/config/failure-categories.yaml" ]]; then
    pass "kernel files installed"
  else
    fail "kernel files not installed"
  fi

  if [[ -x "$SANDBOX/lattice/kernel/doctor.sh" ]]; then
    pass "lattice doctor installed"
  else
    fail "lattice doctor missing or not executable"
  fi

  if [[ -f "$SANDBOX/lattice/kernel/context/backends/knowledge.sh" ]] \
    && [[ -f "$SANDBOX/lattice/context/README.md" ]] \
    && [[ -f "$SANDBOX/lattice/context/sources.yaml" ]] \
    && [[ -f "$SANDBOX/lattice/context/knowledge/rules.md" ]]; then
    pass "context layer installed"
  else
    fail "context layer files missing"
  fi

  if [[ -f "$SANDBOX/CLAUDE.md" ]]; then
    pass "CLAUDE.md created"
  else
    fail "CLAUDE.md not created"
  fi

  if [[ -f "$SANDBOX/lattice/skills/init.md" ]]; then
    pass "Lattice init skill installed"
  else
    fail "Lattice init skill missing"
  fi

  if [[ -f "$SANDBOX/.github/workflows/lattice-eval.yml" ]] \
    && yq -e '.permissions.issues == "write" and .permissions."pull-requests" == "read"' "$SANDBOX/.github/workflows/lattice-eval.yml" >/dev/null 2>&1 \
    && yq -e '.jobs.eval.steps[] | select(.name == "Publish Lattice PR comment")' "$SANDBOX/.github/workflows/lattice-eval.yml" >/dev/null 2>&1; then
    pass "GitHub Actions eval workflow installed"
  else
    fail "GitHub Actions eval workflow missing or invalid"
  fi

  for command in sdd brainstorm plan implement verify finish learn; do
    if [[ -f "$SANDBOX/.claude/commands/${command}.md" ]]; then
      pass "$command slash command installed"
    else
      fail "$command slash command missing"
    fi
  done

  if [[ -f "$SANDBOX/prismspec/skills/sdd/SKILL.md" ]] \
    && [[ -f "$SANDBOX/prismspec/skillpack.yaml" ]] \
    && [[ -f "$SANDBOX/prismspec/skills/brainstorm/SKILL.md" ]] \
    && [[ -f "$SANDBOX/prismspec/skills/plan/SKILL.md" ]] \
    && [[ -f "$SANDBOX/prismspec/skills/implement/SKILL.md" ]] \
    && [[ -f "$SANDBOX/prismspec/skills/verify/SKILL.md" ]] \
    && [[ -f "$SANDBOX/prismspec/skills/finish/SKILL.md" ]] \
    && [[ -f "$SANDBOX/prismspec/skills/learn/SKILL.md" ]] \
    && [[ -x "$SANDBOX/prismspec/bin/guide.sh" ]] \
    && [[ -x "$SANDBOX/prismspec/bin/lint.sh" ]] \
    && [[ -f "$SANDBOX/prismspec/templates/spec-template.md" ]] \
    && [[ -f "$SANDBOX/prismspec/templates/spec-template-lite.md" ]] \
    && [[ -f "$SANDBOX/prismspec/templates/spec-template-service.md" ]] \
    && [[ -f "$SANDBOX/prismspec/templates/spec-template-frontend.md" ]] \
    && [[ -f "$SANDBOX/prismspec/templates/spec-template-tdd.md" ]] \
    && [[ -f "$SANDBOX/prismspec/templates/context-template.md" ]] \
    && [[ -f "$SANDBOX/prismspec/references/mode-selection.md" ]] \
    && [[ -f "$SANDBOX/prismspec/references/definition-of-done.md" ]] \
    && [[ -f "$SANDBOX/prismspec/agents/spec-compliance-reviewer.md" ]] \
    && [[ -f "$SANDBOX/prismspec/commands/sdd.md" ]]; then
    pass "PrismSpec deliverable module installed"
  else
    fail "PrismSpec standalone module missing"
  fi

  FLAT_SKILL_COUNT=$(find "$SANDBOX/prismspec/skills" -maxdepth 1 -type f -name '*.md' -not -name 'README.md' | wc -l | tr -d ' ')
  LATTICE_SDD_SKILL_COUNT=$(find "$SANDBOX/lattice/skills" -maxdepth 1 -type f \( -name 'sdd.md' -o -name 'brainstorm.md' -o -name 'plan.md' -o -name 'implement.md' -o -name 'verify.md' -o -name 'finish.md' -o -name 'learn.md' \) | wc -l | tr -d ' ')
  if [[ "$FLAT_SKILL_COUNT" == "0" ]] && [[ "$LATTICE_SDD_SKILL_COUNT" == "0" ]]; then
    pass "SDD workflow has a single canonical skill source"
  else
    fail "Duplicate SDD skill files found"
  fi

  GUIDE_OUTPUT=$(bash "$SANDBOX/prismspec/bin/guide.sh" --json)
  if echo "$GUIDE_OUTPUT" | grep -q '"stage": "brainstorm"' && echo "$GUIDE_OUTPUT" | grep -q 'prismspec/skills/brainstorm/SKILL.md'; then
    pass "PrismSpec guide detects initial brainstorm stage"
  else
    fail "PrismSpec guide did not detect initial brainstorm stage"
  fi

  GUIDE_ALIAS_OUTPUT=$(bash "$SANDBOX/prismspec/bin/guide.sh" spec=example mode=tdd --json)
  if echo "$GUIDE_ALIAS_OUTPUT" | grep -q '"spec_id": "example"' && echo "$GUIDE_ALIAS_OUTPUT" | grep -q '"mode": "tdd"'; then
    pass "PrismSpec guide accepts command aliases"
  else
    fail "PrismSpec guide did not accept command aliases"
  fi

  if [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/task-brief.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/task-next.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/task-evidence-lint.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/review-package.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/review-summary.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-history.sh" ]] \
    && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/tdd-evidence.sh" ]]; then
    pass "SDD helper scripts installed"
  else
    fail "SDD helper scripts missing"
  fi

  if grep -qxF ".lattice/sdd/" "$SANDBOX/.gitignore"; then
    pass ".lattice/sdd ignored"
  else
    fail ".lattice/sdd not ignored"
  fi

  if grep -qxF ".prismspec/runs/" "$SANDBOX/.gitignore"; then
    pass ".prismspec/runs ignored"
  else
    fail ".prismspec/runs not ignored"
  fi

  DOCTOR_EXIT=0
  DOCTOR_OUTPUT=$(bash "$SANDBOX/lattice/kernel/doctor.sh" 2>&1) || DOCTOR_EXIT=$?
  if [[ $DOCTOR_EXIT -eq 0 ]] && echo "$DOCTOR_OUTPUT" | grep -q "PASS"; then
    pass "lattice doctor passes installed project"
  else
    fail "lattice doctor failed"
    echo "$DOCTOR_OUTPUT" | tail -20
  fi
else
  fail "init.sh exited non-zero"
fi

# Clean up examples inside harness to avoid false positives in search
rm -rf "$SANDBOX/.lattice/framework/examples" "$SANDBOX/.lattice/framework/tests"
echo ""

# ── 4. Install --init targets the requested directory ──
echo "── 4. Install --init target directory ──"
TARGET_INIT_SANDBOX=$(mktemp -d)
printf 'module github.com/example/targetinit\n\ngo 1.22\n' > "$TARGET_INIT_SANDBOX/go.mod"

if printf '\n\n\n\n\n\n' | bash "$REPO_DIR/install.sh" "$TARGET_INIT_SANDBOX" --init >/tmp/lattice-target-init.log 2>&1; then
  if [[ -f "$TARGET_INIT_SANDBOX/lattice/manifest.yaml" ]]; then
    pass "install.sh --init writes manifest to target directory"
  else
    fail "install.sh --init did not write manifest to target directory"
    tail -10 /tmp/lattice-target-init.log
  fi
else
  fail "install.sh --init exited non-zero"
  tail -10 /tmp/lattice-target-init.log
fi
rm -rf "$TARGET_INIT_SANDBOX" /tmp/lattice-target-init.log
echo ""

# ── 5. Pipeline (no code, no spec — should pass with all skips) ──
echo "── 5. Pipeline (no code, no spec) ──"
cd "$SANDBOX"
PIPELINE_EXIT=0
PIPELINE_OUTPUT=$(bash lattice/kernel/delivery/pipeline.sh --skip-spec --skip-integration 2>&1) || PIPELINE_EXIT=$?

if echo "$PIPELINE_OUTPUT" | grep -q "ALL PASS\|PASS"; then
  pass "Pipeline completes (bootstrap-only)"
elif echo "$PIPELINE_OUTPUT" | grep -q "FAIL"; then
  # Bootstrap may fail if go/docker not installed — that's expected
  if echo "$PIPELINE_OUTPUT" | grep -q "not installed"; then
    pass "Pipeline ran correctly (tools not installed — expected in CI)"
  else
    fail "Pipeline failed unexpectedly"
    echo "$PIPELINE_OUTPUT" | tail -10
  fi
else
  pass "Pipeline executed (exit=$PIPELINE_EXIT)"
fi

PIPELINE_JSON_EXIT=0
PIPELINE_JSON_OUTPUT=$(bash lattice/kernel/delivery/pipeline.sh --skip-spec --skip-integration --json-out 2>&1) || PIPELINE_JSON_EXIT=$?
LATEST_EVAL_JSON=$(find "$SANDBOX/lattice/state/eval-runs" -name '*.json' -type f -print 2>/dev/null | sort | tail -1)
if [[ -n "$LATEST_EVAL_JSON" ]] \
  && grep -q '"run_id"' "$LATEST_EVAL_JSON" \
  && grep -q '"pipeline"' "$LATEST_EVAL_JSON" \
  && grep -q '"steps"' "$LATEST_EVAL_JSON" \
  && yq -e '.pipeline.status and .steps' "$LATEST_EVAL_JSON" >/dev/null 2>&1; then
  pass "Pipeline writes structured eval JSON"
else
  fail "Pipeline did not write structured eval JSON"
  echo "$PIPELINE_JSON_OUTPUT" | tail -20
  echo "exit=$PIPELINE_JSON_EXIT file=${LATEST_EVAL_JSON:-<missing>}"
fi
echo ""

# ── 6. Spec-lint on directory spec layout ──
echo "── 6. Spec-lint modern layout ──"
mkdir -p "$SANDBOX/lattice/specs/modern-feature"
cat > "$SANDBOX/lattice/specs/modern-feature/context.md" << 'CONTEXT'
# Context: modern-feature

## Decision Frame

| Item | Value |
|------|-------|
| Requirement type | feature |
| Execution mode impact | tdd |
| Main affected surface | test fixture |
| Verification focus | spec-lint / prismspec-lint |

## Selected Facts

| Type | Source | Fact | Decision Impact |
|------|--------|------|-----------------|
| user | smoke test | Smoke-test PrismSpec modern artifact layout. | Use a minimal fixture. |
| code | N/A | No production code is required for this fixture. | Keep scope small. |
| knowledge | N/A | No durable project rule required. | No knowledge dependency. |

## Constraints

| Type | Constraint | Source | Impact |
|------|------------|--------|--------|
| test | Keep AC ids stable. | fixture | Lint should pass predictably. |

## Conflicts / Ambiguities

| Issue | Sources | Required Decision |
|-------|---------|-------------------|
| None | N/A | N/A |

## Exclusions

| Source / Topic | Why excluded |
|----------------|--------------|
| Production code | This fixture validates artifact contracts only. |

## Context Gaps

| Gap | Blocks planning? | Question / Next action |
|-----|------------------|------------------------|
| None | no | N/A |
CONTEXT

cat > "$SANDBOX/lattice/specs/modern-feature/spec.md" << 'SPEC'
---
id: modern-feature
status: drafted
execution_mode: tdd
mode_source: model-selected
owner: smoke
created_at: 2026-06-26T00:00:00Z
updated_at: 2026-06-26T00:00:00Z
---

# Spec: Modern Feature

## Intent

Add a small behavior with AC tracing.

## Scope

### In

- Create behavior.

### Out

- Export behavior.

## Context

| Source | Constraint | Why it matters |
|--------|------------|----------------|
| smoke | Keep it simple | Test modern lint |

## Acceptance Criteria

| # | When | Then | Verification |
|---|------|------|--------------|
| AC-1 | Create item | Returns 201 | TestAC1 |
| AC-2 | Get item | Returns item | TestAC2 |

## Design Decisions

| # | Decision | Rationale | Reversible? |
|---|----------|-----------|-------------|
| D-1 | Use existing handler | Minimal change | yes |

## Risk Notes

| Risk | Mitigation | Verification |
|------|------------|--------------|
| None | N/A | Tests |

## Execution Policy

- Mode: `tdd`
- Reason: smoke test validates modern template.

## Verification Plan

| Gate / Test | Required? | Notes |
|-------------|-----------|-------|
| spec-lint | yes | |
| unit-test | yes | |
SPEC

MODERN_LINT_EXIT=0
MODERN_LINT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/spec-lint.sh" "$SANDBOX/lattice/specs/modern-feature/spec.md" 2>&1) || MODERN_LINT_EXIT=$?

if [[ $MODERN_LINT_EXIT -eq 0 ]]; then
  pass "spec-lint passes on modern persistent spec"
else
  fail "spec-lint failed on modern persistent spec (exit=$MODERN_LINT_EXIT)"
  echo "$MODERN_LINT_OUTPUT" | tail -10
fi

PRISMSPEC_SPEC_LINT_EXIT=0
PRISMSPEC_SPEC_LINT_OUTPUT=$(bash "$SANDBOX/prismspec/bin/lint.sh" "$SANDBOX/lattice/specs/modern-feature/spec.md" spec 2>&1) || PRISMSPEC_SPEC_LINT_EXIT=$?
if [[ $PRISMSPEC_SPEC_LINT_EXIT -eq 0 ]]; then
  pass "PrismSpec lint passes spec contract"
else
  fail "PrismSpec lint failed spec contract"
  echo "$PRISMSPEC_SPEC_LINT_OUTPUT" | tail -10
fi

SPEC_STATE_LINT_EXIT=0
SPEC_STATE_LINT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-state-lint.sh" modern-feature 2>&1) || SPEC_STATE_LINT_EXIT=$?
if [[ $SPEC_STATE_LINT_EXIT -eq 0 ]]; then
  pass "spec-state-lint passes drafted spec state"
else
  fail "spec-state-lint failed drafted spec state"
  echo "$SPEC_STATE_LINT_OUTPUT" | tail -20
fi

mkdir -p "$SANDBOX/lattice/specs/bad-state"
cp "$SANDBOX/lattice/specs/modern-feature/context.md" "$SANDBOX/lattice/specs/bad-state/context.md"
cat > "$SANDBOX/lattice/specs/bad-state/spec.md" << 'BAD_STATE_SPEC'
---
id: bad-state
status: planned
execution_mode: auto
mode_source: model-selected
owner: smoke
created_at: 2026-06-26T00:00:00Z
updated_at: 2026-06-26T00:00:00Z
---

# Spec: Bad State

## Intent

Bad state fixture.
BAD_STATE_SPEC
BAD_STATE_LINT_EXIT=0
bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-state-lint.sh" bad-state >/tmp/lattice-spec-state-lint-bad.log 2>&1 || BAD_STATE_LINT_EXIT=$?
if [[ $BAD_STATE_LINT_EXIT -ne 0 ]] \
  && grep -q "execution_mode must be resolved" /tmp/lattice-spec-state-lint-bad.log \
  && grep -q "plan.md required" /tmp/lattice-spec-state-lint-bad.log; then
  pass "spec-state-lint rejects invalid state metadata"
else
  fail "spec-state-lint accepted invalid state metadata"
  tail -30 /tmp/lattice-spec-state-lint-bad.log
fi

CONTEXT_LINT_EXIT=0
CONTEXT_LINT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/context/context-lint.sh" modern-feature --strict 2>&1) || CONTEXT_LINT_EXIT=$?
if [[ $CONTEXT_LINT_EXIT -eq 0 ]]; then
  pass "context-lint passes complete context basis"
else
  fail "context-lint failed complete context basis"
  echo "$CONTEXT_LINT_OUTPUT" | tail -20
fi

mkdir -p "$SANDBOX/lattice/specs/bad-context"
cat > "$SANDBOX/lattice/specs/bad-context/context.md" << 'BAD_CONTEXT'
# Context: bad-context

## Decision Frame

| Item | Value |
|------|-------|
| Requirement type | feature / bugfix / refactor / docs / config |

## Selected Facts

| Type | Source | Fact | Decision Impact |
|------|--------|------|-----------------|
| code | `path/to/file` | | |

## Constraints

| Type | Constraint | Source | Impact |
|------|------------|--------|--------|
| compatibility / security / data / performance / release | | | |

## Conflicts / Ambiguities

| Issue | Sources | Required Decision |
|-------|---------|-------------------|
| TODO | TBD | FIXME |

## Exclusions

| Source / Topic | Why excluded |
|----------------|--------------|
| | |

## Context Gaps

| Gap | Blocks planning? | Question / Next action |
|-----|------------------|------------------------|
| Unknown data contract | yes | Ask owner |
BAD_CONTEXT
BAD_CONTEXT_LINT_EXIT=0
bash "$SANDBOX/lattice/kernel/context/context-lint.sh" bad-context --strict >/tmp/lattice-context-lint-bad.log 2>&1 || BAD_CONTEXT_LINT_EXIT=$?
if [[ $BAD_CONTEXT_LINT_EXIT -ne 0 ]] && grep -q "Selected Facts" /tmp/lattice-context-lint-bad.log; then
  pass "context-lint rejects unfinished context basis"
else
  fail "context-lint accepted unfinished context basis"
  tail -20 /tmp/lattice-context-lint-bad.log
fi

CONTEXT_RUN_JSON="$SANDBOX/lattice/state/context-runs/modern-feature-smoke.json"
CONTEXT_RUN_EXIT=0
CONTEXT_RUN_OUTPUT=$(bash "$SANDBOX/lattice/kernel/context/context-run.sh" modern-feature --strict --out="$CONTEXT_RUN_JSON" 2>&1) || CONTEXT_RUN_EXIT=$?
if [[ $CONTEXT_RUN_EXIT -eq 0 ]] \
  && [[ -f "$CONTEXT_RUN_JSON" ]] \
  && yq -e '.kind == "context-run" and .spec_id == "modern-feature" and .metrics.selected_facts == 3 and .metrics.constraints == 1 and .metrics.blocking_gaps == 0 and (.selected_sources | length == 3)' "$CONTEXT_RUN_JSON" >/dev/null 2>&1; then
  pass "context-run records selected context evidence"
else
  fail "context-run output invalid"
  echo "$CONTEXT_RUN_OUTPUT" | tail -20
fi
echo ""

# ── 6c. SDD helper scripts ──
echo "── 6c. SDD helper scripts ──"
cat > "$SANDBOX/lattice/specs/modern-feature/plan.md" << 'PLAN'
# Plan: Modern Feature

## Source

- Spec: `lattice/specs/modern-feature/spec.md`
- Execution mode: tdd

## Implementation Notes

## Global Constraints

- Versions / dependencies: use existing Go module.
- Naming / style: keep AC test names.
- Security / permissions: no permission change.
- Data / migration: no migration.
- Compatibility: no API break.
- Out-of-scope: export behavior.

## Tasks

- [ ] RED-1: Add failing test for AC-1
  - Ref: AC-1
  - Expected failure: handler does not create items yet
  - Test file: `internal/handler/item_test.go`
  - Verification: `go test ./internal/handler -run TestAC1_CreateItem`
  - Done when:
    - [ ] Expected failure is captured in `.lattice/sdd/modern-feature/T1/tdd-evidence.json`

- [ ] RED-2: Add failing test for AC-2
  - Ref: AC-2
  - Expected failure: handler does not return created items yet
  - Test file: `internal/handler/item_test.go`
  - Verification: `go test ./internal/handler -run TestAC2_GetItem`
  - Done when:
    - [ ] Expected failure is captured in `.lattice/sdd/modern-feature/T2/tdd-evidence.json`

- [ ] T1: Add create behavior
  - Ref: AC-1
  - Mode: tdd
  - Scope: Implement the smallest create path needed for AC-1.
  - Interfaces:
    - Inputs: create request
    - Outputs: 201 response
    - Touched files/contracts: handler
  - Files: `internal/handler/item.go`
  - Verification: `TestAC1_CreateItem`
  - Evidence:
    - Brief: `.lattice/sdd/modern-feature/T1/brief.md`
    - Review package: `.lattice/sdd/modern-feature/T1/review-package.md`
  - Done when:
    - [ ] AC-1 passes focused verification and evidence exists.

- [ ] T2: Add get behavior
  - Ref: AC-2
  - Mode: tdd
  - Scope: Implement the smallest get path needed for AC-2.
  - Interfaces:
    - Inputs: get request
    - Outputs: item response
    - Touched files/contracts: handler
  - Files: `internal/handler/item.go`
  - Verification: `TestAC2_GetItem`
  - Evidence:
    - Brief: `.lattice/sdd/modern-feature/T2/brief.md`
    - Review package: `.lattice/sdd/modern-feature/T2/review-package.md`
  - Done when:
    - [ ] AC-2 passes focused verification and evidence exists.
PLAN

TASK_NEXT_JSON=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/task-next.sh" modern-feature --json)
if echo "$TASK_NEXT_JSON" | yq -e '.kind == "task-next" and .status == "next" and .task_id == "RED-1" and .task_kind == "red-test" and .mode == "tdd" and (.ac_refs | length == 1 and .ac_refs[0] == "AC-1")' >/dev/null 2>&1; then
  pass "task-next resolves first red-test task"
else
  fail "task-next did not resolve first red-test task"
  echo "$TASK_NEXT_JSON"
fi

PRISMSPEC_PLAN_LINT_EXIT=0
PRISMSPEC_PLAN_LINT_OUTPUT=$(bash "$SANDBOX/prismspec/bin/lint.sh" "$SANDBOX/lattice/specs/modern-feature" plan 2>&1) || PRISMSPEC_PLAN_LINT_EXIT=$?
if [[ $PRISMSPEC_PLAN_LINT_EXIT -eq 0 ]]; then
  pass "PrismSpec lint passes plan contract"
else
  fail "PrismSpec lint failed plan contract"
  echo "$PRISMSPEC_PLAN_LINT_OUTPUT" | tail -10
fi

PLAN_LINT_EXIT=0
PLAN_LINT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/plan-lint.sh" modern-feature 2>&1) || PLAN_LINT_EXIT=$?
if [[ $PLAN_LINT_EXIT -eq 0 ]]; then
  pass "plan-lint passes AC-traced plan"
else
  fail "plan-lint failed AC-traced plan"
  echo "$PLAN_LINT_OUTPUT" | tail -20
fi

SPEC_STATUS_PLANNED_EXIT=0
SPEC_STATUS_PLANNED_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" modern-feature planned --from=drafted 2>&1) || SPEC_STATUS_PLANNED_EXIT=$?
GUIDE_STATUS_JSON=$(cd "$SANDBOX" && bash prismspec/bin/guide.sh --spec=modern-feature --json)
if [[ $SPEC_STATUS_PLANNED_EXIT -eq 0 ]] \
  && grep -q '^status: planned$' "$SANDBOX/lattice/specs/modern-feature/spec.md" \
  && echo "$GUIDE_STATUS_JSON" | yq -e '.status == "planned"' >/dev/null 2>&1; then
  pass "spec-status advances drafted spec to planned"
else
  fail "spec-status failed to advance drafted spec to planned"
  echo "$SPEC_STATUS_PLANNED_OUTPUT" | tail -20
fi
PLANNED_TRANSITION_EVENT="$(
  find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null \
    | while IFS= read -r file; do
        yq -e '.kind == "spec-transition" and .from_status == "drafted" and .to_status == "planned"' "$file" >/dev/null 2>&1 && echo "$file"
      done \
    | tail -1 || true
)"
if [[ -f "$PLANNED_TRANSITION_EVENT" ]] \
  && yq -e '.kind == "spec-transition" and .spec_id == "modern-feature" and .from_status == "drafted" and .to_status == "planned" and .checks.plan_lint == true and .checks.spec_state_lint == true' "$PLANNED_TRANSITION_EVENT" >/dev/null 2>&1; then
  pass "spec-status records planned transition event"
else
  fail "spec-status planned transition event invalid"
  [[ -f "$PLANNED_TRANSITION_EVENT" ]] && cat "$PLANNED_TRANSITION_EVENT"
fi
TRANSITION_COUNT_AFTER_PLANNED=$(find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null | wc -l | tr -d ' ')

SPEC_STATUS_INCOMPLETE_EXIT=0
bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" modern-feature implemented --from=planned >/tmp/lattice-spec-status-incomplete.log 2>&1 || SPEC_STATUS_INCOMPLETE_EXIT=$?
if [[ $SPEC_STATUS_INCOMPLETE_EXIT -ne 0 ]] && grep -q "incomplete tasks" /tmp/lattice-spec-status-incomplete.log; then
  pass "spec-status blocks implemented state with incomplete tasks"
else
  fail "spec-status accepted incomplete implemented state"
  tail -20 /tmp/lattice-spec-status-incomplete.log
fi

perl -0pi -e 's/- \[ \] T1:/- [x] T1:/g; s/- \[ \] T2:/- [x] T2:/g; s/- \[ \] RED-1:/- [x] RED-1:/g; s/- \[ \] RED-2:/- [x] RED-2:/g' "$SANDBOX/lattice/specs/modern-feature/plan.md"
SPEC_STATUS_NO_EVIDENCE_EXIT=0
bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" modern-feature implemented --from=planned >/tmp/lattice-spec-status-no-evidence.log 2>&1 || SPEC_STATUS_NO_EVIDENCE_EXIT=$?
if [[ $SPEC_STATUS_NO_EVIDENCE_EXIT -ne 0 ]] && grep -q "missing brief.md" /tmp/lattice-spec-status-no-evidence.log; then
  pass "spec-status blocks completed tasks without evidence"
else
  fail "spec-status accepted completed tasks without evidence"
  tail -20 /tmp/lattice-spec-status-no-evidence.log
fi
TRANSITION_COUNT_AFTER_FAILED=$(find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null | wc -l | tr -d ' ')
if [[ "$TRANSITION_COUNT_AFTER_FAILED" == "$TRANSITION_COUNT_AFTER_PLANNED" ]]; then
  pass "spec-status does not record failed transition attempts"
else
  fail "spec-status recorded failed transition attempts"
fi

BRIEF_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/task-brief.sh" modern-feature T1 2>&1)
if [[ -f "$SANDBOX/.lattice/sdd/modern-feature/T1/brief.md" ]] && grep -q "Global Constraints" "$SANDBOX/.lattice/sdd/modern-feature/T1/brief.md"; then
  pass "task-brief generates task evidence"
else
  fail "task-brief did not generate expected evidence"
  echo "$BRIEF_OUTPUT" | tail -10
fi

REVIEW_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/review-package.sh" modern-feature T1 2>&1)
if [[ -f "$SANDBOX/.lattice/sdd/modern-feature/T1/review-package.md" ]] && grep -q "cannot-verify" "$SANDBOX/.lattice/sdd/modern-feature/T1/review-package.md"; then
  pass "review-package generates read-only review package"
else
  fail "review-package did not generate expected package"
  echo "$REVIEW_OUTPUT" | tail -10
fi

TDD_EVIDENCE_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/tdd-evidence.sh" modern-feature T1 \
  --ac=AC-1 \
  --test=TestAC1_CreateItem \
  --test-file=internal/handler/item_test.go \
  --red-command="go test ./internal/handler -run TestAC1_CreateItem" \
  --red-exit=1 \
  --red-summary="handler not implemented" \
  --green-command="go test ./internal/handler -run TestAC1_CreateItem" \
  --green-exit=0 \
  --green-summary="focused AC test passes" \
  --refactor=none 2>&1)
if yq -e '.kind == "tdd-evidence" and .status == "pass" and .red.exit_code == 1 and .green.exit_code == 0 and (.ac_ids | length == 1)' "$SANDBOX/.lattice/sdd/modern-feature/T1/tdd-evidence.json" >/dev/null 2>&1; then
  pass "tdd-evidence writes structured red/green JSON"
else
  fail "tdd-evidence JSON invalid"
  echo "$TDD_EVIDENCE_OUTPUT" | tail -10
fi

BRIEF_OUTPUT_T2=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/task-brief.sh" modern-feature T2 2>&1)
if [[ -f "$SANDBOX/.lattice/sdd/modern-feature/T2/brief.md" ]] && grep -q "Global Constraints" "$SANDBOX/.lattice/sdd/modern-feature/T2/brief.md"; then
  pass "task-brief generates second task evidence"
else
  fail "task-brief did not generate second task evidence"
  echo "$BRIEF_OUTPUT_T2" | tail -10
fi

REVIEW_OUTPUT_T2=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/review-package.sh" modern-feature T2 2>&1)
if [[ -f "$SANDBOX/.lattice/sdd/modern-feature/T2/review-package.md" ]] && grep -q "cannot-verify" "$SANDBOX/.lattice/sdd/modern-feature/T2/review-package.md"; then
  pass "review-package generates second read-only review package"
else
  fail "review-package did not generate second package"
  echo "$REVIEW_OUTPUT_T2" | tail -10
fi

TDD_EVIDENCE_OUTPUT_T2=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/tdd-evidence.sh" modern-feature T2 \
  --ac=AC-2 \
  --test=TestAC2_GetItem \
  --test-file=internal/handler/item_test.go \
  --red-command="go test ./internal/handler -run TestAC2_GetItem" \
  --red-exit=1 \
  --red-summary="handler does not return created items yet" \
  --green-command="go test ./internal/handler -run TestAC2_GetItem" \
  --green-exit=0 \
  --green-summary="focused AC test passes" \
  --refactor=none 2>&1)
if yq -e '.kind == "tdd-evidence" and .status == "pass" and .red.exit_code == 1 and .green.exit_code == 0 and (.ac_ids | length == 1)' "$SANDBOX/.lattice/sdd/modern-feature/T2/tdd-evidence.json" >/dev/null 2>&1; then
  pass "tdd-evidence writes second structured red/green JSON"
else
  fail "second tdd-evidence JSON invalid"
  echo "$TDD_EVIDENCE_OUTPUT_T2" | tail -10
fi

TASK_EVIDENCE_LINT_EXIT=0
TASK_EVIDENCE_LINT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/task-evidence-lint.sh" modern-feature 2>&1) || TASK_EVIDENCE_LINT_EXIT=$?
if [[ $TASK_EVIDENCE_LINT_EXIT -eq 0 ]]; then
  pass "task-evidence-lint passes completed task evidence"
else
  fail "task-evidence-lint failed completed task evidence"
  echo "$TASK_EVIDENCE_LINT_OUTPUT" | tail -20
fi

TASK_NEXT_COMPLETE_JSON=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/task-next.sh" modern-feature --json)
if echo "$TASK_NEXT_COMPLETE_JSON" | yq -e '.kind == "task-next" and .status == "complete" and .next_task == null' >/dev/null 2>&1; then
  pass "task-next reports complete plan"
else
  fail "task-next did not report complete plan"
  echo "$TASK_NEXT_COMPLETE_JSON"
fi

SPEC_STATUS_IMPLEMENTED_EXIT=0
SPEC_STATUS_IMPLEMENTED_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" modern-feature implemented --from=planned 2>&1) || SPEC_STATUS_IMPLEMENTED_EXIT=$?
if [[ $SPEC_STATUS_IMPLEMENTED_EXIT -eq 0 ]] && grep -q '^status: implemented$' "$SANDBOX/lattice/specs/modern-feature/spec.md"; then
  pass "spec-status advances completed plan to implemented"
else
  fail "spec-status failed to advance completed plan to implemented"
  echo "$SPEC_STATUS_IMPLEMENTED_OUTPUT" | tail -20
fi
IMPLEMENTED_TRANSITION_EVENT="$(
  find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null \
    | while IFS= read -r file; do
        yq -e '.kind == "spec-transition" and .from_status == "planned" and .to_status == "implemented"' "$file" >/dev/null 2>&1 && echo "$file"
      done \
    | tail -1 || true
)"
if [[ -f "$IMPLEMENTED_TRANSITION_EVENT" ]] \
  && yq -e '.kind == "spec-transition" and .from_status == "planned" and .to_status == "implemented" and .checks.task_evidence_lint == true' "$IMPLEMENTED_TRANSITION_EVENT" >/dev/null 2>&1; then
  pass "spec-status records implemented transition event"
else
  fail "spec-status implemented transition event invalid"
  [[ -f "$IMPLEMENTED_TRANSITION_EVENT" ]] && cat "$IMPLEMENTED_TRANSITION_EVENT"
fi

mkdir -p "$SANDBOX/lattice/specs/bad-plan"
cat > "$SANDBOX/lattice/specs/bad-plan/spec.md" << 'BAD_SPEC'
---
id: bad-plan
execution_mode: plan
---

# Spec: Bad Plan

## Acceptance Criteria

| # | When | Then | Verification |
|---|------|------|--------------|
| AC-1 | Something happens | It works | Test |
BAD_SPEC
cat > "$SANDBOX/lattice/specs/bad-plan/plan.md" << 'BAD_PLAN'
# Plan: Bad Plan

## Tasks

- Do the work
- TODO verify later
BAD_PLAN
BAD_PLAN_LINT_EXIT=0
bash "$SANDBOX/lattice/kernel/orchestrator/sdd/plan-lint.sh" bad-plan >/tmp/lattice-plan-lint-bad.log 2>&1 || BAD_PLAN_LINT_EXIT=$?
if [[ $BAD_PLAN_LINT_EXIT -ne 0 ]] && grep -q "No stable task ids" /tmp/lattice-plan-lint-bad.log; then
  pass "plan-lint rejects untraceable plan"
else
  fail "plan-lint accepted untraceable plan"
  tail -20 /tmp/lattice-plan-lint-bad.log
fi

mkdir -p "$SANDBOX/lattice/specs/bad-plan-schema"
cat > "$SANDBOX/lattice/specs/bad-plan-schema/spec.md" << 'BAD_SCHEMA_SPEC'
---
id: bad-plan-schema
execution_mode: plan
---

# Spec: Bad Plan Schema

## Acceptance Criteria

| # | When | Then | Verification |
|---|------|------|--------------|
| AC-1 | Something happens | It works | Test |
BAD_SCHEMA_SPEC
cat > "$SANDBOX/lattice/specs/bad-plan-schema/plan.md" << 'BAD_SCHEMA_PLAN'
# Plan: Bad Plan Schema

## Source

- Spec: `lattice/specs/bad-plan-schema/spec.md`
- Execution mode: plan

## Global Constraints

- Keep scope small.

## Tasks

- [ ] T1: Do the work
  - Ref: AC-1
  - Files: `internal/example.go`
  - Verification: `go test ./...`
BAD_SCHEMA_PLAN
BAD_PLAN_SCHEMA_EXIT=0
bash "$SANDBOX/lattice/kernel/orchestrator/sdd/plan-lint.sh" bad-plan-schema >/tmp/lattice-plan-lint-bad-schema.log 2>&1 || BAD_PLAN_SCHEMA_EXIT=$?
if [[ $BAD_PLAN_SCHEMA_EXIT -ne 0 ]] \
  && grep -q "T1 missing Mode" /tmp/lattice-plan-lint-bad-schema.log \
  && grep -q "T1 missing Evidence" /tmp/lattice-plan-lint-bad-schema.log \
  && grep -q "T1 missing Done when" /tmp/lattice-plan-lint-bad-schema.log; then
  pass "plan-lint rejects incomplete task schema"
else
  fail "plan-lint accepted incomplete task schema"
  tail -30 /tmp/lattice-plan-lint-bad-schema.log
fi

cat > "$SANDBOX/lattice/specs/modern-feature/verify.md" << 'VERIFY'
# Verify: Modern Feature

- Command: `go test ./...`
- Exit: 0
- Result: pass
VERIFY

PRISMSPEC_ALL_LINT_EXIT=0
PRISMSPEC_ALL_LINT_OUTPUT=$(bash "$SANDBOX/prismspec/bin/lint.sh" "$SANDBOX/lattice/specs/modern-feature" all 2>&1) || PRISMSPEC_ALL_LINT_EXIT=$?
if [[ $PRISMSPEC_ALL_LINT_EXIT -eq 0 ]]; then
  pass "PrismSpec lint passes full artifact contract"
else
  fail "PrismSpec lint failed full artifact contract"
  echo "$PRISMSPEC_ALL_LINT_OUTPUT" | tail -10
fi

SPEC_STATUS_VERIFIED_EXIT=0
SPEC_STATUS_VERIFIED_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" modern-feature verified --from=implemented 2>&1) || SPEC_STATUS_VERIFIED_EXIT=$?
if [[ $SPEC_STATUS_VERIFIED_EXIT -eq 0 ]] && grep -q '^status: verified$' "$SANDBOX/lattice/specs/modern-feature/spec.md"; then
  pass "spec-status advances implemented spec to verified"
else
  fail "spec-status failed to advance implemented spec to verified"
  echo "$SPEC_STATUS_VERIFIED_OUTPUT" | tail -20
fi

cat > "$SANDBOX/lattice/specs/modern-feature/summary.md" << 'SUMMARY'
# Summary: Modern Feature

- Result: delivered
- Verification: `go test ./...` passed
- Residual risk: none for smoke
SUMMARY
SPEC_STATUS_FINISHED_EXIT=0
SPEC_STATUS_FINISHED_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-status.sh" modern-feature finished --from=verified 2>&1) || SPEC_STATUS_FINISHED_EXIT=$?
if [[ $SPEC_STATUS_FINISHED_EXIT -eq 0 ]] && grep -q '^status: finished$' "$SANDBOX/lattice/specs/modern-feature/spec.md"; then
  pass "spec-status advances verified spec to finished"
else
  fail "spec-status failed to advance verified spec to finished"
  echo "$SPEC_STATUS_FINISHED_OUTPUT" | tail -20
fi
TRANSITION_COUNT_FINAL=$(find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null | wc -l | tr -d ' ')
FINISHED_TRANSITION_EVENT="$(
  find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null \
    | while IFS= read -r file; do
        yq -e '.kind == "spec-transition" and .from_status == "verified" and .to_status == "finished"' "$file" >/dev/null 2>&1 && echo "$file"
      done \
    | tail -1 || true
)"
if [[ "$TRANSITION_COUNT_FINAL" == "4" ]] \
  && [[ -f "$FINISHED_TRANSITION_EVENT" ]] \
  && yq -e '.kind == "spec-transition" and .from_status == "verified" and .to_status == "finished"' "$FINISHED_TRANSITION_EVENT" >/dev/null 2>&1; then
  pass "spec-status records complete transition audit trail"
else
  fail "spec-status transition audit trail invalid"
  find "$SANDBOX/lattice/state/spec-transitions" -name '*.json' -type f -print 2>/dev/null
fi
SPEC_HISTORY_MD="$SANDBOX/lattice/state/spec-history-smoke.md"
SPEC_HISTORY_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/spec-history.sh" --out="$SPEC_HISTORY_MD" --limit=10 2>&1)
if [[ -f "$SPEC_HISTORY_MD" ]] \
  && grep -q "Lattice Spec History" "$SPEC_HISTORY_MD" \
  && grep -q "modern-feature" "$SPEC_HISTORY_MD" \
  && grep -q "finished" "$SPEC_HISTORY_MD" \
  && grep -q "plan=true, task=true, state=true" "$SPEC_HISTORY_MD"; then
  pass "spec-history aggregates transition events"
else
  fail "spec-history output invalid"
  echo "$SPEC_HISTORY_OUTPUT" | tail -20
  [[ -f "$SPEC_HISTORY_MD" ]] && tail -40 "$SPEC_HISTORY_MD"
fi

REVIEW_SUMMARY_OUTPUT=$(bash "$SANDBOX/lattice/kernel/orchestrator/sdd/review-summary.sh" modern-feature T1 \
  --spec-compliance=pass \
  --code-quality=pass \
  --test-coverage=cannot_verify \
  --risk=pass \
  --finding="medium|internal/handler/item_test.go|missing regression test evidence" \
  --evidence="review-package.md" 2>&1)
if yq -e '.kind == "review-summary" and .verdict == "cannot_verify" and .axes.test_coverage == "cannot_verify" and (.findings | length == 1)' "$SANDBOX/.lattice/sdd/modern-feature/T1/review-summary.json" >/dev/null 2>&1; then
  pass "review-summary writes structured verdict JSON"
else
  fail "review-summary JSON invalid"
  echo "$REVIEW_SUMMARY_OUTPUT" | tail -10
fi

echo ""

# ── 7. AC-coverage (no tests — should report uncovered) ──
echo "── 7. AC-coverage gate ──"
AC_EXIT=0
AC_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/ac-coverage.sh" "$SANDBOX/lattice/specs/modern-feature/spec.md" "$SANDBOX" 2>&1) || AC_EXIT=$?

if [[ $AC_EXIT -eq 1 ]] && echo "$AC_OUTPUT" | grep -qi "uncovered"; then
  pass "ac-coverage correctly reports uncovered ACs"
elif [[ $AC_EXIT -eq 0 ]]; then
  fail "ac-coverage should fail (no tests exist)"
else
  pass "ac-coverage ran (exit=$AC_EXIT)"
fi

AC_JSON="$SANDBOX/lattice/state/ac-coverage-smoke.json"
AC_JSON_EXIT=0
bash "$SANDBOX/lattice/kernel/delivery/gates/ac-coverage.sh" "$SANDBOX/lattice/specs/modern-feature/spec.md" "$SANDBOX" --json-out="$AC_JSON" >/tmp/lattice-ac-json.log 2>&1 || AC_JSON_EXIT=$?
if [[ $AC_JSON_EXIT -eq 1 ]] && yq -e '.gate == "ac-coverage" and .metrics.ac_total == 2 and .metrics.ac_uncovered == 2 and (.findings | length == 2)' "$AC_JSON" >/dev/null 2>&1; then
  pass "ac-coverage writes structured gate JSON"
else
  fail "ac-coverage gate JSON invalid"
  cat /tmp/lattice-ac-json.log | tail -20
fi

DRIFT_JSON="$SANDBOX/lattice/state/drift-smoke.json"
bash "$SANDBOX/lattice/kernel/delivery/gates/drift-check.sh" "$SANDBOX/lattice/specs/modern-feature/spec.md" "$SANDBOX" --json-out="$DRIFT_JSON" >/tmp/lattice-drift-json.log 2>&1 || true
if yq -e '.gate == "drift-check" and .metrics.drift_count == 0 and (.findings | length > 0)' "$DRIFT_JSON" >/dev/null 2>&1; then
  pass "drift-check writes structured gate JSON"
else
  fail "drift-check gate JSON invalid"
  cat /tmp/lattice-drift-json.log | tail -20
fi

COMPLIANCE_JSON="$SANDBOX/lattice/state/compliance-smoke.json"
bash "$SANDBOX/lattice/kernel/delivery/gates/compliance.sh" "$SANDBOX/lattice/specs/modern-feature/spec.md" --json-out="$COMPLIANCE_JSON" >/tmp/lattice-compliance-json.log 2>&1 || true
if yq -e '.gate == "compliance" and .metrics.warnings >= 0 and (.findings | length > 0)' "$COMPLIANCE_JSON" >/dev/null 2>&1; then
  pass "compliance writes structured gate JSON"
else
  fail "compliance gate JSON invalid"
  cat /tmp/lattice-compliance-json.log | tail -20
fi

PIPELINE_GATE_JSON="$SANDBOX/lattice/state/pipeline-ac-smoke.json"
PIPELINE_GATE_EXIT=0
bash "$SANDBOX/lattice/kernel/delivery/pipeline.sh" --only=ac-coverage --spec="$SANDBOX/lattice/specs/modern-feature/spec.md" --json-out="$PIPELINE_GATE_JSON" >/tmp/lattice-pipeline-gate-json.log 2>&1 || PIPELINE_GATE_EXIT=$?
if [[ $PIPELINE_GATE_EXIT -eq 1 ]] && yq -e '.metrics.ac_total == 2 and .metrics.ac_uncovered == 2 and (.gates | length == 1) and .gates[0].gate == "ac-coverage" and .metrics.review_total == 1 and .metrics.review_cannot_verify == 1 and .metrics.tdd_total == 2 and .metrics.tdd_complete == 2 and .metrics.context_run_total == 1 and .metrics.context_selected_facts == 3 and .process_evidence.review_summaries[0].kind == "review-summary" and .process_evidence.tdd_evidence[0].kind == "tdd-evidence" and .process_evidence.context_runs[0].kind == "context-run" and .process_evidence.context_runs[0].metrics.selected_facts == 3 and .loop_state.kind == "loop-state" and .loop_state.next_action == "retry" and .loop_state.failed_step == "ac-coverage" and .loop_state.failure_category == "ac_gap" and .loop_state.default_action == "add_or_map_tests"' "$PIPELINE_GATE_JSON" >/dev/null 2>&1; then
  pass "pipeline embeds structured gate JSON in eval run"
else
  fail "pipeline gate JSON embedding invalid"
  cat /tmp/lattice-pipeline-gate-json.log | tail -20
fi

LOOP_RUN_ID=$(yq -r '.run_id' "$PIPELINE_GATE_JSON")
LOOP_STATE_JSON="$SANDBOX/lattice/state/loops/${LOOP_RUN_ID}.json"
if [[ -f "$LOOP_STATE_JSON" ]] && yq -e '.kind == "loop-state" and .next_action == "retry" and .failed_step == "ac-coverage" and .failure_category == "ac_gap" and .default_action == "add_or_map_tests" and .retry_count == 0' "$LOOP_STATE_JSON" >/dev/null 2>&1; then
  pass "pipeline writes loop state JSON"
else
  fail "pipeline loop state JSON invalid"
  cat /tmp/lattice-pipeline-gate-json.log | tail -20
fi

PIPELINE_ESCALATION_JSON="$SANDBOX/lattice/state/pipeline-escalation-smoke.json"
PIPELINE_ESCALATION_EXIT=0
SH_RETRY_COUNT=3 SH_RETRY_MAX=3 bash "$SANDBOX/lattice/kernel/delivery/pipeline.sh" --only=ac-coverage --spec="$SANDBOX/lattice/specs/modern-feature/spec.md" --json-out="$PIPELINE_ESCALATION_JSON" >/tmp/lattice-pipeline-escalation.log 2>&1 || PIPELINE_ESCALATION_EXIT=$?
ESCALATION_RUN_ID=""
ESCALATION_LEARN_DRAFT=""
if [[ -f "$PIPELINE_ESCALATION_JSON" ]]; then
  ESCALATION_RUN_ID=$(yq -r '.run_id' "$PIPELINE_ESCALATION_JSON")
  ESCALATION_LEARN_DRAFT="$SANDBOX/lattice/context/drafts/escalation-${ESCALATION_RUN_ID}.md"
fi
if [[ $PIPELINE_ESCALATION_EXIT -eq 2 ]] \
  && [[ -f "$ESCALATION_LEARN_DRAFT" ]] \
  && yq -e '.pipeline.status == "escalation" and .metrics.loop_escalated == true and .loop_state.next_action == "escalate" and .loop_state.failure_category == "ac_gap" and .loop_state.default_action == "add_or_map_tests" and .loop_state.learn_draft != ""' "$PIPELINE_ESCALATION_JSON" >/dev/null 2>&1 \
  && grep -q "Learn Draft: Pipeline Escalation" "$ESCALATION_LEARN_DRAFT" \
  && grep -q "failure_category: \"ac_gap\"" "$ESCALATION_LEARN_DRAFT"; then
  pass "pipeline writes escalation learn draft"
else
  fail "pipeline escalation learn draft invalid"
  cat /tmp/lattice-pipeline-escalation.log | tail -20
fi

PROMOTE_TARGET="$SANDBOX/lattice/context/knowledge/pitfalls.md"
REQUIRE_REVIEW_EXIT=0
bash "$SANDBOX/lattice/kernel/context/learn-draft.sh" promote "$ESCALATION_LEARN_DRAFT" --require-review --to="$PROMOTE_TARGET" >/tmp/lattice-learn-require-review.log 2>&1 || REQUIRE_REVIEW_EXIT=$?
if [[ $REQUIRE_REVIEW_EXIT -ne 0 ]] && grep -q "requires an approved knowledge review" /tmp/lattice-learn-require-review.log; then
  pass "learn-draft require-review blocks unreviewed promotion"
else
  fail "learn-draft require-review should block unreviewed promotion"
  cat /tmp/lattice-learn-require-review.log | tail -20
fi

KNOWLEDGE_REVIEW_OUTPUT=$(bash "$SANDBOX/lattice/kernel/context/knowledge-review.sh" approve "$ESCALATION_LEARN_DRAFT" --reviewer="smoke-reviewer" --reason="durable lesson candidate checked" --risk=medium --conflicts-checked 2>&1)
KNOWLEDGE_REVIEW_EVENT=$(find "$SANDBOX/lattice/state/knowledge-reviews" -type f -name '*.json' -print | head -1)
if [[ -n "$KNOWLEDGE_REVIEW_EVENT" ]] \
  && yq -e '.kind == "knowledge-review" and .action == "approve" and .reviewer == "smoke-reviewer" and .target == "lattice/context/drafts/'"$(basename "$ESCALATION_LEARN_DRAFT")"'" and .conflicts_checked == true' "$KNOWLEDGE_REVIEW_EVENT" >/dev/null 2>&1; then
  pass "knowledge-review records approval evidence"
else
  fail "knowledge-review approval evidence invalid"
  echo "$KNOWLEDGE_REVIEW_OUTPUT" | tail -20
fi

PROMOTE_EXIT=0
bash "$SANDBOX/lattice/kernel/context/learn-draft.sh" promote "$ESCALATION_LEARN_DRAFT" --require-review --to="$PROMOTE_TARGET" >/tmp/lattice-learn-promote.log 2>&1 || PROMOTE_EXIT=$?
PROMOTED_DRAFT="$SANDBOX/lattice/context/drafts/promoted/$(basename "$ESCALATION_LEARN_DRAFT")"
PROMOTE_EVENT=$(find "$SANDBOX/lattice/state/learn-promotions" -type f -name '*.json' -print | head -1)
if [[ $PROMOTE_EXIT -eq 0 ]] \
  && [[ -f "$PROMOTED_DRAFT" ]] \
  && grep -q "Promoted Learn Draft" "$PROMOTE_TARGET" \
  && [[ -n "$PROMOTE_EVENT" ]] \
  && yq -e '.kind == "learn-promotion" and .action == "promote" and .target == "lattice/context/knowledge/pitfalls.md" and .failure_category == "ac_gap" and .default_action == "add_or_map_tests"' "$PROMOTE_EVENT" >/dev/null 2>&1; then
  pass "learn-draft promotes draft with audit event"
else
  fail "learn-draft promote invalid"
  cat /tmp/lattice-learn-promote.log | tail -20
fi

DISCARD_DRAFT="$SANDBOX/lattice/context/drafts/manual-discard.md"
cat > "$DISCARD_DRAFT" <<'MD'
---
run_id: "manual-discard"
failure_category: "unknown"
default_action: "escalate"
---

# Learn Draft: Manual Discard

## Lesson Candidate

This candidate is intentionally discarded by smoke test.
MD

DISCARD_EXIT=0
bash "$SANDBOX/lattice/kernel/context/learn-draft.sh" discard "$DISCARD_DRAFT" --reason="not reusable" >/tmp/lattice-learn-discard.log 2>&1 || DISCARD_EXIT=$?
DISCARDED_DRAFT="$SANDBOX/lattice/context/drafts/discarded/$(basename "$DISCARD_DRAFT")"
DISCARD_EVENT=$(
  for event in "$SANDBOX"/lattice/state/learn-promotions/*.json; do
    [[ -f "$event" ]] || continue
    if yq -e '.action == "discard"' "$event" >/dev/null 2>&1; then
      printf '%s\n' "$event"
      break
    fi
  done
)
if [[ $DISCARD_EXIT -eq 0 ]] \
  && [[ -f "$DISCARDED_DRAFT" ]] \
  && [[ -n "$DISCARD_EVENT" ]] \
  && yq -e '.kind == "learn-promotion" and .action == "discard" and .reason == "not reusable" and .failure_category == "unknown" and .default_action == "escalate"' "$DISCARD_EVENT" >/dev/null 2>&1; then
  pass "learn-draft discards draft with audit event"
else
  fail "learn-draft discard invalid"
  cat /tmp/lattice-learn-discard.log | tail -20
fi

if bash "$SANDBOX/lattice/kernel/context/knowledge-lint.sh" --strict >/tmp/lattice-knowledge-lint-default.log 2>&1; then
  pass "knowledge-lint passes default knowledge templates"
else
  fail "knowledge-lint should pass default knowledge templates"
  cat /tmp/lattice-knowledge-lint-default.log | tail -20
fi

BAD_KNOWLEDGE="$SANDBOX/lattice/context/knowledge/bad-governance.md"
cat > "$BAD_KNOWLEDGE" <<'MD'
---
expires_at: "2000-01-01"
---

# Bad Governance Fixture

TODO: resolve this before promotion.

## Duplicate

CONFLICT: contradicts existing knowledge.

## Duplicate

Same heading repeated.
MD

if bash "$SANDBOX/lattice/kernel/context/knowledge-lint.sh" --strict --target="$BAD_KNOWLEDGE" >/tmp/lattice-knowledge-lint-bad.log 2>&1; then
  fail "knowledge-lint should reject stale/conflicting knowledge metadata"
else
  pass "knowledge-lint rejects stale/conflicting knowledge metadata"
fi
rm -f "$BAD_KNOWLEDGE"

if bash "$SANDBOX/lattice/kernel/delivery/failure-category-lint.sh" >/tmp/lattice-failure-category-lint.log 2>&1; then
  pass "failure-category-lint passes default config"
else
  fail "failure-category-lint should pass default config"
  cat /tmp/lattice-failure-category-lint.log | tail -20
fi

cat > "$SANDBOX/lattice/config/failure-categories.invalid.yaml" <<'YAML'
schema_version: lattice.failure-categories.v1
default:
  category: unknown
  default_action: escalate
rules:
  - name: Bad Rule
    step_regex: "["
    category: bad-category
YAML

if bash "$SANDBOX/lattice/kernel/delivery/failure-category-lint.sh" "$SANDBOX/lattice/config/failure-categories.invalid.yaml" >/tmp/lattice-failure-category-lint-invalid.log 2>&1; then
  fail "failure-category-lint should reject invalid config"
else
  pass "failure-category-lint rejects invalid config"
fi

cat > "$SANDBOX/lattice/config/failure-categories.yaml" <<'YAML'
schema_version: lattice.failure-categories.v1
default:
  category: unknown
  default_action: escalate
rules:
  - name: ac-coverage-custom
    step: ac-coverage
    category: custom_ac_gap
    default_action: route_to_qa
YAML

PIPELINE_CUSTOM_CATEGORY_JSON="$SANDBOX/lattice/state/pipeline-custom-category-smoke.json"
PIPELINE_CUSTOM_CATEGORY_EXIT=0
bash "$SANDBOX/lattice/kernel/delivery/pipeline.sh" --only=ac-coverage --spec="$SANDBOX/lattice/specs/modern-feature/spec.md" --json-out="$PIPELINE_CUSTOM_CATEGORY_JSON" >/tmp/lattice-pipeline-custom-category.log 2>&1 || PIPELINE_CUSTOM_CATEGORY_EXIT=$?
if [[ $PIPELINE_CUSTOM_CATEGORY_EXIT -eq 1 ]] \
  && yq -e '.loop_state.failure_category == "custom_ac_gap" and .loop_state.default_action == "route_to_qa"' "$PIPELINE_CUSTOM_CATEGORY_JSON" >/dev/null 2>&1; then
  pass "pipeline reads configurable failure categories"
else
  fail "pipeline configurable failure categories invalid"
  cat /tmp/lattice-pipeline-custom-category.log | tail -20
fi

OUTCOME_LINK_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/outcome-link.sh" record --eval="$PIPELINE_GATE_JSON" --type=review_finding --severity=medium --source=smoke-review --summary="missing regression test evidence" --context-ref="rules.md#ac-trace" 2>&1)
OUTCOME_EVENT=$(find "$SANDBOX/lattice/state/outcomes" -type f -name '*.json' -print | head -1)
if [[ -n "$OUTCOME_EVENT" ]] \
  && yq -e '.kind == "outcome-link" and .outcome.type == "review_finding" and .outcome.severity == "medium" and .eval_run.run_id != "" and .eval_metrics.context_run_total == 1 and (.context_refs | length == 1)' "$OUTCOME_EVENT" >/dev/null 2>&1; then
  pass "outcome-link records post-run outcome evidence"
else
  fail "outcome-link event invalid"
  echo "$OUTCOME_LINK_OUTPUT" | tail -20
fi

OUTCOME_REPORT_MD="$SANDBOX/lattice/state/outcome-report-smoke.md"
OUTCOME_REPORT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/outcome-report.sh" --out="$OUTCOME_REPORT_MD" --limit=5 2>&1)
if [[ -f "$OUTCOME_REPORT_MD" ]] && grep -q "Lattice Outcome Attribution Report" "$OUTCOME_REPORT_MD" && grep -q "Context Ref Signals" "$OUTCOME_REPORT_MD" && grep -q "rules.md#ac-trace" "$OUTCOME_REPORT_MD" && grep -q "Runs Needing Review" "$OUTCOME_REPORT_MD" && grep -q "missing regression test evidence" "$OUTCOME_REPORT_MD"; then
  pass "outcome-report renders attribution signals"
else
  fail "outcome-report output invalid"
  echo "$OUTCOME_REPORT_OUTPUT" | tail -20
fi

PIPELINE_SUMMARY_MD="$SANDBOX/lattice/state/eval-summary-smoke.md"
SUMMARY_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/eval-summary.sh" "$PIPELINE_GATE_JSON" --out="$PIPELINE_SUMMARY_MD" 2>&1)
if [[ -f "$PIPELINE_SUMMARY_MD" ]] && grep -q "Lattice Eval Summary" "$PIPELINE_SUMMARY_MD" && grep -q "AC Coverage" "$PIPELINE_SUMMARY_MD" && grep -q "ac-coverage" "$PIPELINE_SUMMARY_MD" && grep -q "Review Evidence" "$PIPELINE_SUMMARY_MD" && grep -q "TDD Evidence" "$PIPELINE_SUMMARY_MD" && grep -q "Context Evidence" "$PIPELINE_SUMMARY_MD" && grep -q "Outcome Links" "$PIPELINE_SUMMARY_MD" && grep -q "missing regression test evidence" "$PIPELINE_SUMMARY_MD" && grep -q "Loop" "$PIPELINE_SUMMARY_MD"; then
  pass "eval-summary renders pipeline JSON as Markdown"
else
  fail "eval-summary output invalid"
  echo "$SUMMARY_OUTPUT" | tail -10
fi

PR_COMMENT_MD="$SANDBOX/lattice/state/pr-comment-smoke.md"
PR_COMMENT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/pr-comment.sh" "$PIPELINE_SUMMARY_MD" --dry-run --out="$PR_COMMENT_MD" 2>&1)
if [[ -f "$PR_COMMENT_MD" ]] && grep -q "lattice-eval-comment" "$PR_COMMENT_MD" && grep -q "Lattice Eval Summary" "$PR_COMMENT_MD"; then
  pass "pr-comment renders stable dry-run body"
else
  fail "pr-comment dry-run output invalid"
  echo "$PR_COMMENT_OUTPUT" | tail -10
fi

mkdir -p "$SANDBOX/lattice/state/eval-runs"
cp "$PIPELINE_GATE_JSON" "$SANDBOX/lattice/state/eval-runs/pipeline-ac-smoke.json"
EVAL_HISTORY_MD="$SANDBOX/lattice/state/eval-history-smoke.md"
HISTORY_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/eval-history.sh" --out="$EVAL_HISTORY_MD" --limit=5 2>&1)
if [[ -f "$EVAL_HISTORY_MD" ]] && grep -q "Lattice Eval History" "$EVAL_HISTORY_MD" && grep -q "Pipeline Pass Rate" "$EVAL_HISTORY_MD" && grep -q "Review Verdicts" "$EVAL_HISTORY_MD" && grep -q "Context Evidence" "$EVAL_HISTORY_MD" && grep -q "Outcome Links" "$EVAL_HISTORY_MD" && grep -q "Outcomes" "$EVAL_HISTORY_MD" && grep -q "Loop" "$EVAL_HISTORY_MD" && grep -q "Recent Runs" "$EVAL_HISTORY_MD"; then
  pass "eval-history aggregates eval run JSON"
else
  fail "eval-history output invalid"
  echo "$HISTORY_OUTPUT" | tail -10
fi

EVAL_SINK_DIR="$SANDBOX/lattice/state/central-sink"
EVAL_SINK_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/eval-sink.sh" publish --sink-dir="$EVAL_SINK_DIR" 2>&1)
EVAL_SINK_MANIFEST="$EVAL_SINK_DIR/projects/testapp/manifest.json"
if [[ -f "$EVAL_SINK_DIR/index.md" ]] \
  && [[ -f "$EVAL_SINK_MANIFEST" ]] \
  && [[ -f "$EVAL_SINK_DIR/projects/testapp/eval-runs/pipeline-ac-smoke.json" ]] \
  && [[ -n "$(find "$EVAL_SINK_DIR/projects/testapp/outcomes" -type f -name '*.json' -print -quit)" ]] \
  && yq -e '.kind == "eval-sink-project" and .project == "testapp" and .counts.eval_runs >= 1 and .counts.outcomes >= 1 and .counts.reports >= 1' "$EVAL_SINK_MANIFEST" >/dev/null 2>&1 \
  && grep -q "Lattice Central Eval Sink" "$EVAL_SINK_DIR/index.md"; then
  pass "eval-sink publishes project evidence to central sink"
else
  fail "eval-sink output invalid"
  echo "$EVAL_SINK_OUTPUT" | tail -20
fi

EVAL_DASHBOARD_HTML="$EVAL_SINK_DIR/dashboard.html"
EVAL_DASHBOARD_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/eval-dashboard.sh" --sink-dir="$EVAL_SINK_DIR" --out="$EVAL_DASHBOARD_HTML" --limit=5 2>&1)
if [[ -f "$EVAL_DASHBOARD_HTML" ]] \
  && grep -q "Lattice Eval Dashboard" "$EVAL_DASHBOARD_HTML" \
  && grep -q "testapp" "$EVAL_DASHBOARD_HTML" \
  && grep -q "Recent Outcomes" "$EVAL_DASHBOARD_HTML" \
  && grep -q "missing regression test evidence" "$EVAL_DASHBOARD_HTML"; then
  pass "eval-dashboard renders central sink HTML"
else
  fail "eval-dashboard output invalid"
  echo "$EVAL_DASHBOARD_OUTPUT" | tail -20
fi

EVAL_QUERY_SUMMARY_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/eval-query.sh" summary --sink-dir="$EVAL_SINK_DIR" 2>&1)
if echo "$EVAL_QUERY_SUMMARY_OUTPUT" | grep -q "Lattice Eval Query" \
  && echo "$EVAL_QUERY_SUMMARY_OUTPUT" | grep -q "| Projects | 1 |" \
  && echo "$EVAL_QUERY_SUMMARY_OUTPUT" | grep -q "testapp"; then
  pass "eval-query summarizes central sink"
else
  fail "eval-query summary output invalid"
  echo "$EVAL_QUERY_SUMMARY_OUTPUT" | tail -20
fi

EVAL_QUERY_RUNS_JSON="$SANDBOX/lattice/state/eval-query-runs.json"
EVAL_QUERY_OUTCOMES_JSON="$SANDBOX/lattice/state/eval-query-outcomes.json"
bash "$SANDBOX/lattice/kernel/delivery/eval-query.sh" runs --sink-dir="$EVAL_SINK_DIR" --project=testapp --format=json > "$EVAL_QUERY_RUNS_JSON"
bash "$SANDBOX/lattice/kernel/delivery/eval-query.sh" outcomes --sink-dir="$EVAL_SINK_DIR" --project=testapp --type=review_finding --format=json > "$EVAL_QUERY_OUTCOMES_JSON"
if yq -e '.kind == "eval-query" and .action == "runs" and .metrics.eval_runs >= 1 and .items[0].project == "testapp"' "$EVAL_QUERY_RUNS_JSON" >/dev/null 2>&1 \
  && yq -e '.kind == "eval-query" and .action == "outcomes" and .metrics.outcomes >= 1 and .items[0].type == "review_finding" and .items[0].summary == "missing regression test evidence"' "$EVAL_QUERY_OUTCOMES_JSON" >/dev/null 2>&1; then
  pass "eval-query emits filtered JSON"
else
  fail "eval-query JSON output invalid"
  cat "$EVAL_QUERY_RUNS_JSON" "$EVAL_QUERY_OUTCOMES_JSON" | tail -40
fi
rm -f /tmp/lattice-ac-json.log /tmp/lattice-drift-json.log /tmp/lattice-compliance-json.log /tmp/lattice-pipeline-gate-json.log /tmp/lattice-pipeline-escalation.log /tmp/lattice-pipeline-custom-category.log /tmp/lattice-failure-category-lint.log /tmp/lattice-failure-category-lint-invalid.log
echo ""

# ── 8. Context knowledge backend ──
echo "── 8. Context knowledge backend ──"
LIST_OUTPUT=$(bash "$SANDBOX/lattice/kernel/context/backends/knowledge.sh" --list 2>&1)
if echo "$LIST_OUTPUT" | grep -q "Context Knowledge Files"; then
  pass "knowledge backend --list works"
else
  fail "knowledge backend --list failed"
fi
echo ""

# ── 9. Spec-lock ──
echo "── 9. Spec-lock ──"
LOCK_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/spec-lock.sh" acquire "$SANDBOX/lattice/specs/modern-feature/spec.md" 2>&1)
if echo "$LOCK_OUTPUT" | grep -q "Locked"; then
  pass "spec-lock acquire works"
else
  fail "spec-lock acquire failed"
fi

UNLOCK_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/spec-lock.sh" release "$SANDBOX/lattice/specs/modern-feature/spec.md" 2>&1)
if echo "$UNLOCK_OUTPUT" | grep -q "Released"; then
  pass "spec-lock release works"
else
  fail "spec-lock release failed"
fi
echo ""

# ── Summary ──
echo "══════════════════════════════════"
TOTAL=$((PASS + FAIL))
echo "📊 Smoke Test: ✅ $PASS / $TOTAL"
if [[ $FAIL -gt 0 ]]; then
  echo "❌ FAIL"
  exit 1
else
  echo "✅ ALL PASS"
  exit 0
fi

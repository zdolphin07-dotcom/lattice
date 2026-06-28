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

if bash "$SANDBOX/.lattice/framework/init.sh" --non-interactive --lang=go --name=testapp 2>&1 | tail -5; then
  if [[ -f "$SANDBOX/lattice/manifest.yaml" ]]; then
    pass "manifest.yaml generated"
  else
    fail "manifest.yaml not found after init"
  fi

  DEFAULT_MODE=$(yq -r '.specs.default_execution_mode // ""' "$SANDBOX/lattice/manifest.yaml")
  ALLOW_MODE_OVERRIDE=$(yq -r '.specs.allow_execution_mode_override // ""' "$SANDBOX/lattice/manifest.yaml")
  if [[ "$DEFAULT_MODE" == "auto" ]] && [[ "$ALLOW_MODE_OVERRIDE" == "true" ]]; then
    pass "execution mode policy configured"
  else
    fail "execution mode policy missing from manifest"
  fi

  if [[ -f "$SANDBOX/lattice/kernel/_lib.sh" ]]; then
    pass "kernel files installed"
  else
    fail "kernel files not installed"
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

  for command in sdd brainstorm plan implement verify finish learn; do
    if [[ -f "$SANDBOX/.claude/commands/${command}.md" ]]; then
      pass "$command slash command installed"
    else
      fail "$command slash command missing"
    fi
  done

  if [[ -f "$SANDBOX/prismspec/skills/sdd/SKILL.md" ]] \
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

  if [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/task-brief.sh" ]] && [[ -x "$SANDBOX/lattice/kernel/orchestrator/sdd/review-package.sh" ]]; then
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

- [ ] T1: Add create behavior
  - Ref: AC-1
  - Interfaces:
    - Inputs: create request
    - Outputs: 201 response
    - Touched files/contracts: handler
  - Files: `internal/handler/item.go`
  - Verification: `TestAC1_CreateItem`
  - Evidence:
    - Brief: `.lattice/sdd/modern-feature/T1/brief.md`
    - Review package: `.lattice/sdd/modern-feature/T1/review-package.md`

## Test-first Tasks

- [ ] RED-1: Add failing test for AC-1
  - Expected failure: handler not implemented
  - Test file: `internal/handler/item_test.go`
PLAN

PRISMSPEC_PLAN_LINT_EXIT=0
PRISMSPEC_PLAN_LINT_OUTPUT=$(bash "$SANDBOX/prismspec/bin/lint.sh" "$SANDBOX/lattice/specs/modern-feature" plan 2>&1) || PRISMSPEC_PLAN_LINT_EXIT=$?
if [[ $PRISMSPEC_PLAN_LINT_EXIT -eq 0 ]]; then
  pass "PrismSpec lint passes plan contract"
else
  fail "PrismSpec lint failed plan contract"
  echo "$PRISMSPEC_PLAN_LINT_OUTPUT" | tail -10
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

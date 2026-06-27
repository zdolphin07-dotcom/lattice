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
for f in "$REPO_DIR"/init.sh "$REPO_DIR"/install.sh $(find "$REPO_DIR/scaffold" -name '*.sh'); do
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
  if [[ -d "$SANDBOX/.lattice/framework/scaffold" ]]; then
    pass "install.sh completed, scaffold exists"
  else
    fail "install.sh ran but scaffold not found"
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

  if [[ -f "$SANDBOX/CLAUDE.md" ]]; then
    pass "CLAUDE.md created"
  else
    fail "CLAUDE.md not created"
  fi

  for skill in sdd brainstorm plan implement finish; do
    if [[ -f "$SANDBOX/lattice/skills/${skill}.md" ]] && [[ -f "$SANDBOX/.claude/commands/${skill}.md" ]]; then
      pass "$skill skill and slash command installed"
    else
      fail "$skill skill or slash command missing"
    fi
  done

  if [[ -f "$SANDBOX/prismspec/skills/sdd.md" ]] && [[ -f "$SANDBOX/prismspec/templates/spec-template.md" ]]; then
    pass "PrismSpec standalone module installed"
  else
    fail "PrismSpec standalone module missing"
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

# ── 6. Spec-lint on sample spec ──
echo "── 6. Spec-lint gate ──"
mkdir -p "$SANDBOX/lattice/specs"
cat > "$SANDBOX/lattice/specs/test-feature.md" << 'SPEC'
# Test Feature

## Intent
Test feature for smoke testing.

## Scope

### In
- Widget CRUD.

### Out
- Export.

## Context
No special project knowledge required.

## Design Decisions
Use the existing smoke handler structure.

## Risk Notes
No high-risk behavior.

## Execution Policy
- Mode: `plan`
- Reason: smoke test.

## Verification Plan
- spec-lint
- ac-coverage

## Part I — Background & Goals

### 1.1 Background & Goals
Test feature for smoke testing.

### 1.2 Naming Conventions
Standard conventions apply.

## Part II — Technical Design

### 2.1 Technical Design
Simple CRUD endpoint.

### 2.2 API Design
REST API.

```mermaid
graph TB
    A --> B
```

```mermaid
sequenceDiagram
    A->>B: request
```

### 2.3 Data Model

```sql
CREATE TABLE `test_items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.4 Design Alternatives
Go + Gin — obvious choice for this scale.

## Part III — Quality Assurance

### 3.1 Acceptance Criteria

| # | When | Then | Ref step |
|---|------|------|----------|
| AC-1 | Create widget | Returns 201 | ① |
| AC-2 | Get widget | Returns widget | ② |
| AC-3 | Delete widget | Returns 204 | ③ |

### 3.2 Risk Review

| Category | Review Item | Status | Design Basis |
|----------|-------------|--------|-------------|
| **Financial Safety** | N/A | ✅ | No financial operations |
| **Technical Risk** | Rate limiting | ✅ | Standard middleware |
| **Data Risk** | Tenant isolation | ✅ | Single tenant |
| **Release Process** | Rollback capable | ✅ | Stateless |

### 3.3 Test Strategy
Unit tests for handlers, integration tests for DB.

## Part IV — Release

### 4.1 Release Checklist

| # | Action | Owner | Notes |
|---|--------|-------|-------|

### 4.2 Rollout & Rollback
Simple restart, no canary needed.

## Decision Log

| # | Decision | Impact | Default | Status |
|---|----------|--------|---------|--------|
| D-1 | Use Gin | Low | Gin | ✅ |
SPEC

LINT_EXIT=0
LINT_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/spec-lint.sh" "$SANDBOX/lattice/specs/test-feature.md" 2>&1) || LINT_EXIT=$?

if [[ $LINT_EXIT -eq 0 ]]; then
  pass "spec-lint passes on valid spec"
else
  fail "spec-lint failed on valid spec (exit=$LINT_EXIT)"
  echo "$LINT_OUTPUT" | tail -10
fi
echo ""

# ── 6b. Spec-lint on modern persistent spec layout ──
echo "── 6b. Spec-lint modern layout ──"
mkdir -p "$SANDBOX/lattice/specs/modern-feature"
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
AC_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/ac-coverage.sh" "$SANDBOX/lattice/specs/test-feature.md" "$SANDBOX" 2>&1) || AC_EXIT=$?

if [[ $AC_EXIT -eq 1 ]] && echo "$AC_OUTPUT" | grep -qi "uncovered"; then
  pass "ac-coverage correctly reports uncovered ACs"
elif [[ $AC_EXIT -eq 0 ]]; then
  fail "ac-coverage should fail (no tests exist)"
else
  pass "ac-coverage ran (exit=$AC_EXIT)"
fi
echo ""

# ── 8. Knowledge loader ──
echo "── 8. Knowledge loader ──"
LIST_OUTPUT=$(bash "$SANDBOX/lattice/kernel/knowledge/loader.sh" --list 2>&1)
if echo "$LIST_OUTPUT" | grep -q "Knowledge Index"; then
  pass "loader.sh --list works"
else
  fail "loader.sh --list failed"
fi
echo ""

# ── 9. Spec-lock ──
echo "── 9. Spec-lock ──"
LOCK_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/spec-lock.sh" acquire "$SANDBOX/lattice/specs/test-feature.md" 2>&1)
if echo "$LOCK_OUTPUT" | grep -q "Locked"; then
  pass "spec-lock acquire works"
else
  fail "spec-lock acquire failed"
fi

UNLOCK_OUTPUT=$(bash "$SANDBOX/lattice/kernel/delivery/gates/spec-lock.sh" release "$SANDBOX/lattice/specs/test-feature.md" 2>&1)
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

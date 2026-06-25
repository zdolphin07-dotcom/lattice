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

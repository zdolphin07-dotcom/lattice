#!/usr/bin/env bash
# doctor.sh - PrismSpec standalone health check.
# Checks the skill pack contract and guide protocol without requiring Lattice.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRISMSPEC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$PRISMSPEC_ROOT/.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)) || true; printf "  ✅ %s\n" "$*"; }
fail() { ((FAIL++)) || true; printf "  ❌ %s\n" "$*"; }
warn() { ((WARN++)) || true; printf "  ⚠️  %s\n" "$*"; }
info() { printf "  ℹ️  %s\n" "$*"; }

check_file() {
  local path="$1" label="$2"
  [[ -f "$path" ]] && pass "$label" || fail "Missing $label: $path"
}

check_executable() {
  local path="$1" label="$2"
  if [[ -x "$path" ]]; then
    pass "$label"
  elif [[ -f "$path" ]]; then
    fail "$label is not executable: $path"
  else
    fail "Missing $label: $path"
  fi
}

check_command() {
  local label="$1"
  shift
  local output
  if output="$("$@" 2>&1)"; then
    pass "$label"
  else
    fail "$label failed"
    echo "$output" | tail -10 | sed 's/^/    /'
  fi
}

echo "══════════════════════════════════"
echo "PrismSpec — Doctor"
echo "Root: $PRISMSPEC_ROOT"
echo "Host: $([[ -f "$PROJECT_ROOT/lattice/manifest.yaml" ]] && echo "lattice-hosted" || echo "standalone")"
echo "══════════════════════════════════"
echo ""

echo "── Runtime ──"
if [[ -n "${BASH_VERSION:-}" ]]; then
  pass "bash"
else
  fail "bash runtime"
fi

if command -v git >/dev/null 2>&1; then
  pass "git"
else
  warn "git not found; PrismSpec can run, but review and changed-file checks are weaker"
fi

if [[ -f "$PROJECT_ROOT/lattice/manifest.yaml" ]]; then
  if command -v yq >/dev/null 2>&1; then
    pass "yq for Lattice-hosted mode"
  else
    fail "Missing yq for Lattice-hosted mode"
  fi
elif ! command -v yq >/dev/null 2>&1; then
  warn "yq not found; standalone PrismSpec still works"
else
  pass "yq"
fi
echo ""

echo "── Skill pack contract ──"
check_file "$PRISMSPEC_ROOT/skillpack.yaml" "skillpack manifest"
check_file "$PRISMSPEC_ROOT/commands/prismspec.md" "PrismSpec command"
check_executable "$PRISMSPEC_ROOT/bin/new.sh" "new"
check_executable "$PRISMSPEC_ROOT/bin/guide.sh" "guide"
check_executable "$PRISMSPEC_ROOT/bin/lint.sh" "lint"
check_executable "$PRISMSPEC_ROOT/bin/eval-skills.sh" "skill eval"
check_command "skillpack contract lint" bash "$PRISMSPEC_ROOT/bin/lint.sh" "$PRISMSPEC_ROOT" skillpack
check_command "skill eval" bash "$PRISMSPEC_ROOT/bin/eval-skills.sh" --root="$PRISMSPEC_ROOT" --all
echo ""

echo "── Guide protocol ──"
GUIDE_OUTPUT=""
if GUIDE_OUTPUT="$(cd "$PROJECT_ROOT" && bash "$PRISMSPEC_ROOT/bin/guide.sh" --json 2>&1)"; then
  pass "guide --json executes"
  echo "$GUIDE_OUTPUT" | grep -q '"host"' && pass "guide JSON host field" || fail "guide JSON missing host field"
  echo "$GUIDE_OUTPUT" | grep -q '"stage"' && pass "guide JSON stage field" || fail "guide JSON missing stage field"
  echo "$GUIDE_OUTPUT" | grep -q '"skill"' && pass "guide JSON skill field" || fail "guide JSON missing skill field"
else
  fail "guide --json failed"
  echo "$GUIDE_OUTPUT" | tail -10 | sed 's/^/    /'
fi
echo ""

echo "── Host artifacts ──"
if [[ -f "$PROJECT_ROOT/lattice/manifest.yaml" ]]; then
  check_file "$PROJECT_ROOT/lattice/manifest.yaml" "Lattice manifest"
  [[ -d "$PROJECT_ROOT/lattice/specs" ]] && pass "Lattice spec root" || info "Lattice spec root not created yet; create the first spec with new.sh"
else
  [[ -d "$PRISMSPEC_ROOT/specs" ]] && pass "standalone spec root" || info "standalone spec root not created yet; create the first spec with new.sh"
fi
echo ""

echo "══════════════════════════════════"
printf "PrismSpec Doctor: ✅ %d" "$PASS"
printf "  ❌ %d" "$FAIL"
printf "  ⚠️  %d\n" "$WARN"
if [[ "$FAIL" -eq 0 ]]; then
  echo "✅ PASS"
  exit 0
fi
echo "❌ FAIL"
exit 1

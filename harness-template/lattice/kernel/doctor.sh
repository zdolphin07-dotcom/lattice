#!/usr/bin/env bash
# doctor.sh — Lattice installation health check
source "$(dirname "$0")/_lib.sh"

echo "══════════════════════════════════"
echo "Lattice — Doctor"
echo "Project: $(manifest_get '.project.name') ($(get_language))"
echo "══════════════════════════════════"
echo ""

check_file() {
  local path="$1" label="${2:-$1}"
  if [[ -f "$PROJECT_ROOT/$path" ]]; then
    pass "$label"
  else
    fail "Missing $label: $path"
  fi
}

check_dir() {
  local path="$1" label="${2:-$1}"
  if [[ -d "$PROJECT_ROOT/$path" ]]; then
    pass "$label"
  else
    fail "Missing $label: $path"
  fi
}

check_executable() {
  local path="$1" label="${2:-$1}"
  if [[ -x "$PROJECT_ROOT/$path" ]]; then
    pass "$label"
  elif [[ -f "$PROJECT_ROOT/$path" ]]; then
    fail "$label is not executable: $path"
  else
    fail "Missing $label: $path"
  fi
}

echo "── Required tools ──"
for tool in yq git; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$tool"
  else
    fail "Missing required tool: $tool"
  fi
done
echo ""

echo "── Lattice contract ──"
check_file "lattice/manifest.yaml" "manifest"
check_file "lattice/config/failure-categories.yaml" "failure category config"
check_file "lattice/kernel/VERSION" "kernel version"
check_file "lattice/kernel/_lib.sh" "kernel library"
check_dir "lattice/specs" "spec root"
check_file "lattice/context/README.md" "context map"
check_file "lattice/context/external.md" "external context map"
mkdir -p "$PROJECT_ROOT/lattice/context/drafts"
check_dir "lattice/context/drafts" "context draft root"
mkdir -p "$PROJECT_ROOT/lattice/context/drafts/promoted" "$PROJECT_ROOT/lattice/context/drafts/discarded"
check_dir "lattice/context/drafts/promoted" "promoted draft archive"
check_dir "lattice/context/drafts/discarded" "discarded draft archive"
echo ""

echo "── PrismSpec contract ──"
check_file "prismspec/skillpack.yaml" "PrismSpec skill pack manifest"
check_file "prismspec/skills/sdd/SKILL.md" "PrismSpec SDD skill"
check_file "prismspec/skills/brainstorm/SKILL.md" "PrismSpec brainstorm skill"
check_file "prismspec/templates/context-template.md" "PrismSpec context template"
check_file "prismspec/templates/spec-template.md" "PrismSpec default template"
check_executable "prismspec/bin/guide.sh" "PrismSpec guide"
check_executable "prismspec/bin/lint.sh" "PrismSpec lint"
echo ""

echo "── Delivery contract ──"
check_executable "lattice/kernel/delivery/pipeline.sh" "delivery pipeline"
check_executable "lattice/kernel/delivery/failure-category-lint.sh" "failure category lint"
check_executable "lattice/kernel/delivery/eval-sink.sh" "central eval sink"
check_executable "lattice/kernel/delivery/eval-dashboard.sh" "central eval dashboard"
check_executable "lattice/kernel/delivery/eval-query.sh" "central eval query"
check_executable "lattice/kernel/delivery/outcome-link.sh" "outcome linkage recorder"
check_executable "lattice/kernel/delivery/outcome-report.sh" "outcome attribution report"
check_executable "lattice/kernel/orchestrator/sdd/plan-lint.sh" "plan contract lint"
check_executable "lattice/kernel/orchestrator/sdd/task-evidence-lint.sh" "task evidence lint"
check_executable "lattice/kernel/orchestrator/sdd/spec-state-lint.sh" "spec state lint"
check_executable "lattice/kernel/orchestrator/sdd/spec-status.sh" "spec status transition helper"
check_executable "lattice/kernel/context/context-lint.sh" "context basis lint"
check_executable "lattice/kernel/context/context-run.sh" "context run recorder"
check_executable "lattice/kernel/context/learn-draft.sh" "learn draft workflow"
check_executable "lattice/kernel/context/knowledge-review.sh" "knowledge review evidence"
check_executable "lattice/kernel/context/knowledge-lint.sh" "knowledge governance lint"
check_executable "lattice/kernel/delivery/gates/spec-lint.sh" "spec lint gate"
check_executable "lattice/kernel/delivery/gates/ac-coverage.sh" "AC coverage gate"
check_executable "lattice/kernel/delivery/gates/drift-check.sh" "drift check gate"
if bash "$PROJECT_ROOT/lattice/kernel/delivery/failure-category-lint.sh" >/dev/null 2>&1; then
  pass "failure category config lint"
else
  fail "failure category config lint failed"
fi
if bash "$PROJECT_ROOT/lattice/kernel/context/knowledge-lint.sh" >/dev/null 2>&1; then
  pass "knowledge governance lint"
else
  fail "knowledge governance lint failed"
fi
check_dir "lattice/state" "state root"
mkdir -p "$PROJECT_ROOT/lattice/state/eval-runs"
check_dir "lattice/state/eval-runs" "eval run output root"
mkdir -p "$PROJECT_ROOT/lattice/state/eval-sink"
check_dir "lattice/state/eval-sink" "central eval sink root"
mkdir -p "$PROJECT_ROOT/lattice/state/loops"
check_dir "lattice/state/loops" "loop state output root"
mkdir -p "$PROJECT_ROOT/lattice/state/outcomes"
check_dir "lattice/state/outcomes" "outcome link event root"
mkdir -p "$PROJECT_ROOT/lattice/state/learn-promotions"
check_dir "lattice/state/learn-promotions" "learn promotion event root"
mkdir -p "$PROJECT_ROOT/lattice/state/knowledge-reviews"
check_dir "lattice/state/knowledge-reviews" "knowledge review event root"
echo ""

echo "── Agent commands ──"
for command in sdd brainstorm plan implement verify finish learn; do
  if [[ -f "$PROJECT_ROOT/.claude/commands/${command}.md" ]]; then
    pass ".claude command: $command"
  else
    warn "Optional Claude command missing: .claude/commands/${command}.md"
  fi
done
echo ""

print_summary "Doctor"

#!/usr/bin/env bash
# lint.sh — PrismSpec artifact and skill-pack lint.
# Validates the minimum contract for artifacts, canonical skills, and distribution files.
set -euo pipefail

TARGET="${1:-}"
CHECK="${2:-all}"

usage() {
  cat <<'EOF'
PrismSpec lint

Usage:
  bash prismspec/bin/lint.sh <spec-dir|spec.md> [all|spec|plan|evidence]
  bash prismspec/bin/lint.sh prismspec skillpack

Checks:
  spec      spec.md has Context Basis, ACs, execution mode, risk, and verification plan
  plan      plan.md references AC ids and includes verification
  evidence  verify.md records commands/results
  skillpack canonical skills, templates, references, command, and routing contract exist
  all       run all available checks
EOF
}

if [[ -z "$TARGET" || "$TARGET" == "--help" || "$TARGET" == "-h" ]]; then
  usage
  [[ -z "$TARGET" ]] && exit 1 || exit 0
fi

case "$CHECK" in
  all|spec|plan|evidence|skillpack) ;;
  *) echo "Invalid check: $CHECK" >&2; usage; exit 1 ;;
esac

FAIL=0

ok() { printf "PASS %s\n" "$*"; }
bad() { printf "FAIL %s\n" "$*" >&2; FAIL=1; }

check_file() {
  local file="$1" label="$2"
  [[ -f "$file" ]] || bad "$label missing: $file"
}

check_executable() {
  local file="$1" label="$2"
  [[ -x "$file" ]] || bad "$label missing or not executable: $file"
}

check_contains() {
  local file="$1" pattern="$2" label="$3"
  grep -qE "$pattern" "$file" 2>/dev/null || bad "$label missing in $file"
}

skill_name_for_stage() {
  echo "prismspec-$1"
}

skill_dir_for_stage() {
  echo "prismspec-$1"
}

check_skill_file() {
  local root="$1" stage="$2"
  local skill_name skill_dir skill_file
  skill_name="$(skill_name_for_stage "$stage")"
  skill_dir="$(skill_dir_for_stage "$stage")"
  skill_file="$root/skills/$skill_dir/SKILL.md"
  check_file "$skill_file" "$stage skill"
  [[ -f "$skill_file" ]] || return

  local line_count
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  [[ "$line_count" -le 500 ]] || bad "$stage skill exceeds 500 lines"

  head -1 "$skill_file" | grep -qxF -- '---' || bad "$stage skill frontmatter start missing"
  check_contains "$skill_file" "^name: $skill_name$" "$stage skill name"
  check_contains "$skill_file" "^description: .+Use (when|after)" "$stage trigger-rich description"
  check_contains "$skill_file" "^## Overview$" "$stage Overview section"
  check_contains "$skill_file" "^## Stop Conditions$" "$stage Stop Conditions section"
  check_contains "$skill_file" "^## Verification$" "$stage Verification section"

  if [[ "$stage" == "workflow" ]]; then
    check_contains "$skill_file" "^## Start Here$" "workflow Start Here section"
    check_contains "$skill_file" "^## Routing$" "workflow Routing section"
    check_contains "$skill_file" "prismspec/bin/guide\\.sh --json" "workflow deterministic guide"
  else
    check_contains "$skill_file" "^## Inputs$" "$stage Inputs section"
    check_contains "$skill_file" "^## Workflow$" "$stage Workflow section"
    check_contains "$skill_file" "^## Outputs$" "$stage Outputs section"
  fi
}

check_skill_interface() {
  local root="$1" stage="$2"
  local skill_name skill_dir metadata_file
  skill_name="$(skill_name_for_stage "$stage")"
  skill_dir="$(skill_dir_for_stage "$stage")"
  metadata_file="$root/skills/$skill_dir/agents/openai.yaml"
  check_file "$metadata_file" "$stage UI metadata"
  [[ -f "$metadata_file" ]] || return

  check_contains "$metadata_file" '^interface:$' "$stage metadata interface root"
  check_contains "$metadata_file" '^[[:space:]]+display_name: "[^"]{3,}"$' "$stage metadata display_name"
  check_contains "$metadata_file" '^[[:space:]]+short_description: "[^"]{25,64}"$' "$stage metadata short_description"
  check_contains "$metadata_file" '^[[:space:]]+default_prompt: ".*\$'"$skill_name" "$stage metadata default_prompt"
}

check_skill_evals() {
  local root="$1" stage="$2"
  local skill_name skill_dir eval_file
  skill_name="$(skill_name_for_stage "$stage")"
  skill_dir="$(skill_dir_for_stage "$stage")"
  eval_file="$root/skills/$skill_dir/evals/evals.json"
  check_file "$eval_file" "$stage evals"
  [[ -f "$eval_file" ]] || return

  check_contains "$eval_file" '"schema_version":[[:space:]]*"prismspec\.skill-evals/v1"' "$stage eval schema"
  check_contains "$eval_file" '"skill":[[:space:]]*"'"$skill_name"'"' "$stage eval skill name"
  check_contains "$eval_file" '"should_trigger":[[:space:]]*\[' "$stage should_trigger evals"
  check_contains "$eval_file" '"should_not_trigger":[[:space:]]*\[' "$stage should_not_trigger evals"
  check_contains "$eval_file" '"assertions":[[:space:]]*\[' "$stage eval assertions"
}

check_skillpack() {
  local root="$1"
  local manifest="$root/skillpack.yaml"

  if [[ -f "$root" && "$(basename "$root")" == "skillpack.yaml" ]]; then
    manifest="$root"
    root="$(dirname "$root")"
  fi

  check_file "$manifest" "skillpack manifest"
  [[ -f "$manifest" ]] || return

  check_contains "$manifest" '^api_version: prismspec\.lattice\.dev/v1$' "skillpack api_version"
  check_contains "$manifest" '^kind: SkillPack$' "skillpack kind"
  check_contains "$manifest" '^[[:space:]]+name: prismspec$' "skillpack metadata.name"
  check_contains "$manifest" 'agent-skills-packaging' "skillpack Agent Skills standard"
  check_contains "$manifest" 'superpowers-workflow-discipline' "skillpack Superpowers standard"
  check_contains "$manifest" '^product_blocks:$' "skillpack product blocks"
  check_contains "$manifest" '^[[:space:]]+command: prismspec/commands/prismspec\.md$' "skillpack command entrypoint"
  check_contains "$manifest" '^[[:space:]]+new: prismspec/bin/new\.sh$' "skillpack new entrypoint"
  check_contains "$manifest" '^[[:space:]]+router: prismspec/bin/guide\.sh$' "skillpack router entrypoint"
  check_contains "$manifest" '^[[:space:]]+lint: prismspec/bin/lint\.sh$' "skillpack lint entrypoint"
  check_contains "$manifest" '^[[:space:]]+doctor: prismspec/bin/doctor\.sh$' "skillpack doctor entrypoint"
  check_contains "$manifest" '^[[:space:]]+skill_eval: prismspec/bin/eval-skills\.sh$' "skillpack skill eval entrypoint"
  check_contains "$manifest" 'bash prismspec/bin/doctor\.sh' "skillpack doctor gate"
  check_contains "$manifest" 'bash prismspec/bin/new\.sh --help' "skillpack new gate"
  check_contains "$manifest" 'bash prismspec/bin/eval-skills\.sh --all' "skillpack skill eval gate"
  check_contains "$manifest" 'bash prismspec/bin/lint\.sh prismspec skillpack' "skillpack self lint gate"

  local command
  for command in prismspec build clarify spec plan implement quality review verify capture; do
    check_file "$root/commands/$command.md" "$command command"
  done
  local block
  for block in clarify spec build quality; do
    check_contains "$manifest" "^[[:space:]]+- id: $block$" "$block product block"
  done
  check_contains "$manifest" 'display_name: Clarify' "Clarify display name"
  check_contains "$manifest" 'display_name: Quality Gate' "Quality Gate display name"
  check_executable "$root/bin/new.sh" "new"
  check_executable "$root/bin/guide.sh" "guide"
  check_executable "$root/bin/lint.sh" "lint"
  check_executable "$root/bin/doctor.sh" "doctor"
  check_executable "$root/bin/eval-skills.sh" "skill eval"

  local stage
  for stage in workflow specification planning implementation review verification knowledge-capture debugging context-engineering grilling source-grounding doubt-review interface-design; do
    local skill_dir
    skill_dir="$(skill_dir_for_stage "$stage")"
    check_skill_file "$root" "$stage"
    check_skill_interface "$root" "$stage"
    check_skill_evals "$root" "$stage"
    check_contains "$manifest" "path: prismspec/skills/$skill_dir/SKILL\\.md" "$stage canonical skill catalog entry"
    check_contains "$manifest" "interface: prismspec/skills/$skill_dir/agents/openai\\.yaml" "$stage interface catalog entry"
  done

  for stage in specification planning implementation review verification; do
    local skill_dir
    skill_dir="$(skill_dir_for_stage "$stage")"
    check_contains "$manifest" "skill: prismspec/skills/$skill_dir/SKILL\\.md" "$stage workflow entry"
  done

  local template
  for template in spec-template.md spec-template-lite.md spec-template-service.md spec-template-frontend.md spec-template-tdd.md; do
    check_file "$root/templates/$template" "template"
  done

  local reference
  for reference in mode-selection.md definition-of-done.md spec-quality-checklist.md tdd-evidence-checklist.md review-evidence-checklist.md superpowers-alignment.md agent-skills-alignment.md; do
    check_file "$root/references/$reference" "reference"
  done
  check_file "$root/agents/spec-reviewer.md" "spec reviewer"
  check_file "$root/agents/task-reviewer.md" "task reviewer"
  check_file "$root/agents/test-reviewer.md" "test reviewer"
  check_file "$root/agents/risk-reviewer.md" "risk reviewer"
  check_contains "$manifest" '^[[:space:]]+spec: prismspec/agents/spec-reviewer\.md$' "spec reviewer catalog entry"
  check_contains "$manifest" '^[[:space:]]+task: prismspec/agents/task-reviewer\.md$' "task reviewer catalog entry"
  check_contains "$manifest" '^[[:space:]]+test: prismspec/agents/test-reviewer\.md$' "test reviewer catalog entry"
  check_contains "$manifest" '^[[:space:]]+risk: prismspec/agents/risk-reviewer\.md$' "risk reviewer catalog entry"

  local flat_count
  flat_count=$(find "$root/skills" -maxdepth 1 -type f -name '*.md' -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
  [[ "$flat_count" == "0" ]] || bad "flat skill wrappers found under $root/skills"

  if [[ $FAIL -eq 0 ]]; then ok "skillpack contract"; fi
}

if [[ "$CHECK" == "skillpack" ]]; then
  if [[ -d "$TARGET" ]]; then
    check_skillpack "${TARGET%/}"
  elif [[ -f "$TARGET" ]]; then
    check_skillpack "$TARGET"
  else
    echo "Target not found: $TARGET" >&2
    exit 1
  fi
  exit "$FAIL"
fi

if [[ -d "$TARGET" ]]; then
  SPEC_DIR="${TARGET%/}"
  SPEC_FILE="$SPEC_DIR/spec.md"
elif [[ -f "$TARGET" ]]; then
  SPEC_FILE="$TARGET"
  SPEC_DIR="$(dirname "$TARGET")"
else
  echo "Target not found: $TARGET" >&2
  exit 1
fi

PLAN_FILE="$SPEC_DIR/plan.md"
VERIFY_FILE="$SPEC_DIR/verify.md"

contains_heading() {
  local file="$1" pattern="$2"
  grep -qiE "^#{1,3}[[:space:]]+.*($pattern)" "$file"
}

check_spec() {
  [[ -f "$SPEC_FILE" ]] || { bad "spec.md missing: $SPEC_FILE"; return; }

  grep -qiE '^scaffolded:[[:space:]]*true[[:space:]]*$' "$SPEC_FILE" \
    && bad "spec.md is still scaffolded; fill it and set scaffolded: false"
  grep -qE 'AC-[0-9]+' "$SPEC_FILE" || bad "spec.md has no AC-{n} acceptance criteria"
  grep -qiE 'execution[_ -]?mode|Mode:[[:space:]]*`?(plan|tdd)|mode:[[:space:]]*`?(plan|tdd)' "$SPEC_FILE" || bad "spec.md has no execution mode"
  grep -qiE '\b(plan|tdd)\b' "$SPEC_FILE" || bad "spec.md execution mode must be plan or tdd"
  grep -qiE '^approval:[[:space:]]*(explicit|inferred|skipped-with-reason)[[:space:]]*$|Status:[[:space:]]*(explicit|inferred|skipped-with-reason)' "$SPEC_FILE" || bad "spec.md has no approval status"
  contains_heading "$SPEC_FILE" 'Intent|Objective|Goal|Background|技术目标|目标|背景' || bad "spec.md missing intent/objective section"
  contains_heading "$SPEC_FILE" 'Scope|设计范围|范围|边界' || bad "spec.md missing scope section"
  contains_heading "$SPEC_FILE" 'Context|Context Basis|上下文依据' || bad "spec.md missing Context Basis section"
  contains_heading "$SPEC_FILE" 'Risk|风险' || bad "spec.md missing risk section"
  contains_heading "$SPEC_FILE" 'Verification|Test Strategy|验证|测试' || bad "spec.md missing verification/test section"

  if [[ $FAIL -eq 0 ]]; then ok "spec contract"; fi
}

check_plan() {
  [[ -f "$PLAN_FILE" ]] || { bad "plan.md missing: $PLAN_FILE"; return; }

  grep -qE 'AC-[0-9]+' "$PLAN_FILE" || bad "plan.md has no AC references"
  grep -qiE 'verify|verification|test|lint|build|验证|测试' "$PLAN_FILE" || bad "plan.md has no verification steps"
  grep -qE '(^|[[:space:]])(T[0-9]+|RED-[0-9]+)[:.) -]' "$PLAN_FILE" || bad "plan.md has no stable task ids"
  grep -qiE '(Mode|模式)[[:space:]]*[:：][[:space:]]*`?(plan|tdd)' "$PLAN_FILE" || bad "plan.md tasks have no Mode"
  grep -qiE '(Scope|范围)[[:space:]]*[:：]' "$PLAN_FILE" || bad "plan.md tasks have no Scope"
  grep -qiE '(Evidence|证据)[[:space:]]*[:：]' "$PLAN_FILE" || bad "plan.md tasks have no Evidence block"
  grep -qiE '(Brief|任务简报)[[:space:]]*[:：]' "$PLAN_FILE" || bad "plan.md tasks have no Brief evidence path"
  grep -qiE '(Review package|评审包)[[:space:]]*[:：]' "$PLAN_FILE" || bad "plan.md tasks have no Review package evidence path"
  grep -qiE '(Done when|完成条件)[[:space:]]*[:：]' "$PLAN_FILE" || bad "plan.md tasks have no Done when condition"

  if grep -qiE 'execution[_ -]?mode:[[:space:]]*tdd|Mode:[[:space:]]*`?tdd|执行模式[[:space:]]*[:：][[:space:]]*`?tdd' "$SPEC_FILE" "$PLAN_FILE" 2>/dev/null; then
    grep -qE 'RED-[0-9]+|red test|failing test|红灯|失败测试' "$PLAN_FILE" || bad "tdd spec requires red-test tasks in plan.md"
  fi

  if [[ $FAIL -eq 0 ]]; then ok "plan contract"; fi
}

check_evidence() {
  if [[ -f "$VERIFY_FILE" ]]; then
    grep -qiE 'command|exit|pass|fail|pipeline|test|build|lint|命令|通过|失败' "$VERIFY_FILE" || bad "verify.md lacks command/result evidence"
  else
    bad "verification evidence missing: verify.md"
  fi

  if [[ $FAIL -eq 0 ]]; then ok "evidence contract"; fi
}

case "$CHECK" in
  spec) check_spec ;;
  plan) check_plan ;;
  evidence) check_evidence ;;
  all)
    check_spec
    check_plan
    check_evidence
    ;;
esac

exit "$FAIL"

#!/usr/bin/env bash
# task-brief.sh - Build a compact, file-backed task brief for implementers/reviewers.
# Usage: task-brief.sh <spec-id> <task-id> [output-file]
source "$(dirname "$0")/../../_lib.sh"

SPEC_ID="${1:-}"
TASK_ID="${2:-}"
OUT="${3:-}"

if [[ -z "$SPEC_ID" || -z "$TASK_ID" ]]; then
  echo "Usage: task-brief.sh <spec-id> <task-id> [output-file]"
  exit 1
fi

SPEC_DIR="$PROJECT_ROOT/lattice/specs/$SPEC_ID"
SPEC_FILE="$SPEC_DIR/spec.md"
PLAN_FILE="$SPEC_DIR/plan.md"

[[ -f "$SPEC_FILE" ]] || { echo "Spec not found: $SPEC_FILE"; exit 1; }
[[ -f "$PLAN_FILE" ]] || { echo "Plan not found: $PLAN_FILE"; exit 1; }

TASK_DIR="$PROJECT_ROOT/.lattice/sdd/$SPEC_ID/$TASK_ID"
mkdir -p "$TASK_DIR"
OUT="${OUT:-$TASK_DIR/brief.md}"

extract_section() {
  local headings="$1" file="$2"
  awk -v headings="$headings" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    function normalize(s) {
      sub(/^##+[[:space:]]+/, "", s)
      sub(/^[0-9]+[.、][[:space:]]*/, "", s)
      return trim(s)
    }
    BEGIN { split(headings, wanted, "|") }
    /^##[[:space:]]+/ {
      title = normalize($0)
      for (i in wanted) {
        if (tolower(title) == tolower(wanted[i])) {
          in_section=1
          print
          next
        }
      }
      if (in_section) exit
    }
    in_section { print }
  ' "$file"
}

extract_task() {
  local task_id="$1" file="$2"
  awk -v task_id="$task_id" '
    $0 ~ "^- \\[[ xX]\\] " task_id ":" { in_task=1; print; next }
    in_task && /^- \[[ xX]\] (T[0-9]+|RED-[0-9]+):/ { exit }
    in_task && /^##[[:space:]]+/ { exit }
    in_task { print }
  ' "$file"
}

{
  echo "# 任务简报：$SPEC_ID / $TASK_ID"
  echo ""
  echo "## 来源"
  echo ""
  echo "- 技术方案：\`lattice/specs/$SPEC_ID/spec.md\`"
  echo "- 实施计划：\`lattice/specs/$SPEC_ID/plan.md\`"
  echo "- 当前任务：\`$TASK_ID\`"
  echo ""
  echo "## 技术目标"
  echo ""
  extract_section "技术目标|Intent|Objective|Goal" "$SPEC_FILE" | sed '1d'
  echo ""
  echo "## 执行策略"
  echo ""
  extract_section "执行策略|Execution Policy" "$SPEC_FILE" | sed '1d'
  echo ""
  echo "## 全局约束"
  echo ""
  extract_section "全局约束|Global Constraints" "$PLAN_FILE" | sed '1d'
  echo ""
  echo "## 当前任务"
  echo ""
  extract_task "$TASK_ID" "$PLAN_FILE"
  echo ""
  echo "## 验收标准"
  echo ""
  extract_section "验收标准|Acceptance Criteria" "$SPEC_FILE" | sed '1d'
  echo ""
  echo "## 评审契约"
  echo ""
  echo "- 改动必须限制在当前任务及其引用的 AC 范围内。"
  echo "- 如果无法通过本地文件或测试验证，必须明确说明原因。"
  echo "- 不得为了通过验证而削弱测试、范围或验收标准。"
} > "$OUT"

echo "$OUT"

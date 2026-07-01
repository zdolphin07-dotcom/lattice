#!/usr/bin/env bash
# review-summary.sh - Write review.md plus structured review verdict evidence.
# Usage: review-summary.sh <spec-id> [task-id] --spec-compliance=pass --code-quality=pass --test-coverage=pass --risk=pass
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "review summary" "Write review.md and review-summary.json evidence" \
    "review-summary.sh <spec-id> [task-id] --spec-compliance=pass|fail|cannot_verify --code-quality=pass|fail|cannot_verify --test-coverage=pass|fail|cannot_verify --risk=pass|fail|cannot_verify" \
    "review-summary.sh <spec-id> T1 ... --finding='medium|file:line|issue' --evidence='go test ./...' --out=<file>"
done

SPEC_ID=""
TASK_ID="branch"
OUT=""
SPEC_COMPLIANCE=""
CODE_QUALITY=""
TEST_COVERAGE=""
RISK=""
declare -a FINDINGS=()
declare -a EVIDENCE=()

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

normalize_verdict() {
  local value="${1:-}"
  value="${value//-/_}"
  case "$value" in
    pass|fail|cannot_verify) printf '%s' "$value" ;;
    *)
      echo "Invalid verdict: ${1:-empty}. Use pass, fail, or cannot_verify."
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-compliance=*) SPEC_COMPLIANCE="${1#--spec-compliance=}" ;;
    --code-quality=*) CODE_QUALITY="${1#--code-quality=}" ;;
    --test-coverage=*) TEST_COVERAGE="${1#--test-coverage=}" ;;
    --risk=*) RISK="${1#--risk=}" ;;
    --finding=*) FINDINGS+=("${1#--finding=}") ;;
    --evidence=*) EVIDENCE+=("${1#--evidence=}") ;;
    --out=*) OUT="${1#--out=}" ;;
    --out)
      shift
      OUT="${1:-}"
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      if [[ -z "$SPEC_ID" ]]; then
        SPEC_ID="$1"
      elif [[ "$TASK_ID" == "branch" ]]; then
        TASK_ID="$1"
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$SPEC_ID" ]]; then
  echo "Usage: review-summary.sh <spec-id> [task-id] --spec-compliance=... --code-quality=... --test-coverage=... --risk=..."
  exit 1
fi

SPEC_COMPLIANCE="$(normalize_verdict "$SPEC_COMPLIANCE")"
CODE_QUALITY="$(normalize_verdict "$CODE_QUALITY")"
TEST_COVERAGE="$(normalize_verdict "$TEST_COVERAGE")"
RISK="$(normalize_verdict "$RISK")"

VERDICT="pass"
for axis in "$SPEC_COMPLIANCE" "$CODE_QUALITY" "$TEST_COVERAGE" "$RISK"; do
  if [[ "$axis" == "fail" ]]; then
    VERDICT="fail"
    break
  fi
  if [[ "$axis" == "cannot_verify" && "$VERDICT" == "pass" ]]; then
    VERDICT="cannot_verify"
  fi
done

TASK_DIR="$PROJECT_ROOT/.lattice/sdd/$SPEC_ID/$TASK_ID"
if [[ -z "$OUT" ]]; then
  JSON_OUT="$TASK_DIR/review-summary.json"
  if [[ "$TASK_ID" == "branch" ]]; then
    MD_OUT="$PROJECT_ROOT/lattice/specs/$SPEC_ID/review.md"
  else
    MD_OUT="$TASK_DIR/review.md"
  fi
else
  [[ "$OUT" == /* ]] || OUT="$PROJECT_ROOT/$OUT"
  case "$OUT" in
    *.md)
      MD_OUT="$OUT"
      JSON_OUT="$(dirname "$OUT")/review-summary.json"
      ;;
    *)
      JSON_OUT="$OUT"
      MD_OUT="$(dirname "$OUT")/review.md"
      ;;
  esac
fi
[[ "$JSON_OUT" == /* ]] || JSON_OUT="$PROJECT_ROOT/$JSON_OUT"
[[ "$MD_OUT" == /* ]] || MD_OUT="$PROJECT_ROOT/$MD_OUT"
mkdir -p "$(dirname "$JSON_OUT")" "$(dirname "$MD_OUT")"

CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REVIEW_PACKAGE=".lattice/sdd/$SPEC_ID/$TASK_ID/review-package.md"
scope_label() {
  if [[ "$TASK_ID" == "branch" ]]; then
    printf '整体分支'
  else
    printf '任务 `%s`' "$TASK_ID"
  fi
}

verdict_label() {
  case "$1" in
    pass) printf '通过' ;;
    fail) printf '不通过' ;;
    cannot_verify) printf '无法验证' ;;
    *) printf '%s' "$1" ;;
  esac
}

gate_decision() {
  case "$VERDICT" in
    pass) printf '允许进入 Verification Gate。' ;;
    fail) printf '不允许进入 Verification Gate；必须先处理阻塞发现项。' ;;
    cannot_verify) printf '不允许进入 Verification Gate；必须先补齐缺失证据或明确风险接受。' ;;
    *) printf '决策未知；需要人工确认。' ;;
  esac
}

{
  printf '{\n'
  printf '  "schema_version": "lattice.review-summary.v1",\n'
  printf '  "kind": "review-summary",\n'
  printf '  "spec_id": "%s",\n' "$(json_escape "$SPEC_ID")"
  printf '  "task_id": "%s",\n' "$(json_escape "$TASK_ID")"
  printf '  "created_at": "%s",\n' "$(json_escape "$CREATED_AT")"
  printf '  "verdict": "%s",\n' "$VERDICT"
  printf '  "axes": {\n'
  printf '    "spec_compliance": "%s",\n' "$SPEC_COMPLIANCE"
  printf '    "code_quality": "%s",\n' "$CODE_QUALITY"
  printf '    "test_coverage": "%s",\n' "$TEST_COVERAGE"
  printf '    "risk": "%s"\n' "$RISK"
  printf '  },\n'
  printf '  "findings": [\n'
  local_idx=0
  if [[ "${#FINDINGS[@]}" -gt 0 ]]; then
    for finding in "${FINDINGS[@]}"; do
      IFS='|' read -r severity reference issue <<< "$finding"
      printf '    {"severity":"%s","reference":"%s","issue":"%s"}' \
        "$(json_escape "${severity:-}")" \
        "$(json_escape "${reference:-}")" \
        "$(json_escape "${issue:-}")"
      local_idx=$((local_idx + 1))
      [[ "$local_idx" -lt "${#FINDINGS[@]}" ]] && printf ','
      printf '\n'
    done
  fi
  printf '  ],\n'
  printf '  "evidence_checked": [\n'
  local_idx=0
  if [[ "${#EVIDENCE[@]}" -gt 0 ]]; then
    for item in "${EVIDENCE[@]}"; do
      printf '    "%s"' "$(json_escape "$item")"
      local_idx=$((local_idx + 1))
      [[ "$local_idx" -lt "${#EVIDENCE[@]}" ]] && printf ','
      printf '\n'
    done
  fi
  printf '  ],\n'
  printf '  "source": {\n'
  printf '    "review_package": "%s"\n' "$(json_escape "$REVIEW_PACKAGE")"
  printf '  }\n'
  printf '}\n'
} > "$JSON_OUT"

{
  printf -- '---\n'
  printf 'schema_version: lattice.review.v1\n'
  printf 'kind: review\n'
  printf 'spec_id: "%s"\n' "$SPEC_ID"
  printf 'task_id: "%s"\n' "$TASK_ID"
  printf 'created_at: "%s"\n' "$CREATED_AT"
  printf 'verdict: "%s"\n' "$VERDICT"
  printf 'spec_compliance: "%s"\n' "$SPEC_COMPLIANCE"
  printf 'code_quality: "%s"\n' "$CODE_QUALITY"
  printf 'test_coverage: "%s"\n' "$TEST_COVERAGE"
  printf 'risk: "%s"\n' "$RISK"
  printf -- '---\n\n'
  printf '# 评审报告：%s\n\n' "$SPEC_ID"
  printf '## 1. 评审结论\n\n'
  printf '| 项 | 结论 |\n'
  printf '|---|---|\n'
  printf '| 评审范围 | %s |\n' "$(scope_label)"
  printf '| 总体结论 | `%s`（%s） |\n' "$VERDICT" "$(verdict_label "$VERDICT")"
  printf '| 是否允许进入验证 | %s |\n\n' "$(gate_decision)"
  printf '## 2. 四轴评审\n\n'
  printf '| 维度 | 结论 | 判断重点 |\n'
  printf '|---|---|---|\n'
  printf '| Spec 符合度 | `%s` | 是否满足相关 AC，且没有引入未批准范围。 |\n' "$SPEC_COMPLIANCE"
  printf '| 代码质量 | `%s` | 是否简单、可维护、符合项目习惯，并具备可回滚性。 |\n' "$CODE_QUALITY"
  printf '| 测试覆盖 | `%s` | 测试是否证明关键成功路径、失败路径和回归风险。 |\n' "$TEST_COVERAGE"
  printf '| 风险控制 | `%s` | 权限、数据、状态、并发、迁移等风险是否被约束。 |\n\n' "$RISK"
  printf '## 3. 检查范围\n\n'
  printf -- '- 技术方案：`lattice/specs/%s/spec.md`\n' "$SPEC_ID"
  printf -- '- 实施计划：`lattice/specs/%s/plan.md`\n' "$SPEC_ID"
  printf -- '- Review package：`%s`\n' "$REVIEW_PACKAGE"
  printf -- '- JSON sidecar：`%s`\n\n' "${JSON_OUT#$PROJECT_ROOT/}"
  printf '## 4. 发现项\n\n'
  if [[ "${#FINDINGS[@]}" -gt 0 ]]; then
    for finding in "${FINDINGS[@]}"; do
      IFS='|' read -r severity reference issue <<< "$finding"
      printf -- '- 严重度：`%s`\n' "${severity:-unspecified}"
      printf '  位置：`%s`\n' "${reference:-N/A}"
      printf '  问题：%s\n' "${issue:-N/A}"
    done
    printf '\n'
  else
    printf '本次结构化评审未记录阻塞发现项。\n\n'
  fi
  printf '## 5. 已检查证据\n\n'
  if [[ "${#EVIDENCE[@]}" -gt 0 ]]; then
    for item in "${EVIDENCE[@]}"; do
      printf -- '- `%s`\n' "$item"
    done
  else
    printf '未向结构化 helper 传入证据条目；该项通常应评为 `cannot_verify` 或补充证据。\n'
  fi
  printf '\n## 6. 风险与处置\n\n'
  if [[ "$VERDICT" == "pass" ]]; then
    printf -- '- 当前评审未发现阻塞进入验证的质量风险。\n'
    printf -- '- 后续仍需通过 Verification Gate 的真实命令输出证明仓库状态。\n'
  elif [[ "$VERDICT" == "fail" ]]; then
    printf -- '- 当前存在阻塞发现项，必须回到 Build/Implement 修复后重新评审。\n'
  else
    printf -- '- 当前证据不足，不能视为通过；必须补齐证据或记录明确的风险接受决策。\n'
  fi
  printf '\n## 7. 机器侧证据\n\n'
  printf -- '- JSON sidecar：`%s`\n' "${JSON_OUT#$PROJECT_ROOT/}"
  printf -- '- Review package：`%s`\n' "$REVIEW_PACKAGE"
} > "$MD_OUT"

echo "Review: ${MD_OUT#$PROJECT_ROOT/}"
echo "Review summary: ${JSON_OUT#$PROJECT_ROOT/}"

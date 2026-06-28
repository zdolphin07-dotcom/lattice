#!/usr/bin/env bash
# compliance.sh — Compliance audit gate (soft gate)
# Checks whether the agent followed Lattice behavioral rules.
# Exit codes: 0=compliant, 1=warnings when --strict is enabled
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery gate compliance" "Check agent behavioral compliance (soft gate)" \
    "compliance.sh [spec-file]    Check context basis and knowledge references" \
    "compliance.sh --strict       Strict mode (warnings treated as failures)"
done

STRICT=false
SPEC="${1:-}"
for arg in "$@"; do
  [[ "$arg" == "--strict" ]] && STRICT=true
done

if [[ -z "$SPEC" ]] || [[ "$SPEC" == "--strict" ]]; then
  SPEC=$(find_spec 2>/dev/null) || { echo "⚠️  No spec file found, skipping compliance check"; exit 0; }
fi

[[ -f "$SPEC" ]] || { echo "⚠️  Spec not found: $SPEC"; exit 0; }

SPEC_DIR="$(dirname "$SPEC")"
CONTEXT_FILE="$SPEC_DIR/context.md"
knowledge_dir=$(manifest_get '.context.knowledge.dir')
PROJECT_KNOWLEDGE_DIR="${PROJECT_ROOT}/${knowledge_dir:-lattice/context/knowledge}"

echo "🔍 Compliance Audit: $(basename "$SPEC")"
echo ""

WARNINGS=0

echo "── Context basis check ──"
if [[ -f "$CONTEXT_FILE" ]]; then
  echo "  ✅ Found per-spec context basis: ${CONTEXT_FILE#$PROJECT_ROOT/}"
  if grep -qiE '^## +(Decision Frame|Selected Facts|Constraints|Conflicts|Context Gaps)' "$CONTEXT_FILE"; then
    echo "  ✅ Context basis has structured decision sections"
  else
    echo "  ⚠️  Context basis is present but lacks structured decision sections"
    echo "     Expected Decision Frame, Selected Facts, Constraints, Conflicts, or Context Gaps."
    ((WARNINGS++)) || true
  fi
else
  echo "  ⚠️  Missing per-spec context basis: ${CONTEXT_FILE#$PROJECT_ROOT/}"
  echo "     Expected the design phase to persist retrieved context and gaps."
  ((WARNINGS++)) || true
fi

echo ""
echo "── Knowledge source check ──"
KNOWLEDGE_FILES=$(find "$PROJECT_KNOWLEDGE_DIR" -name "*.md" -not -name "README.md" 2>/dev/null || true)
TOTAL_KB=0
SEARCH_FILES=("$SPEC")
[[ -f "$CONTEXT_FILE" ]] && SEARCH_FILES+=("$CONTEXT_FILE")

while IFS= read -r kb_file; do
  [[ -z "$kb_file" ]] && continue
  ((TOTAL_KB++)) || true
done <<< "$KNOWLEDGE_FILES"

if [[ "$TOTAL_KB" -gt 0 ]] && grep -qiE 'lattice/context/knowledge|knowledge/' "${SEARCH_FILES[@]}" 2>/dev/null; then
  echo "  ✅ Spec/context references project knowledge paths"
elif [[ "$TOTAL_KB" -gt 0 ]]; then
  echo "  ⚠️  Spec/context does not reference project knowledge paths"
  echo "     Found $TOTAL_KB entries under lattice/context/knowledge."
  echo "     This is acceptable only when the current change does not depend on durable project knowledge."
  ((WARNINGS++)) || true
elif [[ "$TOTAL_KB" -eq 0 ]]; then
  echo "  ⏭️  Context knowledge is empty, skipping"
fi

echo ""
echo "── Source trace check ──"
if [[ -f "$CONTEXT_FILE" ]] && grep -qiE '\| *(user|code|test|schema|contract|knowledge|external) *\|' "$CONTEXT_FILE"; then
  echo "  ✅ Context basis records source categories"
else
  echo "  ⚠️  Context basis does not clearly record source categories"
  ((WARNINGS++)) || true
fi

echo ""
echo "── Ambiguity tracking check ──"
if [[ -f "$CONTEXT_FILE" ]] && grep -qiE 'Open Questions|Context Gaps|Conflicts|Ambiguities|None|N/A' "$CONTEXT_FILE" 2>/dev/null; then
  echo "  ✅ Context basis records ambiguities or explicitly marks none"
else
  echo "  ⚠️  No ambiguity or gap records found in context basis"
  ((WARNINGS++)) || true
fi

echo ""
echo "══════════════════════════════════"
if [[ "$WARNINGS" -eq 0 ]]; then
  echo "📊 Compliance Audit: ✅ no warnings"
  exit 0
fi

echo "📊 Compliance Audit: ⚠️  $WARNINGS warnings (soft rule)"
if [[ "$STRICT" == "true" ]]; then
  echo "❌ FAIL (strict mode)"
  exit 1
fi

echo "✅ PASS (soft gate, warnings for review reference)"
exit 0

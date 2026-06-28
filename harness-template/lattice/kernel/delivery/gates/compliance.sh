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
else
  echo "  ⚠️  Missing per-spec context basis: ${CONTEXT_FILE#$PROJECT_ROOT/}"
  echo "     Expected the design phase to persist retrieved context and gaps."
  ((WARNINGS++)) || true
fi

echo ""
echo "── Knowledge reference check ──"
KNOWLEDGE_FILES=$(find "$PROJECT_KNOWLEDGE_DIR" -name "*.md" -not -name "README.md" 2>/dev/null || true)
REFERENCED=0
TOTAL_KB=0
SEARCH_FILES=("$SPEC")
[[ -f "$CONTEXT_FILE" ]] && SEARCH_FILES+=("$CONTEXT_FILE")

while IFS= read -r kb_file; do
  [[ -z "$kb_file" ]] && continue
  ((TOTAL_KB++)) || true
  slug=$(basename "$kb_file" .md)
  if grep -qi "$slug" "${SEARCH_FILES[@]}" 2>/dev/null; then
    ((REFERENCED++)) || true
    echo "  ✅ Referenced knowledge: $slug"
  fi
done <<< "$KNOWLEDGE_FILES"

if [[ "$TOTAL_KB" -gt 0 ]] && [[ "$REFERENCED" -eq 0 ]]; then
  echo "  ⚠️  Spec/context does not reference any knowledge entries"
  echo "     Found $TOTAL_KB entries under lattice/context/knowledge."
  echo "     Possible cause: Context Discovery did not select any durable project knowledge."
  ((WARNINGS++)) || true
elif [[ "$TOTAL_KB" -eq 0 ]]; then
  echo "  ⏭️  Context knowledge is empty, skipping"
fi

echo ""
echo "── Context activity trace ──"
RECENT_COMMITS=$(git -C "$PROJECT_ROOT" log --oneline -20 2>/dev/null || echo "")
if echo "$RECENT_COMMITS" | grep -qi "context\|knowledge\|loader"; then
  echo "  ✅ Recent commits contain context-related activity"
else
  echo "  ⚠️  No context-related activity in last 20 commits"
  ((WARNINGS++)) || true
fi

echo ""
echo "── Requirements clarification check ──"
if grep -qiE 'clarif|confirm|Q&A|TBD|Open Questions|Questions' "$SPEC" 2>/dev/null; then
  echo "  ✅ Spec contains clarification/confirmation content"
else
  echo "  ⚠️  No clarification records found in spec"
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

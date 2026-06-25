#!/usr/bin/env bash
# compliance.sh — Compliance audit gate (soft gate)
# Checks whether the agent followed Lattice behavioral rules
# Exit codes: 0=compliant, 1=warnings (non-blocking by default)
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery gate compliance" "Check agent behavioral compliance (soft gate, non-blocking)" \
    "compliance.sh [spec-file]    Check if spec references knowledge base entries" \
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

KNOWLEDGE_DIR="$PROJECT_ROOT/$(manifest_get '.knowledge.local_dir')"
KNOWLEDGE_DIR="${KNOWLEDGE_DIR:-$PROJECT_ROOT/lattice/knowledge}"

echo "🔍 Compliance Audit: $(basename "$SPEC")"
echo ""

WARNINGS=0

# ── 1. Knowledge base reference check ──
echo "── Knowledge base reference check ──"
if [[ -d "$KNOWLEDGE_DIR" ]]; then
  KNOWLEDGE_FILES=$(find "$KNOWLEDGE_DIR" -name "*.md" -not -name "index.md" -not -name "README.md" 2>/dev/null)
  REFERENCED=0
  TOTAL_KB=0

  while IFS= read -r kb_file; do
    [[ -z "$kb_file" ]] && continue
    ((TOTAL_KB++))
    slug=$(basename "$kb_file" .md)
    if grep -qi "$slug" "$SPEC" 2>/dev/null; then
      ((REFERENCED++))
      echo "  ✅ Referenced knowledge: $slug"
    fi
  done <<< "$KNOWLEDGE_FILES"

  if [[ "$TOTAL_KB" -gt 0 ]] && [[ "$REFERENCED" -eq 0 ]]; then
    echo "  ⚠️  Spec does not reference any knowledge base entries"
    echo "     Knowledge base has $TOTAL_KB entries, but none cited in spec"
    echo "     Possible cause: loader.sh was not run during design phase"
    ((WARNINGS++))
  elif [[ "$TOTAL_KB" -eq 0 ]]; then
    echo "  ⏭️  Knowledge base is empty, skipping"
  fi
else
  echo "  ⏭️  Knowledge base directory not found"
fi

# ── 2. loader.sh invocation trace in git log ──
echo ""
echo "── loader.sh invocation trace ──"
RECENT_COMMITS=$(git -C "$PROJECT_ROOT" log --oneline -20 2>/dev/null || echo "")
if echo "$RECENT_COMMITS" | grep -qi "knowledge\|loader"; then
  echo "  ✅ Recent commits contain knowledge-related activity"
else
  echo "  ⚠️  No knowledge-related activity in last 20 commits"
  ((WARNINGS++))
fi

# ── 3. Requirements clarification check ──
echo ""
echo "── Requirements clarification check ──"
if grep -qiE 'clarif|confirm|Q&A|TBD' "$SPEC" 2>/dev/null; then
  echo "  ✅ Spec contains clarification/confirmation content"
else
  echo "  ⚠️  No clarification records found in spec (requirements may not have been clarified)"
  ((WARNINGS++))
fi

# ── Summary ──
echo ""
echo "══════════════════════════════════"
if [[ "$WARNINGS" -eq 0 ]]; then
  echo "📊 Compliance Audit: ✅ no warnings"
  exit 0
else
  echo "📊 Compliance Audit: ⚠️  $WARNINGS warnings (soft rule)"
  if [[ "$STRICT" == "true" ]]; then
    echo "❌ FAIL (strict mode)"
    exit 1
  else
    echo "✅ PASS (soft gate, warnings for review reference)"
    exit 0
  fi
fi

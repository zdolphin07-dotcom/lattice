#!/usr/bin/env bash
# ac-coverage.sh — AC↔Test traceability coverage
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery gate ac-coverage" "Check AC number to test coverage" \
    "ac-coverage.sh [spec-file] [test-dir]    Check spec AC vs TestAC{nn} mapping" \
    "ac-coverage.sh --deep [spec] [test-dir]  Also detect empty tests and assertion drift" \
    "" \
    "Omit arguments to auto-discover latest spec and search project root"
done

DEEP_MODE=false
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --deep) DEEP_MODE=true ;;
    --help|-h) ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done
SPEC="${POSITIONAL[0]:-}"
TEST_DIR_ARG="${POSITIONAL[1]:-}"
SPEC="${SPEC:-}"
if [[ -z "$SPEC" ]]; then
  SPEC=$(find_spec) || { echo "⚠️  No spec file found, skipping"; exit 0; }
fi
TEST_DIR="${TEST_DIR_ARG:-$PROJECT_ROOT}"

[[ -f "$SPEC" ]] || { echo "Spec file not found: $SPEC"; exit 1; }

LANG=$(get_language)
echo "🔍 AC Coverage: $(basename "$SPEC") [$LANG]"
echo ""

case "$LANG" in
  go)
    FUNC_REGEX='func Test(AC|_AC)([0-9]+)'
    ;;
  node|javascript|typescript)
    FUNC_REGEX='(describe|it|test).*AC[_-]?([0-9]+)'
    ;;
  python)
    FUNC_REGEX='def test_ac([0-9]+)'
    ;;
  *)
    echo "⚠️  Unknown language: $LANG, using Go defaults"
    FUNC_REGEX='func Test(AC|_AC)([0-9]+)'
    ;;
esac

SPEC_ACS=$({ grep -E '^\| *AC-[0-9]+ *\|' "$SPEC" || true; } | { grep -o 'AC-[0-9]*' || true; } | sort -t- -k2 -n | uniq)
SPEC_COUNT=$(echo "$SPEC_ACS" | grep -c . || true)

if [[ "$SPEC_COUNT" -eq 0 ]]; then
  echo "⚠️  No AC numbers found in spec"
  exit 0
fi

echo "📋 Spec AC count: $SPEC_COUNT"

case "$LANG" in
  node|javascript|typescript)
    TEST_FILES=$(find "$TEST_DIR" \( -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" \) -not -path '*/node_modules/*' 2>/dev/null || true)
    ;;
  go)
    TEST_FILES=$(find "$TEST_DIR" -name "*_test.go" -not -path '*/vendor/*' 2>/dev/null || true)
    ;;
  python)
    TEST_FILES=$(find "$TEST_DIR" -name "test_*.py" -not -path '*/.venv/*' 2>/dev/null || true)
    ;;
  *)
    TEST_FILES=$(find "$TEST_DIR" -name "*_test.go" -not -path '*/vendor/*' 2>/dev/null || true)
    ;;
esac

COVERAGE_ROWS=""

if [[ -n "$TEST_FILES" ]]; then
  while IFS= read -r test_file; do
    [[ -z "$test_file" ]] && continue
    while IFS= read -r match_line; do
      [[ -z "$match_line" ]] && continue
      ac_num=$(echo "$match_line" | grep -oE 'AC[_-]?([0-9]+)' | grep -oE '[0-9]+' | head -1)
      [[ -z "$ac_num" ]] && continue
      ac_num=$((10#$ac_num))
      func_name=$(echo "$match_line" | grep -oE 'func [A-Za-z0-9_]+|def [a-z_0-9]+|(describe|it|test)\(' | head -1 | sed 's/^func //' | sed 's/^def //' | sed 's/($//')
      COVERAGE_ROWS+="$ac_num|${func_name:-unknown}"$'\n'
    done < <(grep -E "$FUNC_REGEX" "$test_file" 2>/dev/null || true)
  done <<< "$TEST_FILES"
fi

echo ""
echo "📋 AC Coverage Matrix:"
echo ""
echo "| AC | Spec Description | Test Function | Status |"
echo "|----|------------------|---------------|--------|"

COVERED_COUNT=0
UNCOVERED=""
while IFS= read -r ac; do
  num=${ac#AC-}
  desc=$(grep -E "^\| *$ac *\|" "$SPEC" | head -1 | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
  [[ -z "$desc" ]] && desc="—"

  func_name=$(printf '%s\n' "$COVERAGE_ROWS" | grep "^${num}|" 2>/dev/null | head -1 | cut -d'|' -f2 || true)

  if [[ -n "$func_name" ]]; then
    echo "| $ac | $desc | \`$func_name\` | ✅ |"
    ((COVERED_COUNT++))
  else
    echo "| $ac | $desc | — | ❌ Uncovered |"
    UNCOVERED="$UNCOVERED $ac"
  fi
done <<< "$SPEC_ACS"

DEEP_WARNINGS=0
if [[ "$DEEP_MODE" == "true" ]] && [[ -n "$TEST_FILES" ]]; then
  echo ""
  echo "🔬 Deep Analysis (experimental):"
  echo ""

  while IFS= read -r ac; do
    num=${ac#AC-}
    func_name=$(printf '%s\n' "$COVERAGE_ROWS" | grep "^${num}|" 2>/dev/null | head -1 | cut -d'|' -f2 || true)
    [[ -z "$func_name" ]] && continue

    while IFS= read -r test_file; do
      [[ -z "$test_file" ]] && continue
      if grep -A 5 "$func_name" "$test_file" 2>/dev/null | grep -qiE 't\.Skip|pytest\.skip|\.skip\(|pending\('; then
        echo "  ⚠️  $ac ($func_name): contains Skip/Pending — test not actually running"
        ((DEEP_WARNINGS++))
      fi

      func_body=$(sed -n "/func.*$func_name/,/^}/p" "$test_file" 2>/dev/null || \
                  sed -n "/def.*$func_name/,/^def\|^class/p" "$test_file" 2>/dev/null || true)
      if [[ -n "$func_body" ]]; then
        has_assert=$(echo "$func_body" | grep -ciE 'assert|expect|should|require|Equal|Error|Nil|True|False|Contains|Len' || true)
        if [[ "$has_assert" -eq 0 ]]; then
          echo "  ⚠️  $ac ($func_name): no assertions detected — may be empty test"
          ((DEEP_WARNINGS++))
        fi
      fi
    done <<< "$TEST_FILES"
  done <<< "$SPEC_ACS"

  if [[ "$DEEP_WARNINGS" -eq 0 ]]; then
    echo "  ✅ No suspicious tests found"
  else
    echo ""
    echo "  $DEEP_WARNINGS warnings (non-blocking, for review reference)"
  fi
fi

PERCENT=0
[[ "$SPEC_COUNT" -gt 0 ]] && PERCENT=$((COVERED_COUNT * 100 / SPEC_COUNT))

echo ""
echo "══════════════════════════════════"
echo "📊 AC Coverage: $COVERED_COUNT/$SPEC_COUNT ($PERCENT%)"

if [[ -n "$UNCOVERED" ]]; then
  echo "❌ FAIL — uncovered:$UNCOVERED"
  exit 1
else
  echo "✅ PASS — all ACs covered"
  exit 0
fi

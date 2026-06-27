#!/usr/bin/env bash
# drift-check.sh — Spec-Code drift detection
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery gate drift-check" "Detect drift between spec and code" \
    "drift-check.sh [spec-file] [project-root]    Detect DDL/route/error code drift" \
    "" \
    "Detects: DDL column drift (GORM) · Route drift (Gin/Echo/Chi) · Error code drift · Seed SQL drift"
done

SPEC="${1:-}"
if [[ -z "$SPEC" ]]; then
  SPEC=$(find_spec) || { echo "⚠️  No spec file found, skipping"; exit 0; }
fi
PROJECT="${2:-$PROJECT_ROOT}"

[[ -f "$SPEC" ]] || { echo "Spec file not found: $SPEC"; exit 1; }

LANG=$(get_language)
DRIFT=0

drift() { ((DRIFT++)); printf "  🔴 %s\n" "$*"; }
ok()    { printf "  ✅ %s\n" "$*"; }

echo "🔍 Drift Check: $(basename "$SPEC") ↔ code [$LANG]"
echo ""

# ══════════════════════════════════════════════════════
# 1. DDL drift (spec CREATE TABLE vs ORM model)
# ══════════════════════════════════════════════════════
echo "── DDL drift detection ──"

SPEC_TABLES=$({ grep -i 'CREATE TABLE' "$SPEC" || true; } | sed 's/.*`\([^`]*\)`.*/\1/' | sort)
SPEC_TABLE_COUNT=$(echo "$SPEC_TABLES" | grep -c . || true)

if [[ "$SPEC_TABLE_COUNT" -eq 0 ]]; then
  skip "No DDL in spec"
else
  ORM=$(manifest_get ".drift.ddl.orm")
  MODEL_TAG=$(manifest_get ".drift.ddl.model_tag")
  MODEL_DIRS=$(manifest_list ".drift.ddl.model_dirs[]")

  case "${ORM:-none}" in
    gorm)
      MODEL_FILES=""
      for dir in $MODEL_DIRS; do
        if [[ -d "$PROJECT/$dir" ]]; then
          found=$(find "$PROJECT/$dir" -name '*.go' -not -name '*_test.go' 2>/dev/null || true)
          MODEL_FILES="$MODEL_FILES $found"
        fi
      done
      if [[ -z "$MODEL_FILES" ]]; then
        MODEL_FILES=$(find "$PROJECT" -name '*.go' -not -path '*/vendor/*' -not -name '*_test.go' -exec grep -l "${MODEL_TAG:-column:}" {} + 2>/dev/null || true)
      fi

      if [[ -z "$MODEL_FILES" ]]; then
        skip "No GORM model files found"
      else
        ok "Spec DDL tables: $SPEC_TABLE_COUNT"
        while IFS= read -r table; do
          SPEC_COLS=$(awk "/CREATE TABLE \`$table\`/,/\) ENGINE/" "$SPEC" | grep -v -iE '^\s*(PRIMARY|UNIQUE|KEY|INDEX|CONSTRAINT|\))' | grep -oE '`[a-z_]+`' | sed 's/`//g' | grep -v "^$table$" | sort | uniq)
          MODEL_COLS=""
          for mf in $MODEL_FILES; do
            cols=$(grep -oE "${MODEL_TAG}[a-z_]+" "$mf" 2>/dev/null | sed "s/${MODEL_TAG}//" | sort)
            MODEL_COLS="$MODEL_COLS $cols"
          done
          MODEL_COLS=$(echo "$MODEL_COLS" | tr ' ' '\n' | grep -v '^$' | sort | uniq)

          if [[ -z "$MODEL_COLS" ]]; then
            skip "Table '$table': not found in model"
          else
            SPEC_ONLY=$(comm -23 <(echo "$SPEC_COLS") <(echo "$MODEL_COLS") 2>/dev/null || true)
            CODE_ONLY=$(comm -13 <(echo "$SPEC_COLS") <(echo "$MODEL_COLS") 2>/dev/null || true)
            if [[ -n "$SPEC_ONLY" ]]; then drift "Table '$table' — in spec but not code: $(echo "$SPEC_ONLY" | tr '\n' ', ')"; fi
            if [[ -n "$CODE_ONLY" ]]; then drift "Table '$table' — in code but not spec: $(echo "$CODE_ONLY" | tr '\n' ', ')"; fi
            if [[ -z "$SPEC_ONLY" ]] && [[ -z "$CODE_ONLY" ]]; then ok "Table '$table' columns match"; fi
          fi
        done <<< "$SPEC_TABLES"
      fi
      ;;
    sequelize|sqlalchemy|prisma)
      skip "ORM '$ORM' drift detection: not yet implemented (contributions welcome)"
      ;;
    none|*)
      skip "No ORM configured, skipping DDL drift detection"
      ;;
  esac
fi

echo ""

# ══════════════════════════════════════════════════════
# 2. Route drift (spec API table vs code route registration)
# ══════════════════════════════════════════════════════
echo "── Route drift detection ──"

SPEC_ROUTES=$({ grep -E '^\|.*\| *(GET|POST|PUT|DELETE|PATCH) *\|' "$SPEC" || true; } | \
  awk -F'|' '{
    method=$3; path=$4;
    gsub(/^[ \t]+|[ \t]+$/, "", method);
    gsub(/^[ \t]+|[ \t]+$/, "", path);
    if (method != "" && path != "") print method " " path
  }' | sort)
SPEC_ROUTE_COUNT=$(echo "$SPEC_ROUTES" | grep -c . || true)

if [[ "$SPEC_ROUTE_COUNT" -eq 0 ]]; then
  skip "No routes in spec API table"
else
  FRAMEWORK=$(manifest_get ".drift.routes.framework")

  case "${FRAMEWORK:-none}" in
    gin|echo|chi)
      ROUTER_FILES=$(find "$PROJECT" -name '*.go' -not -path '*/vendor/*' -exec grep -lE '\.(GET|POST|PUT|DELETE|PATCH)\(' {} + 2>/dev/null || true)

      if [[ -z "$ROUTER_FILES" ]]; then
        skip "No route registration code found"
      else
        ok "Spec routes: $SPEC_ROUTE_COUNT"
        while IFS= read -r spec_route; do
          method=$(echo "$spec_route" | awk '{print $1}')
          path=$(echo "$spec_route" | awk '{print $2}')
          endpoint=$(basename "$path")
          if echo "$ROUTER_FILES" | xargs grep -q "$method.*$endpoint" 2>/dev/null; then
            ok "Route: $method $path"
          else
            drift "Spec route not registered in code: $method $path"
          fi
        done <<< "$SPEC_ROUTES"
      fi
      ;;
    express|fastapi)
      skip "Framework '$FRAMEWORK' route drift detection: not yet implemented (contributions welcome)"
      ;;
    none|*)
      skip "No framework configured, skipping route drift"
      ;;
  esac
fi

echo ""

# ══════════════════════════════════════════════════════
# 3. Error code drift
# ══════════════════════════════════════════════════════
echo "── Error code drift detection ──"

SPEC_CODES=$({ grep -E '^\| *[0-9]+ *\|' "$SPEC" || true; } | \
  awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 ~ /^[0-9]+$/) print $2}' | \
  { grep -v '^0$' || true; } | sort -n | uniq)
SPEC_CODE_COUNT=$(echo "$SPEC_CODES" | grep -c . || true)

if [[ "$SPEC_CODE_COUNT" -eq 0 ]]; then
  skip "No business error codes in spec"
else
  CONST_PAT=$(manifest_get ".drift.error_codes.const_pattern")
  CODE_CONSTS=$(find "$PROJECT" -name '*.go' -not -path '*/vendor/*' \
    -exec grep -ohE "${CONST_PAT:-'(Code|Err)[A-Za-z]+ *= *[0-9]+'}" {} + 2>/dev/null | \
    grep -oE '[0-9]+' | sort -n | uniq || true)

  if [[ -z "$CODE_CONSTS" ]]; then
    skip "No error code constants found"
  else
    ok "Spec error codes: $SPEC_CODE_COUNT"
    while IFS= read -r code; do
      if echo "$CODE_CONSTS" | grep -q "^${code}$"; then
        ok "Error code $code"
      else
        drift "Spec error code $code not defined in code"
      fi
    done <<< "$SPEC_CODES"
  fi
fi

echo ""

# ══════════════════════════════════════════════════════
# 4. Seed SQL drift (spec vs fixtures)
# ══════════════════════════════════════════════════════
echo "── Seed SQL drift detection ──"

FIXTURE_FILE="$PROJECT_ROOT/lattice/fixtures/seed.sql"
if [[ -f "$FIXTURE_FILE" ]]; then
  SPEC_SEED=$(awk '/^```sql$/,/^```$/' "$SPEC" | tail -n +2 | grep -i 'INSERT' || true)
  FILE_SEED=$(grep -i 'INSERT' "$FIXTURE_FILE" || true)

  if [[ -z "$SPEC_SEED" ]]; then
    skip "No Seed SQL in spec"
  elif [[ "$SPEC_SEED" == "$FILE_SEED" ]]; then
    ok "Seed SQL consistent"
  else
    drift "fixtures/seed.sql differs from spec Seed SQL"
  fi
else
  skip "fixtures/seed.sql not found"
fi

# ── Plugin drift detection ──
PLUGIN_COUNT=$(yq '.drift.plugins | length // 0' "$MANIFEST" 2>/dev/null || echo 0)
if [[ "$PLUGIN_COUNT" -gt 0 ]]; then
  echo ""
  echo "── Plugin drift detection ──"
  for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
    plugin_name=$(yq -r ".drift.plugins[$i].name" "$MANIFEST")
    plugin_run=$(yq -r ".drift.plugins[$i].run" "$MANIFEST")
    [[ -z "$plugin_name" || "$plugin_name" == "null" ]] && continue
    [[ -z "$plugin_run" || "$plugin_run" == "null" ]] && continue

    plugin_run="${plugin_run//\$\{SPEC_FILE\}/$SPEC}"
    plugin_run="${plugin_run//\$\{PROJECT_ROOT\}/$PROJECT_ROOT}"

    printf "  🔌 %s: %s\n" "$plugin_name" "$plugin_run"
    if bash -c "$plugin_run" 2>&1 | sed 's/^/    /'; then
      echo "  ✅ $plugin_name: no drift"
    else
      echo "  ❌ $plugin_name: drift detected"
      ((DRIFT++))
    fi
  done
fi

echo ""
echo "══════════════════════════════════"

if [[ $DRIFT -gt 0 ]]; then
  echo "📊 Drift Check: 🔴 $DRIFT drifts detected"
  echo "❌ FAIL — update spec or fix code to resolve drift"
  exit 1
else
  echo "📊 Drift Check: no drift"
  echo "✅ PASS"
  exit 0
fi

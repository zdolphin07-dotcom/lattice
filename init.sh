#!/usr/bin/env bash
# init.sh — Lattice project initialization
# Detects project language/framework, copies scaffold, generates manifest, appends CLAUDE.md
#
# Usage:
#   init.sh                — Interactive initialization
#   init.sh --non-interactive --lang=go --name=myapp  — Non-interactive
#
# Exit codes: 0=success, 1=failure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCAFFOLD_DIR=""

for candidate in \
  "$(pwd)/.lattice/framework/scaffold" \
  "$SCRIPT_DIR/scaffold" \
  "$HOME/.agents/skills/lattice/scaffold"; do
  if [[ -d "$candidate/lattice/kernel" ]]; then
    SCAFFOLD_DIR="$candidate"
    break
  fi
done

if [[ -z "$SCAFFOLD_DIR" ]]; then
  echo "Cannot find scaffold directory"
  echo "   Make sure Lattice is installed to .lattice/framework/"
  exit 1
fi

FRAMEWORK_ROOT="$(cd "$SCAFFOLD_DIR/.." && pwd)"
PRISMSPEC_SOURCE="$FRAMEWORK_ROOT/prismspec"

PROJECT_ROOT="$(pwd)"

for tool in yq git; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Missing required tool: $tool"
    exit 1
  fi
done

NON_INTERACTIVE=false
PARAM_LANG="" PARAM_NAME="" PARAM_FRAMEWORK="" PARAM_ORM="" PARAM_DB="" PARAM_CI=""

for arg in "$@"; do
  case "$arg" in
    --non-interactive) NON_INTERACTIVE=true ;;
    --lang=*)       PARAM_LANG="${arg#--lang=}" ;;
    --name=*)       PARAM_NAME="${arg#--name=}" ;;
    --framework=*)  PARAM_FRAMEWORK="${arg#--framework=}" ;;
    --orm=*)        PARAM_ORM="${arg#--orm=}" ;;
    --db=*)         PARAM_DB="${arg#--db=}" ;;
    --ci=*)         PARAM_CI="${arg#--ci=}" ;;
  esac
done

ask() {
  local prompt="$1" default="$2" var_name="$3"
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    printf -v "$var_name" '%s' "$default"
    return
  fi
  printf "%s [%s]: " "$prompt" "$default"
  read -r answer
  answer="${answer:-$default}"
  printf -v "$var_name" '%s' "$answer"
}

ask_choice() {
  local prompt="$1" default="$2" var_name="$3"
  shift 3
  local choices=("$@")

  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    printf -v "$var_name" '%s' "$default"
    return
  fi

  echo "$prompt"
  local i=1
  for c in "${choices[@]}"; do
    local marker=""
    [[ "$c" == "$default" ]] && marker=" (default)"
    printf "  %d) %s%s\n" "$i" "$c" "$marker"
    ((i++))
  done
  printf "Choose [%s]: " "$default"
  read -r answer
  answer="${answer:-$default}"

  if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#choices[@]} )); then
    answer="${choices[$((answer-1))]}"
  fi
  printf -v "$var_name" '%s' "$answer"
}

echo "══════════════════════════════════"
echo "Lattice — Init"
echo "══════════════════════════════════"
echo ""

echo "🔍 Detecting project info..."

DETECTED_LANG="unknown"
DETECTED_NAME="$(basename "$PROJECT_ROOT")"
DETECTED_FRAMEWORK="none"
DETECTED_ORM="none"
DETECTED_DB="none"
DETECTED_VERSION=""

if [[ -f "go.mod" ]]; then
  DETECTED_LANG="go"
  DETECTED_NAME=$(head -1 go.mod | awk '{print $2}' | awk -F/ '{print $NF}')
  DETECTED_VERSION=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go/>=/')
  grep -q "gin-gonic/gin" go.mod 2>/dev/null && DETECTED_FRAMEWORK="gin"
  grep -q "labstack/echo" go.mod 2>/dev/null && DETECTED_FRAMEWORK="echo"
  grep -q "go-chi/chi" go.mod 2>/dev/null && DETECTED_FRAMEWORK="chi"
  grep -q "gorm.io/gorm" go.mod 2>/dev/null && DETECTED_ORM="gorm"
  grep -q "ent/ent" go.mod 2>/dev/null && DETECTED_ORM="ent"
elif [[ -f "package.json" ]]; then
  DETECTED_LANG="node"
  DETECTED_NAME=$(yq -r '.name // "unknown"' package.json 2>/dev/null || echo "unknown")
  DETECTED_VERSION=$(node --version 2>/dev/null | sed 's/v/>=/' || echo "")
  grep -q '"express"' package.json 2>/dev/null && DETECTED_FRAMEWORK="express"
  grep -q '"@nestjs/core"' package.json 2>/dev/null && DETECTED_FRAMEWORK="nestjs"
  grep -q '"koa"' package.json 2>/dev/null && DETECTED_FRAMEWORK="koa"
  grep -q '"fastify"' package.json 2>/dev/null && DETECTED_FRAMEWORK="fastify"
  grep -q '"sequelize"' package.json 2>/dev/null && DETECTED_ORM="sequelize"
  grep -q '"prisma"' package.json 2>/dev/null && DETECTED_ORM="prisma"
  grep -q '"typeorm"' package.json 2>/dev/null && DETECTED_ORM="typeorm"
elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
  DETECTED_LANG="python"
  [[ -f "pyproject.toml" ]] && DETECTED_NAME=$(grep '^name' pyproject.toml 2>/dev/null | head -1 | sed 's/.*= *"\(.*\)"/\1/' || echo "unknown")
  DETECTED_VERSION=$(python3 --version 2>/dev/null | awk '{print ">="$2}' || echo "")
  src="${PROJECT_ROOT}/requirements.txt"
  [[ -f "pyproject.toml" ]] && src="pyproject.toml"
  grep -qi "fastapi" "$src" 2>/dev/null && DETECTED_FRAMEWORK="fastapi"
  grep -qi "flask" "$src" 2>/dev/null && DETECTED_FRAMEWORK="flask"
  grep -qi "django" "$src" 2>/dev/null && DETECTED_FRAMEWORK="django"
  grep -qi "sqlalchemy" "$src" 2>/dev/null && DETECTED_ORM="sqlalchemy"
elif [[ -f "Cargo.toml" ]]; then
  DETECTED_LANG="rust"
  DETECTED_NAME=$(grep '^name' Cargo.toml | head -1 | sed 's/.*= *"\(.*\)"/\1/')
elif [[ -f "pom.xml" ]]; then
  DETECTED_LANG="java"
fi

for f in docker-compose.yml docker-compose.yaml .env; do
  if [[ -f "$f" ]]; then
    grep -qi "mysql" "$f" 2>/dev/null && DETECTED_DB="mysql"
    grep -qi "postgres" "$f" 2>/dev/null && DETECTED_DB="postgresql"
    grep -qi "mongo" "$f" 2>/dev/null && DETECTED_DB="mongodb"
    grep -qi "redis" "$f" 2>/dev/null && [[ "$DETECTED_DB" != "none" ]] && DETECTED_DB="${DETECTED_DB}+redis"
  fi
done

echo "  Language:  $DETECTED_LANG"
echo "  Name:      $DETECTED_NAME"
echo "  Framework: $DETECTED_FRAMEWORK"
echo "  ORM:       $DETECTED_ORM"
echo "  Database:  $DETECTED_DB"
echo ""

LANG="${PARAM_LANG:-$DETECTED_LANG}"
NAME="${PARAM_NAME:-$DETECTED_NAME}"
FRAMEWORK="${PARAM_FRAMEWORK:-$DETECTED_FRAMEWORK}"
ORM="${PARAM_ORM:-$DETECTED_ORM}"
DB="${PARAM_DB:-$DETECTED_DB}"
CI="${PARAM_CI:-none}"
VERSION="${DETECTED_VERSION:->=1.0}"

ask "Project name" "$NAME" "NAME"
ask_choice "Language" "$LANG" "LANG" "go" "node" "python" "rust" "java"
ask "Framework" "$FRAMEWORK" "FRAMEWORK"
ask "ORM" "$ORM" "ORM"
ask "Database" "$DB" "DB"
ask_choice "CI platform" "$CI" "CI" "none" "gitlab" "github" "jenkins"

echo ""
echo "✅ Configuration confirmed:"
echo "  Project: $NAME ($LANG)"
echo "  Framework: $FRAMEWORK | ORM: $ORM | DB: $DB | CI: $CI"
echo ""

echo "📁 Copying scaffold files..."

copy_if_not_exists() {
  local src="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    echo "  ⏭️  Already exists: $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✅ $dest"
  fi
}

copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/_lib.sh" "lattice/kernel/_lib.sh"
copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/orchestrator/templates/spec-template.md" "lattice/kernel/orchestrator/templates/spec-template.md"
copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/orchestrator/rules.md" "lattice/kernel/orchestrator/rules.md"
copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/orchestrator/flow.yaml" "lattice/kernel/orchestrator/flow.yaml"
for f in task-brief.sh review-package.sh; do
  copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/orchestrator/sdd/$f" "lattice/kernel/orchestrator/sdd/$f"
done

for f in loader.sh sync.sh README.md; do
  copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/knowledge/$f" "lattice/kernel/knowledge/$f"
done

for f in pipeline.sh bootstrap.sh deploy.sh; do
  copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/delivery/$f" "lattice/kernel/delivery/$f"
done
for f in spec-lint.sh ac-coverage.sh drift-check.sh compliance.sh spec-lock.sh; do
  copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/delivery/gates/$f" "lattice/kernel/delivery/gates/$f"
done

copy_if_not_exists "$SCAFFOLD_DIR/lattice/kernel/VERSION" "lattice/kernel/VERSION"

for dir in requirements specs plans state skills; do
  mkdir -p "lattice/$dir"
  [[ -f "lattice/$dir/.gitkeep" ]] || touch "lattice/$dir/.gitkeep"
done

if [[ -d "$PRISMSPEC_SOURCE" ]]; then
  mkdir -p prismspec
  for dir in skills templates; do
    if [[ -d "$PRISMSPEC_SOURCE/$dir" ]]; then
      mkdir -p "prismspec/$dir"
      for src in "$PRISMSPEC_SOURCE/$dir"/*; do
        [[ -f "$src" ]] || continue
        copy_if_not_exists "$src" "prismspec/$dir/$(basename "$src")"
      done
    fi
  done
  copy_if_not_exists "$PRISMSPEC_SOURCE/README.md" "prismspec/README.md"
fi

chmod +x lattice/kernel/_lib.sh lattice/kernel/knowledge/*.sh lattice/kernel/delivery/*.sh lattice/kernel/delivery/gates/*.sh lattice/kernel/orchestrator/sdd/*.sh 2>/dev/null || true

if [[ -d ".git" ]]; then
  touch .gitignore
  if ! grep -qxF ".lattice/sdd/" .gitignore; then
    {
      echo ""
      echo "# Lattice transient SDD evidence"
      echo ".lattice/sdd/"
    } >> .gitignore
    echo "  ✅ .gitignore: .lattice/sdd/"
  fi
  if ! grep -qxF ".prismspec/runs/" .gitignore; then
    {
      echo ""
      echo "# PrismSpec transient execution evidence"
      echo ".prismspec/runs/"
    } >> .gitignore
    echo "  ✅ .gitignore: .prismspec/runs/"
  fi
fi

copy_if_not_exists "$SCAFFOLD_DIR/lattice/knowledge/index.md" "lattice/knowledge/index.md"
copy_if_not_exists "$SCAFFOLD_DIR/lattice/knowledge/synonyms.txt" "lattice/knowledge/synonyms.txt"

for f in init.md sdd.md brainstorm.md plan.md implement.md verify.md finish.md learn.md; do
  copy_if_not_exists "$SCAFFOLD_DIR/lattice/skills/$f" "lattice/skills/$f"
done

for f in init.md sdd.md brainstorm.md plan.md implement.md verify.md finish.md learn.md; do
  copy_if_not_exists "$SCAFFOLD_DIR/.claude/commands/$f" ".claude/commands/$f"
done

echo ""
echo "📝 Generating manifest.yaml..."

MANIFEST_FILE="lattice/manifest.yaml"

if [[ -f "$MANIFEST_FILE" ]]; then
  echo "  ⏭️  Already exists: $MANIFEST_FILE (skipping generation)"
else
  case "$LANG" in
    go)
      CMD_BUILD="go build ./..."
      CMD_LINT="go vet ./..."
      CMD_TEST="go test ./... -short -count=1"
      CMD_ITEST="go test ./tests/integration/... -tags=integration -timeout=10m"
      TOOL_CHECK="go version"
      BUILDER_IMAGE="golang:1.22-alpine"
      RUNNER_IMAGE="alpine:3.19"
      ;;
    node)
      CMD_BUILD="npm run build"
      CMD_LINT="npm run lint"
      CMD_TEST="npm test"
      CMD_ITEST="npm run test:integration"
      TOOL_CHECK="node --version"
      BUILDER_IMAGE="node:20-alpine"
      RUNNER_IMAGE="node:20-alpine"
      ;;
    python)
      CMD_BUILD="python -m py_compile *.py"
      CMD_LINT="ruff check ."
      CMD_TEST="pytest -x"
      CMD_ITEST="pytest tests/integration/ -x"
      TOOL_CHECK="python3 --version"
      BUILDER_IMAGE="python:3.12-slim"
      RUNNER_IMAGE="python:3.12-slim"
      ;;
    rust)
      CMD_BUILD="cargo build"
      CMD_LINT="cargo clippy"
      CMD_TEST="cargo test"
      CMD_ITEST="cargo test --test integration"
      TOOL_CHECK="rustc --version"
      BUILDER_IMAGE="rust:1.77-slim"
      RUNNER_IMAGE="debian:bookworm-slim"
      ;;
    java)
      CMD_BUILD="mvn compile"
      CMD_LINT="mvn checkstyle:check"
      CMD_TEST="mvn test"
      CMD_ITEST="mvn verify -Pintegration"
      TOOL_CHECK="java --version"
      BUILDER_IMAGE="maven:3.9-eclipse-temurin-21"
      RUNNER_IMAGE="eclipse-temurin:21-jre-alpine"
      ;;
    *)
      CMD_BUILD="echo 'no build'"
      CMD_LINT="echo 'no lint'"
      CMD_TEST="echo 'no test'"
      CMD_ITEST="echo 'no integration test'"
      TOOL_CHECK="echo 'unknown'"
      BUILDER_IMAGE="alpine:latest"
      RUNNER_IMAGE="alpine:latest"
      ;;
  esac

  MODEL_TAG=""
  MODEL_DIRS='["internal/model", "models"]'
  case "$ORM" in
    gorm)        MODEL_TAG="column:" ; MODEL_DIRS='["internal/model", "model"]' ;;
    sequelize)   MODEL_TAG="" ; MODEL_DIRS='["models", "src/models"]' ;;
    sqlalchemy)  MODEL_TAG="" ; MODEL_DIRS='["models", "app/models"]' ;;
    prisma)      MODEL_TAG="" ; MODEL_DIRS='["prisma"]' ;;
  esac

  case "$LANG" in
    go)     TEST_FILE_PAT="*_test.go" ; TEST_FUNC_RE='func Test(AC|_AC)([0-9]+)' ;;
    node)   TEST_FILE_PAT="*.test.ts" ; TEST_FUNC_RE='(describe|it|test).*AC[_-]?([0-9]+)' ;;
    python) TEST_FILE_PAT="test_*.py" ; TEST_FUNC_RE='def test_ac([0-9]+)' ;;
    *)      TEST_FILE_PAT="*_test.*"  ; TEST_FUNC_RE='TestAC([0-9]+)' ;;
  esac

  ROUTER_PATTERN=""
  case "$FRAMEWORK" in
    gin|echo|chi) ROUTER_PATTERN='\.(GET|POST|PUT|DELETE|PATCH)\("([^"]+)"' ;;
    express)      ROUTER_PATTERN='\.(get|post|put|delete|patch)\(["\x27]([^"\x27]+)' ;;
    fastapi)      ROUTER_PATTERN='@app\.(get|post|put|delete)\("([^"]+)"' ;;
  esac

  cat > "$MANIFEST_FILE" <<YAML
# manifest.yaml — Lattice project declaration
# Auto-generated by lattice init on $(date +%Y-%m-%d)

project:
  name: ${NAME}
  language: ${LANG}
  version_constraint: "${VERSION}"

tools:
  required:
    - { name: ${LANG}, check: "${TOOL_CHECK}" }
    - { name: yq,      check: "yq --version" }
  optional:
    - { name: docker,  check: "docker --version" }
    - { name: kubectl, check: "kubectl version --client 2>/dev/null" }

services:
  local: []
  test: []

commands:
  build:            "${CMD_BUILD}"
  lint:             "${CMD_LINT}"
  test:             "${CMD_TEST}"
  integration_test: "${CMD_ITEST}"
  smoke_test:       ""

specs:
  dir: "lattice/specs"
  # Optional active spec selector. Accepts either a spec id under specs.dir or a path.
  active: ""
  # Override this path to use a project/team-specific spec template.
  # The default template is a compact contract used by PrismSpec.
  template: "lattice/kernel/orchestrator/templates/spec-template.md"
  # auto = model selects plan or tdd by risk; plan/tdd force a project default.
  # A user may still override the mode for a single spec in /sdd or /brainstorm.
  default_execution_mode: "auto"
  allow_execution_mode_override: true
  required_sections:
    - "Intent"
    - "Scope"
    - "Context"
    - "Acceptance Criteria"
    - "Design Decisions"
    - "Execution Policy"
    - "Verification Plan"

testing:
  strategies:
    ${LANG}:
      file_pattern: "${TEST_FILE_PAT}"
      func_regex: '${TEST_FUNC_RE}'

drift:
  ddl:
    orm: ${ORM}
    model_tag: '${MODEL_TAG}'
    model_dirs: ${MODEL_DIRS}
  routes:
    framework: ${FRAMEWORK}
    router_pattern: '${ROUTER_PATTERN}'
  error_codes:
    const_pattern: '(Code|Err)[A-Za-z]+ *= *[0-9]+'

pipeline:
  steps:
    - { name: bootstrap,        run: "lattice/kernel/delivery/bootstrap.sh check",              skip_when: never }
    - { name: spec-lint,        run: "lattice/kernel/delivery/gates/spec-lint.sh \${SPEC_FILE}",      skip_when: no_spec }
    - { name: build,            run: "\${commands.build}",                                   skip_when: no_code }
    - { name: lint,             run: "\${commands.lint}",                                    skip_when: no_code }
    - { name: unit-test,        run: "\${commands.test}",                                    skip_when: no_code }
    - { name: ac-coverage,      run: "lattice/kernel/delivery/gates/ac-coverage.sh \${SPEC_FILE} .",  skip_when: no_spec }
    - { name: integration-test, run: "\${commands.integration_test}",                        skip_when: no_integration }
    - { name: drift-check,      run: "lattice/kernel/delivery/gates/drift-check.sh \${SPEC_FILE} .",  skip_when: no_spec }
    - { name: compliance,       run: "lattice/kernel/delivery/gates/compliance.sh \${SPEC_FILE}",     skip_when: no_spec }

deploy:
  docker:
    builder_image: "${BUILDER_IMAGE}"
    runner_image:  "${RUNNER_IMAGE}"
    dockerfile:    "deploy/Dockerfile"
  registry: "\${DOCKER_REGISTRY}"
  environments:
    test:
      namespace: "${NAME}-test"
      manifests: "deploy/k8s/"
      rollback: auto
      smoke_after_deploy: true

knowledge:
  local_dir: "lattice/knowledge"
  remote_dir: "lattice/knowledge/remote"
  sources: []
YAML
  echo "  ✅ $MANIFEST_FILE"
fi

echo ""
echo "📝 Configuring CLAUDE.md..."

SSD_RULES="$SCAFFOLD_DIR/CLAUDE.ssd.md"
if [[ -f "CLAUDE.md" ]]; then
  if grep -q "Lattice\|lattice\|SpecHarness\|specharness" "CLAUDE.md" 2>/dev/null; then
    echo "  ⏭️  CLAUDE.md already contains Lattice rules"
  elif [[ -f "$SSD_RULES" ]]; then
    echo "" >> CLAUDE.md
    cat "$SSD_RULES" >> CLAUDE.md
    echo "  ✅ Appended Lattice rules to CLAUDE.md"
  fi
else
  if [[ -f "$SSD_RULES" ]]; then
    cp "$SSD_RULES" CLAUDE.md
    echo "  ✅ Created CLAUDE.md"
  fi
fi

echo ""
echo "🔍 Verifying environment..."
if bash lattice/kernel/delivery/bootstrap.sh check 2>/dev/null; then
  echo ""
else
  echo ""
  echo "⚠️  Some tools missing. Install them and retry."
fi

echo ""
echo "══════════════════════════════════"
echo "✅ Lattice initialization complete"
echo ""
echo "Project: $NAME ($LANG)"
echo "Artifacts:"
echo "  lattice/manifest.yaml        — Project declaration (review config)"
echo "  lattice/kernel/              — Harness kernel (3 layers)"
echo "  lattice/requirements/        — Requirements input"
echo "  lattice/specs/  plans/       — Design / plan"
echo "  lattice/knowledge/           — Knowledge base"
echo "  prismspec/                   — Standalone PrismSpec skills module"
echo "  .claude/commands/                — Slash commands"
echo ""
echo "Usage:"
echo "  /sdd \"requirement\" — Guided workflow with artifact-based resume"
echo "  /brainstorm       — Draft persistent spec"
echo "  /plan             — Create AC-traced plan"
echo "  /implement        — Execute plan/tdd policy"
echo "  /verify           — Run verification pipeline"
echo "  /finish           — Close delivery and extract knowledge"
echo "  /learn \"lesson\"   — Capture knowledge to knowledge base"
echo "  Describe a requirement — Full spec-driven workflow"
echo "══════════════════════════════════"

#!/usr/bin/env bash
# new.sh - Create a PrismSpec spec directory from templates.
set -euo pipefail

SPEC_ID=""
TITLE=""
TEMPLATE="default"
MODE="auto"
OWNER="${USER:-agent}"
FORCE=false
JSON=false

usage() {
  cat <<'EOF'
PrismSpec new

Usage:
  bash prismspec/bin/new.sh <spec-id> [--title=<title>] [--template=default|lite|service|frontend|tdd] [--mode=auto|plan|tdd] [--owner=<name>] [--force] [--json]

Examples:
  bash prismspec/bin/new.sh checkout-flow --title="Checkout Flow"
  bash prismspec/bin/new.sh payment-regression --template=tdd --mode=tdd
EOF
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --title=*) TITLE="${arg#--title=}" ;;
    title=*) TITLE="${arg#title=}" ;;
    --template=*) TEMPLATE="${arg#--template=}" ;;
    template=*) TEMPLATE="${arg#template=}" ;;
    --mode=*) MODE="${arg#--mode=}" ;;
    mode=*) MODE="${arg#mode=}" ;;
    --owner=*) OWNER="${arg#--owner=}" ;;
    owner=*) OWNER="${arg#owner=}" ;;
    --force) FORCE=true ;;
    --json) JSON=true ;;
    --*) echo "Unknown argument: $arg" >&2; usage; exit 1 ;;
    *)
      if [[ -z "$SPEC_ID" ]]; then
        SPEC_ID="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

[[ -n "$SPEC_ID" ]] || { usage; exit 1; }

case "$SPEC_ID" in
  *[!A-Za-z0-9._-]*)
    echo "Invalid spec id: $SPEC_ID" >&2
    echo "Use letters, numbers, dot, underscore, or dash." >&2
    exit 1
    ;;
esac

case "$TEMPLATE" in
  default|lite|service|frontend|tdd) ;;
  *) echo "Invalid template: $TEMPLATE" >&2; exit 1 ;;
esac

case "$MODE" in
  auto|plan|tdd) ;;
  *) echo "Invalid mode: $MODE" >&2; exit 1 ;;
esac

ROOT="$(pwd)"
HOST="standalone"
SPEC_ROOT="prismspec/specs"
TEMPLATE_ROOT="prismspec/templates"

if [[ -f "$ROOT/lattice/manifest.yaml" ]]; then
  HOST="lattice"
  SPEC_ROOT="lattice/specs"
  if command -v yq >/dev/null 2>&1; then
    SPEC_ROOT="$(yq -r '.specs.dir // "lattice/specs"' lattice/manifest.yaml 2>/dev/null || echo "lattice/specs")"
    [[ -n "$SPEC_ROOT" && "$SPEC_ROOT" != "null" ]] || SPEC_ROOT="lattice/specs"
  fi
fi

if [[ -z "$TITLE" ]]; then
  TITLE="$(printf '%s' "$SPEC_ID" | tr '._-' '   ' | awk '{ for (i=1; i<=NF; i++) { $i=toupper(substr($i,1,1)) substr($i,2) } print }')"
fi

template_file_for() {
  case "$1" in
    default) echo "$TEMPLATE_ROOT/spec-template.md" ;;
    lite) echo "$TEMPLATE_ROOT/spec-template-lite.md" ;;
    service) echo "$TEMPLATE_ROOT/spec-template-service.md" ;;
    frontend) echo "$TEMPLATE_ROOT/spec-template-frontend.md" ;;
    tdd) echo "$TEMPLATE_ROOT/spec-template-tdd.md" ;;
  esac
}

SPEC_TEMPLATE="$(template_file_for "$TEMPLATE")"
CONTEXT_TEMPLATE="$TEMPLATE_ROOT/context-template.md"
SPEC_DIR="$SPEC_ROOT/$SPEC_ID"
SPEC_FILE="$SPEC_DIR/spec.md"
CONTEXT_FILE="$SPEC_DIR/context.md"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

[[ -f "$SPEC_TEMPLATE" ]] || { echo "Spec template not found: $SPEC_TEMPLATE" >&2; exit 1; }
[[ -f "$CONTEXT_TEMPLATE" ]] || { echo "Context template not found: $CONTEXT_TEMPLATE" >&2; exit 1; }

if [[ -e "$SPEC_DIR" && "$FORCE" != "true" ]]; then
  echo "Spec directory already exists: $SPEC_DIR" >&2
  echo "Use --force to overwrite context.md/spec.md." >&2
  exit 1
fi

sed_escape() {
  printf '%s' "$1" | sed -e 's/[\/&@]/\\&/g'
}

render_template() {
  local source="$1"
  local target="$2"
  local spec_id title title_text mode owner timestamp
  spec_id="$(sed_escape "$SPEC_ID")"
  title="$(sed_escape "$TITLE")"
  title_text="$(sed_escape "$TITLE")"
  mode="$(sed_escape "$MODE")"
  owner="$(sed_escape "$OWNER")"
  timestamp="$(sed_escape "$TIMESTAMP")"
  sed \
    -e "s@{spec-id}@$spec_id@g" \
    -e "s@{title}@$title@g" \
    -e "s@{Title}@$title_text@g" \
    -e "s@{auto|plan|tdd}@$mode@g" \
    -e "s@{plan|tdd}@$mode@g" \
    -e "s@{owner}@$owner@g" \
    -e "s@{timestamp}@$timestamp@g" \
    "$source" > "$target"
}

mark_scaffolded() {
  local target="$1"
  local tmp="${target}.tmp"

  awk '
    NR == 1 && $0 == "---" {
      in_frontmatter = 1
      print
      next
    }
    in_frontmatter && $0 ~ /^scaffolded:/ {
      next
    }
    in_frontmatter && $0 ~ /^status:/ && !added {
      print
      print "scaffolded: true"
      added = 1
      next
    }
    in_frontmatter && $0 == "---" {
      if (!added) {
        print "scaffolded: true"
        added = 1
      }
      print
      in_frontmatter = 0
      next
    }
    { print }
  ' "$target" > "$tmp"
  mv "$tmp" "$target"
}

mkdir -p "$SPEC_DIR"
render_template "$CONTEXT_TEMPLATE" "$CONTEXT_FILE"
render_template "$SPEC_TEMPLATE" "$SPEC_FILE"
mark_scaffolded "$SPEC_FILE"

if [[ "$JSON" == "true" ]]; then
  printf '{\n'
  printf '  "host": "%s",\n' "$HOST"
  printf '  "spec_id": "%s",\n' "$SPEC_ID"
  printf '  "template": "%s",\n' "$TEMPLATE"
  printf '  "mode": "%s",\n' "$MODE"
  printf '  "spec_dir": "%s",\n' "$SPEC_DIR"
  printf '  "context_file": "%s",\n' "$CONTEXT_FILE"
  printf '  "spec_file": "%s"\n' "$SPEC_FILE"
  printf '}\n'
  exit 0
fi

echo "PrismSpec created"
echo ""
echo "Host:    $HOST"
echo "Spec:    $SPEC_ID"
echo "Mode:    $MODE"
echo "Template: $TEMPLATE"
echo "Files:"
echo "  $CONTEXT_FILE"
echo "  $SPEC_FILE"
echo ""
echo "Next:"
echo "  Fill context.md and spec.md, then run:"
echo "  bash prismspec/bin/lint.sh $SPEC_FILE spec"

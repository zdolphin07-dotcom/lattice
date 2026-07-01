#!/usr/bin/env bash
# capabilities.sh — Lattice runtime capability declaration.
# This is the stable discovery surface for IDE adapters and MCP servers.
source "$(dirname "$0")/_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "capabilities" "Print Lattice runtime capabilities as JSON" \
    "capabilities.sh --json              Print capability declaration" \
    "capabilities.sh                     Print capability declaration"
done

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

json_bool() {
  case "${1:-}" in
    true) printf 'true' ;;
    *) printf 'false' ;;
  esac
}

kernel_version() {
  local version_file="$KERNEL_DIR/VERSION"
  if [[ -f "$version_file" ]]; then
    head -1 "$version_file" | tr -d '[:space:]'
  else
    printf 'unknown'
  fi
}

has_executable() {
  local path="$1"
  [[ -x "$PROJECT_ROOT/$path" ]] && printf 'true' || printf 'false'
}

render_stages() {
  cat <<'JSON'
[
    {
      "id": "specification",
      "label": "Spec",
      "order": 20,
      "description": "Clarify intent, context basis, scope, AC, risk, and verification plan."
    },
    {
      "id": "planning",
      "label": "Plan",
      "order": 30,
      "description": "Turn spec.md into AC-traced implementation tasks."
    },
    {
      "id": "implementation",
      "label": "Build",
      "order": 40,
      "description": "Execute the next plan task with required task evidence."
    },
    {
      "id": "review",
      "label": "Review",
      "order": 50,
      "description": "Review implementation evidence, diff, and quality risk."
    },
    {
      "id": "verification",
      "label": "Verify",
      "order": 60,
      "description": "Run fresh command-backed verification and record eval evidence."
    },
    {
      "id": "done",
      "label": "Done",
      "order": 70,
      "description": "Workflow is complete for the active spec."
    }
  ]
JSON
}

render_tools() {
  cat <<JSON
[
    {
      "id": "capabilities",
      "label": "Capabilities",
      "command": "bash lattice/kernel/capabilities.sh --json",
      "available": $(has_executable "lattice/kernel/capabilities.sh")
    },
    {
      "id": "guide",
      "label": "Guide",
      "command": "bash prismspec/bin/guide.sh --json",
      "available": $(has_executable "prismspec/bin/guide.sh")
    },
    {
      "id": "doctor",
      "label": "Doctor",
      "command": "bash lattice/kernel/doctor.sh",
      "available": $(has_executable "lattice/kernel/doctor.sh")
    },
    {
      "id": "run_pipeline",
      "label": "Run Pipeline",
      "command": "bash lattice/kernel/delivery/pipeline.sh --json-out",
      "available": $(has_executable "lattice/kernel/delivery/pipeline.sh")
    },
    {
      "id": "eval_query",
      "label": "Eval Query",
      "command": "bash lattice/kernel/delivery/eval-query.sh summary --format=json",
      "available": $(has_executable "lattice/kernel/delivery/eval-query.sh")
    },
    {
      "id": "record_outcome",
      "label": "Record Outcome",
      "command": "bash lattice/kernel/delivery/outcome-link.sh record",
      "available": $(has_executable "lattice/kernel/delivery/outcome-link.sh")
    },
    {
      "id": "open_dashboard",
      "label": "Open Dashboard",
      "command": "bash lattice/kernel/delivery/eval-dashboard.sh",
      "available": $(has_executable "lattice/kernel/delivery/eval-dashboard.sh")
    }
  ]
JSON
}

render_actions() {
  cat <<'JSON'
[
    {
      "id": "continue",
      "label": "Continue",
      "kind": "primary",
      "tool": "guide",
      "description": "Resolve the next Lattice action from current repo artifacts.",
      "requires_confirmation": false
    },
    {
      "id": "verify",
      "label": "Verify",
      "kind": "primary",
      "tool": "run_pipeline",
      "description": "Run delivery pipeline with fresh command-backed evidence.",
      "requires_confirmation": false
    },
    {
      "id": "record_outcome",
      "label": "Record Outcome",
      "kind": "secondary",
      "tool": "record_outcome",
      "description": "Link post-delivery review, rework, escaped defect, incident, or success signal to an eval run.",
      "requires_confirmation": true
    }
  ]
JSON
}

render_metrics() {
  cat <<'JSON'
[
    {
      "id": "pipeline_status",
      "label": "Pipeline Status",
      "kind": "status",
      "scope": "run",
      "source": "eval-runs"
    },
    {
      "id": "first_pass",
      "label": "First-pass",
      "kind": "boolean",
      "scope": "run",
      "source": "eval-runs"
    },
    {
      "id": "ac_coverage",
      "label": "AC Coverage",
      "kind": "ratio",
      "scope": "run",
      "source": "eval-runs.metrics"
    },
    {
      "id": "drift_count",
      "label": "Drift",
      "kind": "count",
      "scope": "run",
      "source": "eval-runs.metrics"
    },
    {
      "id": "review_verdict",
      "label": "Review Verdict",
      "kind": "status",
      "scope": "run",
      "source": "process_evidence.review"
    },
    {
      "id": "outcome_count",
      "label": "Outcomes",
      "kind": "count",
      "scope": "team",
      "source": "outcomes"
    }
  ]
JSON
}

render_reports() {
  cat <<'JSON'
[
    {
      "id": "eval_summary",
      "label": "Eval Summary",
      "kind": "markdown",
      "command": "bash lattice/kernel/delivery/eval-summary.sh <eval-json>"
    },
    {
      "id": "eval_history",
      "label": "Eval History",
      "kind": "markdown",
      "command": "bash lattice/kernel/delivery/eval-history.sh"
    },
    {
      "id": "eval_dashboard",
      "label": "Eval Dashboard",
      "kind": "html",
      "command": "bash lattice/kernel/delivery/eval-dashboard.sh"
    }
  ]
JSON
}

render_gates() {
  local count i first=true name run skip_when
  count="$(yq -r '(.pipeline.steps // []) | length' "$MANIFEST" 2>/dev/null || echo 0)"
  [[ "$count" =~ ^[0-9]+$ ]] || count=0

  printf '['
  for i in $(seq 0 $((count - 1))); do
    name="$(yq -r ".pipeline.steps[$i].name // \"\"" "$MANIFEST" 2>/dev/null || true)"
    run="$(yq -r ".pipeline.steps[$i].run // \"\"" "$MANIFEST" 2>/dev/null || true)"
    skip_when="$(yq -r ".pipeline.steps[$i].skip_when // \"never\"" "$MANIFEST" 2>/dev/null || true)"
    [[ -n "$name" ]] || continue
    if [[ "$first" == "true" ]]; then
      first=false
    else
      printf ','
    fi
    printf '\n    {'
    printf '"id":"%s",' "$(json_escape "$name")"
    printf '"label":"%s",' "$(json_escape "$name")"
    printf '"command":"%s",' "$(json_escape "$run")"
    printf '"skip_when":"%s"' "$(json_escape "$skip_when")"
    printf '}'
  done
  if [[ "$first" == "false" ]]; then
    printf '\n  '
  fi
  printf ']'
}

project_name="$(manifest_get '.project.name')"
project_language="$(get_language)"
specs_dir="$(manifest_get '.specs.dir')"
default_mode="$(manifest_get '.specs.default_execution_mode')"
eval_sink_dir="$(manifest_get '.eval.sink.dir')"

cat <<JSON
{
  "schema_version": "lattice.capabilities.v1",
  "kind": "lattice-capabilities",
  "runtime": {
    "name": "lattice",
    "version": "$(json_escape "$(kernel_version)")",
    "protocol_version": "1.0"
  },
  "project": {
    "name": "$(json_escape "$project_name")",
    "language": "$(json_escape "$project_language")",
    "root": "$(json_escape "$PROJECT_ROOT")"
  },
  "host": {
    "mode": "lattice",
    "manifest": "lattice/manifest.yaml",
    "specs_dir": "$(json_escape "${specs_dir:-lattice/specs}")",
    "eval_sink_dir": "$(json_escape "${eval_sink_dir:-lattice/state/eval-sink}")"
  },
  "policy": {
    "default_execution_mode": "$(json_escape "${default_mode:-auto}")",
    "allow_execution_mode_override": $(json_bool "$(manifest_get '.specs.allow_execution_mode_override')")
  },
  "layers": {
    "orchestrator": $(json_bool "$(manifest_get '.kernel.layers.orchestrator')"),
    "context": $(json_bool "$(manifest_get '.kernel.layers.context')"),
    "delivery": $(json_bool "$(manifest_get '.kernel.layers.delivery')")
  },
  "stages": $(render_stages),
  "tools": $(render_tools),
  "actions": $(render_actions),
  "gates": $(render_gates),
  "metrics": $(render_metrics),
  "reports": $(render_reports),
  "compatibility": {
    "min_adapter_protocol": "1.0",
    "warnings": []
  }
}
JSON

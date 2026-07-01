#!/usr/bin/env bash
# eval-skills.sh - PrismSpec skill quality checks.
# Runs static skill anatomy checks and lightweight trigger-collision heuristics.
set -euo pipefail

MODE="all"
JSON=false
ROOT=""

usage() {
  cat <<'EOF'
PrismSpec skill eval

Usage:
  bash prismspec/bin/eval-skills.sh [--root=<prismspec-dir>] [--static|--trigger|--all] [--json]

Checks:
  static   Validate skill anatomy and eval fixture shape.
  trigger  Check trigger prompts for duplicate prompts and obvious stage collisions.
  all      Run static and trigger checks.

The trigger check is intentionally conservative. It is not a model-based judge;
it catches packaging regressions and stage-boundary ambiguity that can be found
from skill descriptions and eval prompts.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --root=*) ROOT="${arg#--root=}" ;;
    --static) MODE="static" ;;
    --trigger) MODE="trigger" ;;
    --all) MODE="all" ;;
    --json) JSON=true ;;
    *) echo "Unknown argument: $arg" >&2; usage; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

if [[ ! -d "$ROOT/skills" ]]; then
  echo "PrismSpec skills directory not found: $ROOT/skills" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for eval-skills.sh" >&2
  exit 1
fi

python3 - "$ROOT" "$MODE" "$JSON" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
mode = sys.argv[2]
json_mode = sys.argv[3].lower() == "true"

failures = []
warnings = []
passes = []

def add(kind, msg):
    if kind == "fail":
        failures.append(msg)
    elif kind == "warn":
        warnings.append(msg)
    else:
        passes.append(msg)

def frontmatter(text):
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end == -1:
        return {}
    data = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"')
    return data

def words(text):
    stop = {
        "the", "and", "or", "to", "a", "an", "of", "in", "for", "with",
        "when", "use", "uses", "using", "from", "into", "after", "before",
        "this", "that", "must", "should", "prismspec", "spec", "skill",
        "stage", "workflow", "artifact", "artifacts", "evidence", "run",
        "runs", "write", "writes", "read", "reads", "current"
    }
    tokens = re.findall(r"[a-z0-9][a-z0-9-]{2,}", text.lower())
    return {t for t in tokens if t not in stop}

skills = []
for skill_dir in sorted((root / "skills").glob("*/")):
    skill_file = skill_dir / "SKILL.md"
    eval_file = skill_dir / "evals" / "evals.json"
    if not skill_file.exists():
        add("fail", f"{skill_dir.name}: missing SKILL.md")
        continue
    text = skill_file.read_text(encoding="utf-8")
    meta = frontmatter(text)
    skill_name = meta.get("name", "")
    description = meta.get("description", "")
    skills.append({
        "dir": skill_dir.name,
        "name": skill_name,
        "description": description,
        "text": text,
        "eval_file": eval_file,
        "desc_words": words(skill_dir.name + " " + skill_name + " " + description),
    })

def run_static():
    required_sections = [
        "## Overview",
        "## Common Rationalizations",
        "## Red Flags",
        "## Verification",
    ]
    stage_sections = ["## Inputs", "## Workflow", "## Outputs"]

    for skill in skills:
        name = skill["name"]
        text = skill["text"]
        if name != skill["dir"]:
            add("fail", f"{skill['dir']}: frontmatter name must match directory")
        if "Use when" not in skill["description"]:
            add("fail", f"{skill['dir']}: description must include Use when trigger")
        if len(skill["description"]) > 1024:
            add("fail", f"{skill['dir']}: description exceeds 1024 characters")
        if len(text.splitlines()) > 500:
            add("fail", f"{skill['dir']}: SKILL.md exceeds 500 lines")
        for section in required_sections:
            if section not in text:
                add("fail", f"{skill['dir']}: missing {section}")
        if name != "prismspec-workflow":
            for section in stage_sections:
                if section not in text:
                    add("fail", f"{skill['dir']}: missing {section}")
        if text.count("| Rationalization | Reality |") != 1:
            add("warn", f"{skill['dir']}: rationalization table should be explicit")
        if len(re.findall(r"^- \[ \]", text, re.M)) < 3:
            add("warn", f"{skill['dir']}: verification checklist has fewer than 3 checkboxes")

        eval_file = skill["eval_file"]
        if not eval_file.exists():
            add("fail", f"{skill['dir']}: missing evals/evals.json")
            continue
        try:
            data = json.loads(eval_file.read_text(encoding="utf-8"))
        except Exception as exc:
            add("fail", f"{skill['dir']}: invalid evals JSON: {exc}")
            continue
        if data.get("schema_version") != "prismspec.skill-evals/v1":
            add("fail", f"{skill['dir']}: invalid eval schema_version")
        if data.get("skill") != name:
            add("fail", f"{skill['dir']}: eval skill must match frontmatter name")
        for key in ("should_trigger", "should_not_trigger", "assertions"):
            values = data.get(key)
            if not isinstance(values, list) or len(values) < 3:
                add("fail", f"{skill['dir']}: {key} must have at least 3 entries")
        add("pass", f"{skill['dir']}: static anatomy")

def score(prompt_words, skill):
    return len(prompt_words & skill["desc_words"])

def run_trigger():
    seen_prompts = {}
    for skill in skills:
        eval_file = skill["eval_file"]
        if not eval_file.exists():
            continue
        try:
            data = json.loads(eval_file.read_text(encoding="utf-8"))
        except Exception:
            continue
        for bucket in ("should_trigger", "should_not_trigger"):
            for case in data.get(bucket, []):
                prompt = str(case.get("prompt", "")).strip()
                if not prompt:
                    add("fail", f"{skill['dir']}: empty prompt in {bucket}")
                    continue
                key = re.sub(r"\s+", " ", prompt.lower())
                owner = seen_prompts.get(key)
                if owner and owner != skill["name"]:
                    add("warn", f"duplicate eval prompt across {owner} and {skill['name']}: {prompt}")
                seen_prompts[key] = skill["name"]

                if bucket != "should_trigger":
                    continue
                prompt_words = words(prompt)
                expected = score(prompt_words, skill)
                ranked = sorted(
                    ((score(prompt_words, other), other["name"]) for other in skills if other["name"] != skill["name"]),
                    reverse=True,
                )
                top_score, top_name = ranked[0] if ranked else (0, "")
                if expected == 0:
                    add("warn", f"{skill['name']}: trigger prompt has no lexical overlap with description: {prompt}")
                elif top_score >= expected + 2:
                    add("warn", f"possible trigger collision: {skill['name']} prompt scores closer to {top_name}: {prompt}")
        add("pass", f"{skill['dir']}: trigger fixtures")

if mode in ("all", "static"):
    run_static()
if mode in ("all", "trigger"):
    run_trigger()

result = {
    "status": "fail" if failures else "pass",
    "mode": mode,
    "root": str(root),
    "passes": len(passes),
    "warnings": len(warnings),
    "failures": len(failures),
    "details": {
        "pass": passes,
        "warn": warnings,
        "fail": failures,
    },
}

if json_mode:
    print(json.dumps(result, indent=2, ensure_ascii=False))
else:
    print("PrismSpec Skill Eval")
    print(f"Root: {root}")
    print(f"Mode: {mode}")
    print("")
    for msg in passes:
        print(f"PASS {msg}")
    for msg in warnings:
        print(f"WARN {msg}")
    for msg in failures:
        print(f"FAIL {msg}")
    print("")
    print(f"Summary: PASS={len(passes)} WARN={len(warnings)} FAIL={len(failures)}")

sys.exit(1 if failures else 0)
PY

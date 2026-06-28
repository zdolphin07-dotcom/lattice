# Lattice Agent Guide

## Role

This is the Lattice source repository. It builds a repo-local AI Coding harness that users install into their own projects.

Do not treat this repository as a target project already using Lattice. The installable artifact is `harness-template/` plus `prismspec/`.

## Source Of Truth

| Surface | Canonical Location |
|---------|--------------------|
| Public product docs | `README.md`, `README.en.md` |
| System design docs | `docs/wiki/` |
| PrismSpec workflow | `prismspec/skills/*/SKILL.md` |
| PrismSpec package contract | `prismspec/skillpack.yaml` |
| PrismSpec templates | `prismspec/templates/` |
| Lattice install template | `harness-template/` |
| CI artifact/comment workflow template | `harness-template/.github/workflows/lattice-eval.yml` |
| Delivery pipeline, doctor, gates, and eval summary | `harness-template/lattice/kernel/`, `harness-template/lattice/kernel/delivery/` |
| Context layer | `harness-template/lattice/context/`, `harness-template/lattice/kernel/context/` |
| Target-project Claude import | `harness-template/CLAUDE.lattice.md` |

## Design Rules

- Keep the public product experience Chinese-first; keep English docs as secondary entry points.
- Keep PrismSpec independent. Do not duplicate SDD workflow logic under `harness-template/lattice/skills/`.
- Use directory specs as the only default shape: `lattice/specs/<spec-id>/context.md` + `spec.md`.
- Preserve the install boundary: `kernel/` is framework code; `manifest.yaml`, `context/`, and `specs/` are user assets.
- Do not overwrite project-owned files on upgrade unless the user explicitly asks.
- Prefer small shell contracts for install, routing, and gates. Move only genuinely complex parsing into separate tools.
- Keep docs current with implementation. Do not leave obsolete names, legacy paths, or one-off planning notes in public docs.

## Common Tasks

| Task | Edit |
|------|------|
| User-facing positioning | `README.md`, `README.en.md` |
| Design explanation | `docs/wiki/*.md` |
| Spec workflow behavior | `prismspec/skills/*/SKILL.md`, `prismspec/bin/guide.sh`, `prismspec/bin/lint.sh` |
| Spec/context templates | `prismspec/templates/` |
| Install/init behavior | `install.sh`, `init.sh`, `harness-template/` |
| Pipeline behavior | `harness-template/lattice/kernel/delivery/` |
| Context behavior | `harness-template/lattice/context/`, `harness-template/lattice/kernel/context/` |
| Runnable examples | `examples/` |

## Verification

Run these before reporting completion:

```bash
bash -n init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')
shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')
bash tests/smoke-test.sh
bash examples/go-gin-gorm/try-it.sh
git diff --check
```

For docs-only changes, at least run:

```bash
git diff --check
rg -n "legacy|scaffold|create-item-api\\.md|test-feature\\.md|Eval Evidence" README.md docs prismspec harness-template examples tests -S
```

## Release Hygiene

- Root `README.md` is the Chinese default entry.
- `README.en.md` is the English entry.
- Avoid extra redirect-only README files.
- Keep `CLAUDE.md` small; long-lived repo instructions belong here.
- Keep target-project instructions in `harness-template/CLAUDE.lattice.md`.

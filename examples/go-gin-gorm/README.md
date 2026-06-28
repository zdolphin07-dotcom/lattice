# Go + Gin + GORM Example

A minimal runnable example demonstrating Lattice with a Go API project.

## What's Included

```
examples/go-gin-gorm/
├── manifest.yaml                      # Lattice project config
├── go.mod                             # Go module (mock, not buildable)
├── lattice/
│   ├── specs/
│   │   └── create-item-api/
│   │       ├── context.md             # Per-spec context basis
│   │       └── spec.md                # Sample spec with AC-1 through AC-4
│   └── context/
│       ├── sources.yaml
│       ├── README.md                  # Agent context map
│       └── knowledge/
│           ├── architecture.md
│           └── rules.md               # Sample naming rules
├── internal/
│   ├── model/item.go                  # GORM model (matches spec DDL)
│   └── handler/item.go               # Gin route registration
└── tests/
    └── item_test.go                   # Tests named TestAC1_ through TestAC4_
```

## Try It

```bash
# From the repo root:
cd examples/go-gin-gorm

# Run individual gates:
bash ../../harness-template/lattice/kernel/delivery/gates/spec-lint.sh lattice/specs/create-item-api/spec.md
bash ../../prismspec/bin/lint.sh lattice/specs/create-item-api spec
bash ../../harness-template/lattice/kernel/delivery/gates/ac-coverage.sh lattice/specs/create-item-api/spec.md .
bash ../../harness-template/lattice/kernel/delivery/gates/drift-check.sh lattice/specs/create-item-api/spec.md .
bash ../../harness-template/lattice/kernel/context/backends/knowledge.sh naming
```

## What You'll See

- **spec-lint**: Validates that the spec has all required sections, sequential AC numbers, risk review
- **prismspec-lint**: Validates the PrismSpec artifact contract
- **ac-coverage**: Maps AC-1 through AC-4 to `TestAC1_CreateItem`, `TestAC2_GetItem`, etc. — 100% coverage
- **drift-check**: Compares spec DDL columns against GORM model tags — no drift
- **context knowledge backend**: Searches "naming" → returns `knowledge/rules.md`

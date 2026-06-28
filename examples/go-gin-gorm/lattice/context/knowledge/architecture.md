# Architecture

## Modules

| Module | Responsibility | Notes |
|--------|----------------|-------|
| `internal/handler` | HTTP route registration and request handling | Gin-style route declarations |
| `internal/model` | GORM model definitions | Used by drift checks |
| `tests` | AC-traced tests | Test names map to spec ACs |

# Catalog

The menu `guz-init` offers. Order here is the order shown; the skill numbers the
entries when it prints them.

Free-form entries a user types during `guz-init` are never appended here — they belong
to that repo's `.guz.yaml` alone.

## Architecture patterns

- **Clean Architecture** — dependencies point inward; domain knows nothing about framework, DB, or transport.
- **Hexagonal / Ports & Adapters** — the core talks to interfaces; every I/O concern is an adapter behind a port.
- **DDD tactical patterns** — entities, value objects, aggregates; invariants live in the model, not in services.
- **CQRS** — reads and writes take separate paths, with separate models where it pays off.
- **Event-Driven** — modules publish facts instead of calling each other directly.
- **Repository** — persistence hides behind a collection-like interface; no query builders leaking into use cases.
- **Dependency Injection** — collaborators are injected, never constructed inline or reached for as globals.
- **Feature-Sliced / modular monolith** — the top-level split is by feature, not by technical layer.
- **Layered** — a fixed stack of layers, each calling only the one below it.
- **Service Layer** — use cases sit in an explicit application layer between transport and domain.
- **Anti-Corruption Layer** — external models are translated at the boundary, never used raw inside.
- **Saga** — multi-step distributed work is coordinated with explicit compensation.
- **Outbox** — state change and the event announcing it commit in one transaction.
- **API-first** — the contract (OpenAPI, proto, GraphQL schema) is authored before the handler.
- **Twelve-Factor config** — all config comes from the environment; nothing per-environment is committed.

## Code style

- **No default exports** — named exports only, so renames and greps stay honest.
- **Explicit return types** — public functions declare what they return; no inference across module boundaries.
- **No `any`** — `unknown` plus narrowing, or a real type.
- **Named arguments over positional booleans** — `create({ draft: true })`, never `create(true)`.
- **Errors as values** — expected failures are returned and typed, not thrown; exceptions stay for the unexpected.
- **No barrel re-export chains** — a barrel may re-export its own module, never another barrel.
- **One public export per file** — the file is named after it.
- **Immutability by default** — no mutation of arguments or shared state; build new values.
- **No magic numbers** — every literal with meaning gets a name.
- **Structured logging only** — log objects with fields, never interpolated sentences.
- **No business logic in controllers** — transport handlers parse, delegate, and serialise; nothing else.
- **Money as decimal, never float** — fixed-point or integer minor units throughout; no binary floating point for money.

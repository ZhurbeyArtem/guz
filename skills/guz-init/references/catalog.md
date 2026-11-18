# Catalog

The menu `guz-init` offers. Order here is the order shown; the skill numbers the
entries when it prints them.

Each part is split by target. `guz-init` shows the `Shared` section to every repo, plus
`Backend`, `Frontend`, or both, depending on the `target` the user picked. Entry names
are what `guz-audit` matches on — never rename one, or every contract that already uses
it loses its definition and its grep hook.

Free-form entries a user types during `guz-init` are never appended here — they belong
to that repo's `.guz.yaml` alone.

## Architecture patterns

### Shared

- **API-first** — the contract (OpenAPI, proto, GraphQL schema) is authored before the handler or the client code that uses it.
- **Twelve-Factor config** — all config comes from the environment; nothing per-environment is committed.

### Backend

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

### Frontend

- **Feature-Sliced Design (FSD)** — layers `app → pages → widgets → features → entities → shared`; a layer imports only from layers below it, and slices of one layer never import each other.
- **Bulletproof React** — code lives in `features/<name>`; imports flow `app → features → shared`, and features never import each other — the app composes them.
- **Public API per feature** — every feature or slice exposes one `index` file; code outside it imports only through that file, never a deep path.
- **Atomic Design** — UI is built from atoms, molecules, organisms, templates and pages; each level uses only the levels below it.
- **Container / Presentational** — containers own data and state; presentational components get everything through props and only render.
- **Server state apart from client state** — server data lives in a query cache (TanStack Query, RTK Query, SWR); global stores hold client state only, never copies of server data.
- **API layer** — every network call goes through one typed client layer; components and stores never call `fetch` or `axios` directly.
- **Colocation** — code, styles, tests and state live next to the component that uses them; state stays as local as it can.
- **Design system** — shared UI primitives live in one place and wrap the UI library; features compose them and never restyle their internals.
- **Server-first rendering** — server components or SSR by default; client components only at the leaves that need interactivity.
- **Route-level code splitting** — every route loads lazily; the first screen never ships code only other routes need.
- **Unidirectional data flow** — state flows down and events flow up; no component mutates state it received or writes to a store outside its actions.

## Code style

### Shared

- **No default exports** — named exports only, so renames and greps stay honest. Files a framework requires to default-export are exempt.
- **Explicit return types** — public functions declare what they return; no inference across module boundaries.
- **No `any`** — `unknown` plus narrowing, or a real type.
- **Named arguments over positional booleans** — `create({ draft: true })`, never `create(true)`.
- **Errors as values** — expected failures are returned and typed, not thrown; exceptions stay for the unexpected.
- **No barrel re-export chains** — a barrel may re-export its own module, never another barrel.
- **One public export per file** — the file is named after it.
- **Immutability by default** — no mutation of arguments or shared state; build new values.
- **No magic numbers** — every literal with meaning gets a name.
- **Money as decimal, never float** — fixed-point or integer minor units throughout; no binary floating point for money.

### Backend

- **Structured logging only** — log objects with fields, never interpolated sentences.
- **No business logic in controllers** — transport handlers parse, delegate, and serialise; nothing else.

### Frontend

- **Function components and hooks only** — no class components, except an error boundary where the framework still needs one.
- **Rules of Hooks** — hooks are called unconditionally, at the top level of a component or another hook.
- **Honest effect dependencies** — every effect lists what it reads; `exhaustive-deps` is never silenced.
- **No derived state in effects** — a value computable from props or state is computed during render, not synced through an effect.
- **Stable list keys** — keys come from the item's identity, never from its array index.
- **No business logic in components** — components render and wire events; rules, calculations and data shaping live in hooks, selectors or the model.
- **No direct DOM access** — refs and framework APIs, never `document.querySelector` or hand-mutated nodes.
- **No inline styles** — styling goes through the project's styling system; an inline style carries only values computed at runtime.
- **Design tokens only** — colours, spacing, fonts and breakpoints come from the theme; no hard-coded hex or pixel values.
- **Accessible by default** — semantic elements, labels and alt text; anything clickable is a button or a link.
- **No user-facing string literals** — UI text goes through the i18n layer.
- **No `console` in shipped code** — log through the app's logger, or remove the line.
- **Path aliases over deep relative imports** — `@/features/x`, never `../../../`.
- **Composition over prop drilling** — a prop passes through at most two components that do not use it; deeper needs go through composition or context.
- **Error boundary per route** — every route renders inside an error boundary, so one failure never blanks the whole app.

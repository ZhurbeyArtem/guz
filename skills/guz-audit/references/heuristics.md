# Heuristics

Mechanical hooks for the catalog rules. `guz-module-auditor` runs the hook for a rule
before judging it — a rule that has one is never scored on impression alone.

A hit is not a violation. It is a place to look. Read what the grep found before it
becomes a score, and record the file:line, not the grep.

Written for TypeScript/NestJS. For other stacks translate the intent, not the syntax.
`<m>` is the module path.

## Architecture patterns

- **Clean Architecture** — framework and persistence reaching into the domain:
  `grep -rnE "@nestjs/|typeorm|sequelize|prisma|mongoose" <m> --include=*.entity.ts --include=*.domain.ts`
- **Hexagonal / Ports & Adapters** — no `ports/`/`adapters/` split, or SDK clients
  constructed in core: `grep -rnE "new (Axios|Kafka|Redis|S3|.*Client)\(" <m>`
- **DDD tactical patterns** — anemic models: entities that are pure field bags.
  `grep -rln "class .*Entity" <m>` then check whether any of them hold behaviour.
- **CQRS** — `grep -rnE "CommandHandler|QueryHandler|@CommandHandler|@QueryHandler" <m>`
  and whether read and write paths share one model.
- **Event-Driven** — direct service-to-service calls where an event was promised:
  `grep -rnE "from '\.\./[a-z-]+/(?!.*module)" <m>` against
  `grep -rnE "emit\(|@OnEvent|publish\(" <m>`
- **Repository** — query builders leaking out of the repository:
  `grep -rnE "createQueryBuilder|\.query\(|knex\(|raw\(" <m> --include=*.service.ts`
- **Dependency Injection** — collaborators built by hand:
  `grep -rnE "new [A-Z][a-zA-Z]*(Service|Repository|Client|Gateway)\(" <m>`
- **Feature-Sliced / modular monolith** — top level split by layer instead of feature:
  `ls <m>` showing `services/`, `controllers/`, `models/` as the primary division.
- **Layered** — imports climbing back up the stack:
  `grep -rn "from '.*controller" <m> --include=*.service.ts`
- **Service Layer** — transport reaching straight into persistence:
  `grep -rnE "Repository|DataSource|EntityManager" <m> --include=*.controller.ts --include=*.resolver.ts`
- **Anti-Corruption Layer** — third-party types used raw inside:
  `grep -rnE "from '(@?[a-z0-9-]+/)?(sdk|api|client)" <m> --include=*.service.ts`
- **Outbox** — `grep -rniE "outbox" <m>`; if absent, check whether any handler publishes
  after a commit rather than inside the transaction.
- **API-first** — `find <m> -name '*.graphql' -o -name '*.proto' -o -name 'openapi*'`
  against handlers written before any contract exists.
- **Twelve-Factor config** — env read outside the config layer, or committed env files:
  `grep -rn "process\.env" <m> | grep -v config` and `find . -maxdepth 2 -name '.env.*'`

## Code style

- **No default exports** — `grep -rn "export default" <m>`
- **No `any`** — `grep -rnE ":\s*any\b|<any>|as any|any\[\]" <m>`
- **Named arguments over positional booleans** — `grep -rnE "\((true|false)[,)]" <m>`
- **No barrel re-export chains** — `grep -rn "export \* from" <m> --include=index.ts`,
  then check whether any target is itself a barrel.
- **One public export per file** — `grep -rc "^export " <m> --include=*.ts` and look at
  files above 1 that are not type-only.
- **Immutability by default** — mutation of inputs:
  `grep -rnE "\w+\.(push|pop|splice|sort|reverse)\(" <m>`
- **Structured logging only** — interpolated log lines:
  `grep -rnE "(logger|log)\.(log|info|warn|error)\(\s*[\`'\"]" <m>` plus
  `grep -rn "console\." <m>`
- **No business logic in controllers** — branching in transport:
  `grep -rcE "\bif\b|\bfor\b|\bswitch\b" <m> --include=*.controller.ts --include=*.resolver.ts`
- **Money as decimal, never float** — `grep -rnE "parseFloat|Number\(|toFixed\(|\* 100\b" <m>`,
  then check whether the value is monetary.
- **Explicit return types** — noisy to grep; prefer the project's own lint output if
  `@typescript-eslint/explicit-module-boundary-types` is configured, otherwise sample
  exported functions in the module's public files.
- **No magic numbers** — `grep -rnE "[^a-zA-Z0-9_.]\d{2,}\b" <m> --include=*.ts` is noisy
  by design; only count literals that carry meaning, never array indices or `0`/`1`.

## No mechanical hook

Judgement only, on read code — never score these from a grep:

- **Saga** — whether compensation exists and is correct is not greppable.
- **Errors as values** — `throw` count says nothing about whether the failure was expected.
- **DDD tactical patterns**, beyond the anemic-model check above.

If a rule here scores below 8, the evidence gate still applies: cite the file:line you
read, not the absence of a pattern.

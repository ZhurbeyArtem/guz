# Heuristics

Mechanical hooks for the catalog rules. `guz-module-auditor` runs the hook for a rule
before judging it — a rule that has one is never scored on impression alone.

A hit is not a violation. It is a place to look. Read what the grep found before it
becomes a score, and record the file:line, not the grep.

Backend hooks are written for TypeScript/NestJS, frontend hooks for TypeScript/React.
For other stacks translate the intent, not the syntax. `<m>` is the module path. In a
frontend, every `--include=*.ts` also means `--include=*.tsx`.

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

- **No default exports** — `grep -rn "export default" <m>`, then drop the files a
  framework requires to default-export: Next.js `page`/`layout`/`route` files,
  `React.lazy` targets, Storybook meta.
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

## Frontend architecture patterns

- **Feature-Sliced Design (FSD)** — prefer `npx steiger` output when the repo has it.
  Otherwise list cross-layer imports, then check each against the layer order and
  for a sibling slice of the same layer:
  `grep -rnE "from ['\"](@/|(\.\./)+)(app|pages|widgets|features|entities)/" <m>`
- **Bulletproof React** — one feature importing another, or shared code importing a
  feature: inside `features/<x>`,
  `grep -rnE "from ['\"](@/|(\.\./)+)features/" <m>` and keep hits naming another
  feature; in `components/`, `hooks/`, `lib/`, `utils/`, any hit at all.
- **Public API per feature** — deep imports past a slice's `index`:
  `grep -rnE "from ['\"](@/|(\.\./)+)(features|entities|widgets|pages|views)/[^/'\"]+/" <m>`
- **Atomic Design** — a level importing one above it:
  `grep -rnE "from .*/(molecules|organisms|templates)/" <m>/atoms`, then the same for
  molecules against organisms and templates, and so on up.
- **Container / Presentational** — data access in presentational components:
  `grep -rlnE "useSelector|useDispatch|useQuery|useMutation|fetch\(|axios" <m>`, then
  check which hits sit in components meant to only render.
- **Server state apart from client state** — fetched data stored in a global store:
  `grep -rnE "createAsyncThunk|\.fulfilled" <m>`, plus effects that fetch and then call
  a setter: `grep -rnA6 "useEffect(" <m> | grep -E "fetch\(|axios|api\."`
- **API layer** — network calls outside the API layer:
  `grep -rnE "\bfetch\(|axios(\.(get|post|put|patch|delete|request))?\(" <m>`; a hit
  outside the API directory is a violation.
- **Colocation** — a file in a shared folder (`components/`, `hooks/`, `utils/`) with
  exactly one importer: `grep -rlE "from .*/<name>['\"]" src | wc -l` for each such file.
- **Design system** — the UI library imported straight into features:
  `grep -rnE "from ['\"](@mui/|antd|@chakra-ui/|@mantine/)" <m>` outside the design-system
  directory, and overrides of primitive internals: `grep -rnE "\bsx=\{|styled\(" <m>`
- **Server-first rendering** — `grep -rln "'use client'" <m>`, then check whether each
  file needs state, effects, event handlers or browser APIs at all.
- **Route-level code splitting** — routes imported eagerly: in the router files,
  `grep -rnE "^import .* from .*/(pages|views)/" <m>` against
  `grep -rnE "\blazy\(|dynamic\(" <m>`
- **Unidirectional data flow** — writes to received props or to store state:
  `grep -rnE "props\.\w+(\.\w+)*\s*=[^=]|getState\(\)\.\w+(\.\w+)*\s*=[^=]" <m>`

## Frontend code style

- **Function components and hooks only** —
  `grep -rnE "extends (React\.)?(Pure)?Component\b" <m>`, then drop error boundaries.
- **Rules of Hooks** — prefer the project's lint output if `react-hooks/rules-of-hooks`
  is configured. Otherwise `grep -rnB4 -E "\buse[A-Z]\w*\(" <m> --include=*.tsx` and
  read for hooks after an early `return` or inside a condition or loop.
- **Honest effect dependencies** — `grep -rn "exhaustive-deps" <m>`; every disable
  comment is a hit.
- **No derived state in effects** — `grep -rnA4 "useEffect(" <m>`, then look for bodies
  that only call a setter with values computed from props or state.
- **Stable list keys** — `grep -rnE "key=\{[^}]*\b(i|idx|index)\b" <m>`
- **No business logic in components** — branching in components:
  `grep -rcE "\bif\b|\bfor\b|\bswitch\b|\.reduce\(" <m> --include=*.tsx`, then read the
  heaviest files.
- **No direct DOM access** —
  `grep -rnE "document\.(getElement|querySelector)|\.innerHTML\s*=|\.style\.\w+\s*=" <m>`
- **No inline styles** — `grep -rn "style={{" <m>`, then check whether the value is
  computed at runtime.
- **Design tokens only** — hard-coded values outside the theme files:
  `grep -rnE "#[0-9a-fA-F]{3,8}\b|\b[0-9]+px\b|rgba?\(" <m> --include=*.tsx --include=*.ts --include=*.css --include=*.scss`
- **Accessible by default** — prefer `jsx-a11y` lint output when configured. Otherwise
  `grep -rnE "<(div|span)[^>]*onClick" <m>` and `grep -rn "<img" <m> | grep -v "alt="`
- **No user-facing string literals** — noisy by design:
  `grep -rnE ">[[:space:]]*[A-Z][a-z]+[^<{]*<|(label|title|placeholder|aria-label)=\"[A-Z]" <m> --include=*.tsx`;
  count only text a user reads.
- **No `console` in shipped code** — `grep -rn "console\." <m>`
- **Path aliases over deep relative imports** — `grep -rnE "from ['\"](\.\./){3,}" <m>`
- **Error boundary per route** — `grep -rnE "ErrorBoundary|errorElement" <m>` plus
  `find <m> -name 'error.tsx'`, against the list of routes.

## No mechanical hook

Judgement only, on read code — never score these from a grep:

- **Saga** — whether compensation exists and is correct is not greppable.
- **Errors as values** — `throw` count says nothing about whether the failure was expected.
- **DDD tactical patterns**, beyond the anemic-model check above.
- **Composition over prop drilling** — following one prop through the tree means
  reading the components it passes through.

If a rule here scores below 8, the evidence gate still applies: cite the file:line you
read, not the absence of a pattern.

# Corrections

Every time Artem corrects how Claude wrote code in any repo, the correction lands here. On request the open
entries are summed up, and the ones that hold become defaults in this plugin. That is how the contract `guz-init`
writes, and the code written under it, get better over time.

## What goes in

A correction of how code is written: structure, folder layout, naming, tests, error handling, style, process. Not a
bug report, not a product decision that only makes sense in one repo, and not a rule the repo's `.guz.yaml`
already held and Claude simply broke (that is an audit finding, not a new rule).

## Entry format

Newest at the bottom. One entry per correction; a repeat of an earlier one adds a line to that entry's `Seen`
instead of a new entry, since the repeat count is what the summary weighs.

```
## <YYYY-MM-DD> — <short rule>

- **Seen:** <repo> <YYYY-MM-DD> (<commit or file>)
- **Claude wrote:** what was there before the correction
- **Artem wants:** the correction, in his terms
- **Rule:** the general form, one sentence a catalog entry could carry
- **Lands in:** catalog.md section, a guz-audit heuristic, a guz-init default, or a skill text
- **Status:** open | promoted (<commit>) | dropped (<why>)
```

## Summing up

Only when Artem asks. Group the open entries, rank them by how many times and in how many repos each was seen,
and propose for each one: promote (and where it lands), merge into an existing catalog entry, or drop. Nothing
moves into `skills/` before he agrees; once it does, the entry's status points at the commit that moved it.

This is the route decision 11 left open: free-form rules still never leak into the catalog from inside another
repo. They reach it only through this file, reviewed here.

---

## 2026-11-05 — Specs live in a tests/ folder inside their module

- **Seen:** analyzer 2026-11-05 (3cc2dcf)
- **Claude wrote:** each spec beside the file it tests (`src/replay/replay.service.spec.ts`), helper specs inside
  `helpers/`, e2e specs in the root `test/` folder
- **Artem wants:** every test of a module in a separate `tests/` folder inside that module
- **Rule:** unit, integration and e2e specs live in `<module>/tests/`; the root `test/` keeps only the shared
  harness (env, global setup, fixtures helpers, jest config)
- **Lands in:** catalog.md → Code style; guz-audit heuristic: a `*spec.ts` outside a `tests/` directory
- **Status:** open

## 2026-11-05 — Await into a named const before using the result

- **Seen:** analyzer 2026-11-05 (e36af66)
- **Claude wrote:** `for (const row of await this.repository.findByExternalRefs(...)) { ... }`, and the same habit as
  `(await f()).x`, `list.push(await f())` and `g(await f())`
- **Artem wants:** first a const that fetches the data, then the code that uses it
- **Rule:** every awaited result goes into a named const before anything iterates, reads or passes it on;
  `expect(await f())` in a test is fine
- **Lands in:** catalog.md → Code style; guz-audit heuristic: `of await `, `(await ` followed by `.` or `?.`,
  `(await ` as a call argument other than `expect(`
- **Status:** open

## 2026-11-05 — Blank line before and after every if and for

- **Seen:** analyzer 2026-11-05 (828035b)
- **Claude wrote:** `if` and `for` blocks glued to the statements around them
- **Artem wants:** one empty line before and after every `if` and `for`, so the code reads easier
- **Rule:** one blank line around each `if` and `for` statement, except where it opens or closes its block
- **Lands in:** catalog.md → Code style, shipped with the eslint snippet
  (`padding-line-between-statements`: `prev: '*', next: ['if', 'for']` and the reverse) so it is enforced, not audited
- **Status:** open

## 2026-11-05 — try/catch in every repository method

- **Seen:** analyzer 2026-11-05 (a510f56)
- **Claude wrote:** repository methods with no try/catch, so a driver error reached the global filter as a bare
  INTERNAL; only the few methods mapping a duplicate or a missing parent had one
- **Artem wants:** a try/catch on every repository method that queries the database
- **Rule:** each public repository method catches, lets its own domain error through, and rethrows anything else as
  one catalogue code (`DATABASE_ERROR`) naming `<Class>.<method>` with the driver error as `cause`; the 5xx is
  logged with that cause. A method that returns a query promise must `return await` it, or the catch never runs.
  A method that runs caller code (a callback) passes the caller's errors through unchanged
- **Lands in:** catalog.md → Code style; guz-audit heuristic: a public method in `*.repository.ts` whose body is
  not one try statement; eslint `@typescript-eslint/return-await` (in strictTypeChecked) guards the `return await`
- **Status:** open

## 2026-11-05 — async on every method that returns a Promise

- **Seen:** analyzer 2026-11-05 (6eb16d9)
- **Claude wrote:** `create(input): Promise<SourceRow> { if (blank) throw ...; return this.repository.insert(input); }`
  without `async`, so the validation error was thrown synchronously instead of rejecting; tests missed it because
  their `errorOf` helper caught both
- **Artem wants:** such a method marked `async`
- **Rule:** every method or function that returns a Promise is `async`; a test of a rejection awaits
  `expect(promise).rejects` so a synchronous throw fails it
- **Lands in:** catalog.md → Code style with the eslint snippet
  (`@typescript-eslint/promise-function-async`, `checkArrowFunctions: false`), enforced rather than audited
- **Status:** open

## 2026-11-05 — A loop iterates a named const; no multi-line callback inside an argument list

- **Seen:** analyzer 2026-11-05 (5099722)
- **Seen:** analyzer 2026-11-05 (d51982d): the same rule applied to calls in a loop header, which the first pass missed
- **Claude wrote:** `for await (const page of this.pages(options, (after) => { ...25 lines building a query... })) {`
- **Artem wants:** no arrow function inside the arguments; first get the pages, then walk them
- **Rule:** the call that produces what a loop walks goes into a const above the loop; a callback longer than one
  line gets a name (a private method, or a const) instead of sitting inline in an argument list. One-line
  accessors such as `(row) => row.id` stay inline. Related to the await-into-a-const entry above
- **Lands in:** catalog.md → Code style; guz-audit heuristic: `for (` or `for await (` whose header contains
  `=>` or `function`, and an argument list holding an arrow whose body spans more than one line
- **Status:** open

## 2026-11-05 — Split independent work across parallel subagents, each in its own worktree

- **Seen:** analyzer 2026-11-05 (process, no commit)
- **Claude wrote:** Phase 3 work done inline in the main session, one piece at a time, with no superpowers skills loaded and no UI design skill for UI work
- **Artem wants:** use superpowers and ui-ux-pro-max where they fit, and do the work through subagents; when five agents can safely run at once, run five, and run more or fewer when that is the safe number
- **Rule:** split work into genuinely independent parts and dispatch them to subagents in parallel, each in its own git worktree with its own test database; load the relevant superpowers skills (test-driven-development, verification-before-completion, dispatching-parallel-agents) and ui-ux-pro-max for UI design; the main session coordinates, reviews and integrates
- **Lands in:** a skill text (writing-for-agents or guz-init default for process rules); not a catalog.md code-style entry
- **Status:** open

## 2026-11-06 — Check a nullable object with `!x`, not `x === undefined`

- **Seen:** analyzer 2026-11-06 (src/auth/auth.decorators.ts, `if (user === undefined)`)
- **Claude wrote:** explicit comparisons such as `if (user === undefined)` and `if (row === null)` on values that
  can only be an object or nothing
- **Artem wants:** the shorter `if (!user)`
- **Rule:** a value typed object | null | undefined is checked with `!x` / `x`; a nullable string, number or
  boolean keeps the explicit `=== null` / `=== undefined`, because `!x` also treats `''`, `0` and `false` as
  missing. Enforced by `@typescript-eslint/strict-boolean-expressions` with only `allowNullableObject` on
  (scope beyond objects still to confirm with Artem)
- **Lands in:** catalog.md → Code style with the eslint snippet, enforced rather than audited
- **Status:** open

## 2026-11-06 — Every exported interface lives in interface/, one file each

- **Seen:** analyzer 2026-11-06 (src/cli/helpers/prompter.ts `Prompter`, src/cli/create-admin.ts `CreateAdminIo`)
- **Claude wrote:** exported interfaces declared beside the code that uses them (helpers, controllers, repositories,
  CLI scripts), and several related interfaces sharing one file in `interface/`
- **Artem wants:** an interface that a file exports goes into the module's `interface/` folder, in a file of its own
- **Rule:** an exported interface or type alias sits alone in `<module>/interface/<kebab-name>.ts`; a file outside
  `interface/` may declare only unexported ones. The folder half was already in `.guz.yaml` (Module folder layout);
  the one-per-file half is new. Enforceable with eslint `no-restricted-syntax` on
  `ExportNamedDeclaration > TSInterfaceDeclaration` outside `**/interface/**`
- **Lands in:** catalog.md → Code style (folder layout), plus a guz-audit heuristic for files in `interface/` that
  export more than one declaration
- **Status:** open

## 2026-11-06 — A file holds one kind of thing: module, functions and interfaces apart

- **Seen:** analyzer 2026-11-06 (src/cli/create-admin.ts: `CreateAdminModule`, `CreateAdminIo`, `runCreateAdmin` and
  `main` in one file)
- **Claude wrote:** CLI scripts that declare a Nest module, an exported interface, the exported work function and
  `main` side by side in one file
- **Artem wants:** split it: the module in its own file, the functions apart, the interface in `interface/`
- **Rule:** a Nest `@Module` class gets its own `<name>.module.ts`; each other class its own file; exported
  functions go to `helpers/`; an entry-point script keeps only `main` and its self-invocation. Related to the
  one-interface-per-file entry above
- **Lands in:** catalog.md → Code style (folder layout); guz-audit heuristic: a file that declares a `@Module` class
  together with an exported function or another class
- **Status:** open

## 2026-11-09 — Raw SQL used once stays inline, not in a constant

- **Seen:** analyzer 2026-11-09 (src/exceptions/exceptions.repository.ts `const UNION = \`…\``)
- **Claude wrote:** a module-level `const UNION` holding a multi-line SQL union, referenced from a single
  `db.raw(\`(${UNION}) AS u\`)` call
- **Artem wants:** no constant for SQL that is used once; write it inline at the call site
- **Rule:** raw SQL used in one place goes straight into its `db.raw` / `*Raw` call. This applies only to raw SQL:
  other single-use literals still follow "No magic numbers". SQL shared by two or more calls may stay a constant
- **Lands in:** catalog.md → Code style; guz-audit heuristic: a top-level const whose template literal starts with
  SELECT/WITH/INSERT/UPDATE/DELETE and has exactly one reference
- **Status:** open

## 2026-11-09 — A finished module waits for Artem's review before it is committed

- **Seen:** analyzer 2026-11-09 (process; replaces "commit on your own" for module work)
- **Claude wrote:** committed each module as soon as its checks passed, then moved on to the next one
- **Artem wants:** after a module is written, leave it uncommitted and ask him to review the code. Commit only once
  he says it can be committed, and only then go on to the next module
- **Rule:** finishing a module ends with the checks run and a review request, not a commit. The commit waits for an
  explicit OK; the next module starts after that commit. Applies to work integrated from subagents too: their
  changes land in the working tree uncommitted for the same review
- **Lands in:** workflow / process rules (guz skills that write code end their unit of work with a review gate)
- **Status:** promoted (a9a76b4, guz feat/review-gate: opt-in `review_before_commit` option and SessionStart hook)

## 2026-11-09 — HTTP calls go through axios, not fetch

- **Seen:** analyzer 2026-11-09 (src/vakotrade-ledger/vakotrade-ledger.client.ts, src/fireblocks/fireblocks.client.ts,
  src/common/metrics/metrics.client.ts, src/auth/turnstile.verifier.ts)
- **Claude wrote:** outbound HTTP with the global `fetch`, `AbortSignal.timeout` and `response.json()`, and specs that
  mock it with `jest.spyOn(global, 'fetch')`
- **Artem wants:** axios instead of fetch
- **Rule:** backend HTTP clients call axios (the version `margin_trading_service` uses), with `timeout` instead of an
  abort signal; specs mock axios rather than `global.fetch`. The web keeps RTK Query's base query unless asked
- **Lands in:** catalog.md → Code style; guz-audit heuristic: a `fetch(` call or `jest.spyOn(global, 'fetch')` in a
  NestJS repo
- **Status:** open

## 2026-11-10 — A class's helpers are its private methods

- **Seen:** analyzer 2026-11-10 (src/imports/imports.service.ts `walletOf`, `withoutUnmappedTrades`)
- **Claude wrote:** non-exported module-level functions below `ImportsService`, called only from the class, while
  other helpers of the same class (`toEvent`, `parserOf`) were already private methods
- **Artem wants:** those functions as private methods of the class
- **Rule:** a helper that only one class calls is a private method of that class, not a top-level function in its
  file; a function shared beyond the class goes to `helpers/`. A one-line expression is not extracted at all: it
  stays at its call sites, in a named const when it needs a name (see the next entry)
- **Lands in:** catalog.md → Code style; guz-audit heuristic: a non-exported top-level `function` in a file that
  declares a class
- **Status:** open

## 2026-11-10 — A one-line expression stays inline

- **Seen:** analyzer 2026-11-10 (src/lockouts/lockouts.service.ts `private counts(action, status)`)
- **Seen:** analyzer 2026-11-10 (src/reports/reports.repository.ts top-level `monthKey`, `nextMonth` used once and
  `likePattern` used twice: Artem wanted all three inlined, so a one-liner used in two places stays inline too)
- **Seen:** analyzer 2026-11-10 (src/trader-vaults/trader-vaults.service.ts `const SYSTEM_ACTOR = null`, used in
  two places: no constant for a value used in only two places)
- **Claude wrote:** a private method whose body is one boolean expression, called from a single place in `settle`
- **Artem wants:** no private method for it
- **Rule:** a one-line expression or a plain value is written where it is used, even when two call sites repeat it;
  no private method, helper or module-level constant just to name it. A named const inside the function is fine when
  the name helps. Extraction is for logic longer than one line. "No magic numbers" still covers numeric literals
- **Lands in:** catalog.md → Code style; guz-audit heuristic: a private method or top-level function whose body is
  a single return of one expression
- **Status:** open

## 2026-11-10 — Security settings come from the environment

- **Seen:** analyzer 2026-11-10 (src/users/helpers/password.ts `const BCRYPT_ROUNDS = 10`,
  `const UNKNOWN_USER_HASH = '$2b$10$…'`)
- **Claude wrote:** the bcrypt cost and the dummy hash for unknown emails as constants in the helper
- **Artem wants:** both in the `.env`
- **Rule:** a security setting an operator may tune (hash cost, the dummy hash that hides unknown accounts) is read
  from the environment through the config loader, which validates it (here: the hash's cost must equal the rounds),
  never a constant in code
- **Lands in:** catalog.md → Twelve-factor config; guz-audit heuristic: a module-level constant named `*_ROUNDS`,
  `*_COST` or holding a `$2[aby]$` hash
- **Status:** open

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
- **Claude wrote:** `for await (const page of this.pages(options, (after) => { ...25 lines building a query... })) {`
- **Artem wants:** no arrow function inside the arguments; first get the pages, then walk them
- **Rule:** the call that produces what a loop walks goes into a const above the loop; a callback longer than one
  line gets a name (a private method, or a const) instead of sitting inline in an argument list. One-line
  accessors such as `(row) => row.id` stay inline. Related to the await-into-a-const entry above
- **Lands in:** catalog.md → Code style; guz-audit heuristic: `for (` or `for await (` whose header contains
  `=>` or `function`, and an argument list holding an arrow whose body spans more than one line
- **Status:** open

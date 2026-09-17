# guz

A Claude Code plugin that gives a repo an explicit architecture-and-style contract:
which patterns it commits to, which style rules it holds itself to, and how much each
one matters. The contract lives in `.guz.yaml` at the repo root and is checked in.

## Install

```
/plugin marketplace add ZhurbeyArtem/guz
/plugin install guz@guz
```

Or from a local checkout, for development:

```
/plugin marketplace add ~/Desktop/robota/guz
/plugin install guz@guz
```

## Skills

### `/guz:guz-init`

Creates `.guz.yaml`. Detects the repo name, stack and modules, then asks which
architecture patterns and code-style rules apply — pick from the catalog, write your
own, or both — and sorts them into priority buckets.

Refuses to run if `.guz.yaml` already exists. Offers to add an `@.guz.yaml` line to the
repo's `CLAUDE.md`, which is what makes the contract load into every session.

A module is a top-level directory under `src/`, plus any directory nested below one that
holds the stack's module-marker file — `*.module.ts` in NestJS. Nested modules are named
by path, and a parent's perimeter stops where a nested module begins, so no file is
counted twice.

```yaml
# .guz.yaml — architecture & style contract for this repo. Checked in.
repo: example-service
stack: [typescript, nestjs, postgres, redis]
thresholds: { green: 8, yellow: 5 }
overall: null
modules:
  - { name: orders,            score: null }
  - { name: orders/settlement, score: null }
  - { name: billing,           score: null }
patterns:
  - { name: Clean Architecture, priority: 10, score: null }
  - { name: Repository Pattern, priority: 7,  score: null }
style:
  - { name: No default exports,    priority: 10, score: null }
  - { name: Explicit return types, priority: 7,  score: null }
```

### `/guz:guz-audit`

Fills in every `score` and `overall`. One auditor agent per module, in batches of six —
each greps for mechanical hooks before it judges, and none may lower a score without
citing a `file.ts:42`. A rule that cannot apply to a module comes back `n/a`, not 10.

A module's score is the priority-weighted average of its rules; a repo-wide rule score
is the size-weighted average across modules. `overall` stays a judgement, capped by the
worst `priority: 10` rule.

Evidence goes to two places. `docs/guz-audit/YYYY-MM-DD.md` carries the per-rule matrix
and up to three examples per rule — that matrix is what lets `/guz:guz-audit referrals`
re-audit one module with everything nested under it and still recompute the totals.
`.guz.yaml` keeps only numbers.

The complete list goes to `docs/guz-audit/findings/YYYY-MM-DD/<module>.md`, one file per
module, written by that module's auditor and linked from its section in the report.
Findings are grouped by source file rather than by rule, and split into what the auditor
read and confirmed against what its greps merely turned up — so the file reads as a work
queue for whoever fixes it, not a wall of unverified hits.

### `/guz:guz-fix`

Works the queue the audit left behind. Reads the newest `docs/guz-audit/YYYY-MM-DD.md`,
follows the `All findings:` link out of the named module's section — and out of every
module nested under it — then lists the files carrying `Verified` findings. Unverified
hits stay out: clearing them means reading them, which is a second audit.

The unit is a file, not a finding. That is what findings are grouped by file for — two
fixes in one file collide, and the first one moves every line number below it.

Each chosen file goes to two `guz-fixer` agents at once, each in its own git worktree,
both handed a byte-identical brief and neither told the other exists. Each grills its own
plan into a design tree before it writes, fixes test-first where behaviour changes and
leans on the type-checker and the linter where only shape does, and returns its reasoning,
its diff, and the real output of the check it ran.

You pick one. Its diff is applied to the working tree uncommitted, both worktrees are
removed, and the next file starts — files are worked in sequence, never in parallel.

Nothing is committed and `.guz.yaml` is not touched. Re-run `/guz:guz-audit <module>` to
move the scores.

```
/guz:guz-fix orders
```

### `/guz:guz-grill` and `/guz:guz-grill-with-docs`

The interview every block in `context/decisions.md` was settled with, vendored so it
ships with the plugin instead of living on one machine.

`guz-grill` maps a plan as a design tree and works the frontier in rounds: every question
whose prerequisites are already settled, each with a recommended answer, then the next
round once your answers push the frontier outward. `guz-fixer` invokes it against itself —
the `When there is no user` section is what lets an agent answer its own frontier instead
of waiting for a reply that is never coming.

`guz-grill-with-docs` runs the same interview and writes the result down as it goes:
`CONTEXT.md` for the vocabulary, `docs/adr/` for the decisions that were hard to reverse,
surprising, and a real trade-off. User-invoked only — it writes to the repo.

Both are copied from [mattpocock/skills](https://github.com/mattpocock/skills) under MIT.
See [LICENSES.md](LICENSES.md).

## Two numbers, not one

`priority` is declared — how much this repo cares. `score` is measured — how well the
code actually complies. `guz-init` writes `priority` and leaves every `score` as
`null`; nothing here guesses at compliance.

The gap between the two is the deviation the file exists to track. Green/yellow/red is
derived from `score` against `thresholds`, never stored as a field. Full rubric:
`skills/guz-init/references/scoring.md`.

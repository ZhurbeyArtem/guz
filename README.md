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

```yaml
# .guz.yaml — architecture & style contract for this repo. Checked in.
repo: example-service
stack: [typescript, nestjs, postgres, redis]
thresholds: { green: 8, yellow: 5 }
overall: null
modules:
  - { name: orders,  score: null }
  - { name: billing, score: null }
patterns:
  - { name: Clean Architecture, priority: 10, score: null }
  - { name: Repository Pattern, priority: 7,  score: null }
style:
  - { name: No default exports,    priority: 10, score: null }
  - { name: Explicit return types, priority: 7,  score: null }
```

### `/guz:guz-audit`

Fills in every `score` and `overall`. One read-only auditor agent per module, in batches
of six — each greps for mechanical hooks before it judges, and none may lower a score
without citing a `file.ts:42`. A rule that cannot apply to a module comes back `n/a`,
not 10.

A module's score is the priority-weighted average of its rules; a repo-wide rule score
is the size-weighted average across modules. `overall` stays a judgement, capped by the
worst `priority: 10` rule.

Evidence goes to `docs/guz-audit/YYYY-MM-DD.md`, which also carries the per-rule matrix
— that is what lets `/guz:guz-audit orders` re-audit one module and still
recompute the totals. `.guz.yaml` keeps only numbers.

## Two numbers, not one

`priority` is declared — how much this repo cares. `score` is measured — how well the
code actually complies. `guz-init` writes `priority` and leaves every `score` as
`null`; nothing here guesses at compliance.

The gap between the two is the deviation the file exists to track. Green/yellow/red is
derived from `score` against `thresholds`, never stored as a field. Full rubric:
`skills/guz-init/references/scoring.md`.

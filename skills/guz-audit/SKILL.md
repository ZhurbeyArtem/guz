---
name: guz-audit
description: Measure how well a repo complies with the architecture-and-style contract in its .guz.yaml - audits every module against every declared pattern and style rule, fills in every score and overall, and writes a dated evidence report. Use when asked to audit, score, or assess a repo against its guz contract, or to re-audit a single module after changes.
---

# guz-audit

Fill in what `guz-init` left `null`: a `score` for every module, every pattern and every
style rule in `.guz.yaml`, plus `overall`. `.guz.yaml` keeps only numbers.

Evidence goes to two places under `docs/guz-audit/`: a dated report holding the matrix
and up to three examples per rule, and one findings file per module holding everything
that was found. The report answers "why is this red"; the findings are the work queue
for whoever — or whatever — fixes it.

The scale is fixed in `../guz-init/references/scoring.md` — read it before scoring
anything. `priority` is never touched: it is the user's declaration, not a measurement.

Invoked bare, this audits the whole repo. Given a module name — `/guz:guz-audit orders`
— it re-audits that module and every module nested under it, then recomputes everything
derived from them. Whoever just changed `referrals` almost certainly changed
`referrals/rewards` too.

## 1. Refuse if there is no contract

Repo root is `git rev-parse --show-toplevel`, falling back to the current directory.

If `<root>/.guz.yaml` does not exist, stop and tell the user to run `/guz:guz-init`
first. Never audit against an imagined contract.

## 2. Reconcile the module list

Modules are detected exactly as `guz-init` detects them:

- every top-level directory under `src/` — or of the repo, when there is no `src/`;
- plus, recursively and at any depth below those, every directory holding the stack's
  module-marker file. In NestJS that file is `*.module.ts`; in another stack it is
  whatever plays the same role — translate the intent, not the filename.

A module's name is its path from `src/`: `referrals`, `referrals/rewards`,
`referrals/rewards/operations`. Bare directory names are not usable — one repo here has
twelve modules called `operations`.

A parent's perimeter stops where a nested module begins. That directory belongs to its
own module and to no other, or the same file votes twice in every size-weighted number
this skill computes.

The marker is what makes a nested directory a module; a top-level directory is one
whether or not it has a marker. `common/` and `config/` usually hold the code most worth
auditing.

- In `src/` but absent from `.guz.yaml` → add it and audit it like any other.
- In `.guz.yaml` but gone from `src/` → remove the entry.

Show both lists to the user before changing anything. A disappearance is usually a
rename, and only the user knows what it was renamed to.

## 3. Resolve free-form rule definitions

A rule that is not in `../guz-init/references/catalog.md` is defined by the YAML comment
directly above its entry. Read `.guz.yaml` as raw text — a parser drops comments.

If such a rule carries no comment, ask the user for a one-sentence definition and write
it back as a comment above that entry before auditing. Never infer a rule from its name.

## 4. Load the previous matrix

The newest `docs/guz-audit/YYYY-MM-DD.md` by filename holds the per-rule matrix of the
last audit. Per-rule scores live only there; `.guz.yaml` stores averages.

A partial audit inherits every row it does not re-measure, each keeping its own
`audited` date. A full audit reads the file too — a rule that was 8 in a module and is
`n/a` today usually means the code moved, not that the rule stopped applying.

## 5. Audit each module

Dispatch the `guz-module-auditor` agent, one per module, in batches of 6.

Each agent gets: the module name and path, every rule with its `priority` and its
definition, the perimeter, the paths of any modules nested under it, its findings file
path, and the path to the scoring rubric.

Perimeter — everything in the module except tests: `*.spec.ts`, `*.e2e-spec.ts`,
`test/`, `__tests__/` and the equivalents in other stacks, and except the directories of
nested modules. Migrations and generated code are inside the perimeter.

Every agent returns, per rule: a score of 1-10 or `n/a`, up to three `file.ts:42`
examples, and the total count of violations found. Everything else it found goes into
its own findings file. Nothing beyond those three examples passes through this context,
which is the only reason a 120-module repo fits in one run.

## 6. Aggregate

Rules returned as `n/a` drop out of every denominator.

Module score — weighted by declared priority, so a `priority: 5` rule cannot drag as
hard as a non-negotiable one:

```
module.score = round( Σ(rule_score × rule_priority) / Σ(rule_priority) )
```

Repo-wide rule score — weighted by module size in perimeter files, so a clean two-file
module cannot outvote a dirty 294-file one:

```
rule.score = round( Σ(module_rule_score × module_files) / Σ(module_files) )
```

`overall` is a judgement, not an average: a repo can have sound modules and an unsound
arrangement of them. It has one hard ceiling — it may never exceed the lowest score
among rules with `priority: 10`. A repo that breaks a non-negotiable rule is not an 8.

## 7. Write the report

`docs/guz-audit/YYYY-MM-DD.md`, overwritten if today's file already exists. No `latest`
file and no symlink: the newest audit is simply the largest filename. Findings live in a
directory of their own, `docs/guz-audit/findings/`, so they never enter that comparison.

````markdown
# guz audit — example-service — 2026-09-15

Scope: full repo | overall: 6 | green 12 / yellow 18 / red 4

## Matrix

```yaml
orders:
  audited: 2026-09-15
  files: 162
  rules:
    Clean Architecture: 7
    No `any`: 4
    Money as decimal, never float: n/a
```

## orders — 6

**No `any`** — 4 · 37 occurrences
- src/orders/order.service.ts:112
- src/orders/dto/create-order.dto.ts:28

**Money as decimal, never float** — n/a
- No monetary arithmetic in this module; amounts pass through as strings.

**All findings:** [findings/2026-09-15/orders.md](findings/2026-09-15/orders.md)
````

The matrix block is the machine-readable part and the only record of per-rule scores —
keep it parseable. The prose sections are for the human who asks why something is red.

Every module section ends with the link to its findings file, written by that module's
auditor at `docs/guz-audit/findings/YYYY-MM-DD/<module>.md`. The module name is a path,
so nested modules land in nested directories and the link needs no escaping.

After the agents have written, copy forward what today's directory is missing —
`cp -rn <newest previous findings dir>/. docs/guz-audit/findings/YYYY-MM-DD/`. `-n`
leaves every file today's agents just wrote untouched and fills in only the modules
nobody re-audited. Same rule as the matrix: unmeasured is inherited, not dropped.

## 8. Update `.guz.yaml`

Write `score` for every module, pattern and style rule, plus `overall`. Show the diff
before writing.

Touch nothing else. `priority`, `thresholds`, `stack`, `repo` and every comment stay
exactly as they are — the only structural change allowed is the module add/remove agreed
in step 2.

Scores stay `null` where a rule came back `n/a` everywhere, or where a module has no
measurable rule at all. Unmeasured is not the same as bad.

## 9. Report to the user

In chat, in this order: `overall`, the green/yellow/red spread, the five worst modules,
then breaches — every rule where `priority: 10` and `score <= 4`, which is what the file
exists to catch.

Keep it to a screen. The full tables are in the report. Finish with both paths: the
report and today's findings directory.

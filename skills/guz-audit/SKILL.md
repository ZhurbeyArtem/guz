---
name: guz-audit
description: Measure how well a repo complies with the architecture-and-style contract in its .guz.yaml - audits every module against every declared pattern and style rule, fills in every score and overall, and writes a dated evidence report. Use when asked to audit, score, or assess a repo against its guz contract, or to re-audit a single module after changes.
---

# guz-audit

Fill in what `guz-init` left `null`: a `score` for every module, every pattern and every
style rule in `.guz.yaml`, plus `overall`. Evidence goes to a dated report under
`docs/guz-audit/`; `.guz.yaml` keeps only numbers.

The scale is fixed in `../guz-init/references/scoring.md` — read it before scoring
anything. `priority` is never touched: it is the user's declaration, not a measurement.

Invoked bare, this audits the whole repo. Given a module name — `/guz:guz-audit orders`
— it re-audits that module alone and recomputes everything derived from it.

## 1. Refuse if there is no contract

Repo root is `git rev-parse --show-toplevel`, falling back to the current directory.

If `<root>/.guz.yaml` does not exist, stop and tell the user to run `/guz:guz-init`
first. Never audit against an imagined contract.

## 2. Reconcile the module list

Modules are detected exactly as `guz-init` detects them: top-level directories under
`src/`, or top-level directories of the repo when there is no `src/`.

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

Each agent gets: the module path, every rule with its `priority` and its definition, the
perimeter, and the path to the scoring rubric.

Perimeter — everything in the module except tests: `*.spec.ts`, `*.e2e-spec.ts`,
`test/`, `__tests__/` and the equivalents in other stacks. Migrations and generated code
are inside the perimeter.

Every agent returns, per rule: a score of 1-10 or `n/a`, up to three `file.ts:42`
examples, and the total count of violations found.

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
file and no symlink: the newest audit is simply the largest filename.

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
````

The matrix block is the machine-readable part and the only record of per-rule scores —
keep it parseable. The prose sections are for the human who asks why something is red.

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
exists to catch. Finish with the report path.

Keep it to a screen. The full tables are in the report.

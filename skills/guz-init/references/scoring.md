# Scoring

The 1-10 scale used by every `priority` and `score` in `.guz.yaml`. This file is the
only definition — it is deliberately not duplicated into the YAML.

## The scale

| Score | Meaning |
| ----- | ------- |
| 10    | Followed fully. |
| 8-9   | Followed, with minor exceptions. |
| 7     | Mediocre, but within acceptable limits. |
| 5-6   | Noticeable violations. |
| 3-4   | Violated more often than followed. |
| 1-2   | Not followed. |
| null  | Not measured yet. |
| n/a   | Rule does not apply to what is being scored. Audit only; never stored in `.guz.yaml`. |

## Two axes, never one

`priority` — how much this repo cares. Declared by the user during `guz-init`, on the
same scale: 10 is non-negotiable, 7 is important, 5 is nice to have. Never measured,
never recalculated.

`score` — how well the code actually complies. Measured by audit, `null` until then.
Never guessed by `guz-init`.

The gap between them is the point of the file. `priority: 10, score: 4` is a breach of
contract. `priority: 5, score: 4` is a known trade-off nobody needs to act on. A single
blended number would hide both.

`guz-init` only ever writes 10, 7, or 5, because it asks in buckets. The full range is
there for hand-editing afterwards.

## How audit derives a score

`guz-audit` measures one score per rule per module, then rolls those up twice.

A rule that cannot apply to a module — no money handled, no transport layer — is `n/a`,
not 10. "Nothing to violate" is not compliance, and scoring it 10 inflates every average
that contains it. `n/a` drops out of both denominators below.

Module score, weighted by declared priority:

    module.score = round( Σ(rule_score × rule_priority) / Σ(rule_priority) )

Repo-wide rule score, weighted by module size in audited files:

    rule.score = round( Σ(module_rule_score × module_files) / Σ(module_files) )

Priority weighting stops a nice-to-have rule from dragging as hard as a non-negotiable
one. Size weighting stops a clean two-file module from outvoting a dirty 294-file one.

Per-rule scores are never stored in `.guz.yaml` — only the two averages are. They live
in the matrix block of the newest report under `docs/guz-audit/`, which is what lets a
single-module re-audit recompute the repo-wide numbers.

## Colour

Green, yellow and red are derived from `score` against the `thresholds` in
`.guz.yaml` — by default `green: 8, yellow: 5`:

- `score >= 8` → green
- `5 <= score <= 7` → yellow
- `score <= 4` → red
- `score: null` → no colour; unmeasured is not the same as bad

The thresholds live in each repo's `.guz.yaml` because "good enough" is a per-repo
call. The scale above does not — what a 7 means is fixed everywhere.

There is no `status` field in `.guz.yaml`. Storing the colour alongside the score would
let the two disagree the first time someone edits the file by hand.

## `overall`

One 1-10 score for the architecture as a whole, on the same scale. Written by audit,
`null` until then. It is a judgement, not an average of `modules` — a repo can have
sound modules and an unsound arrangement of them.

One hard ceiling: `overall` may never exceed the lowest score among rules with
`priority: 10`. A repo that breaks a rule it declared non-negotiable is not an 8,
however sound everything else looks.

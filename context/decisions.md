# Decisions

## 2026-09-12 — initial design of `guz` and `guz-init`

Design settled in one session before any code was written. Recorded because most of
these decisions look arbitrary from the outside, and the rejected options are the
part that gets re-proposed later.

| # | Decision | Why | Rejected |
| - | -------- | --- | -------- |
| 1 | `guz` is standalone and knowingly overlaps `architecture-first`'s `.arch-profile.yaml` on repo/stack/modules. | Duplicating four YAML keys is cheaper than coupling to another author's release cycle. | Extending or forking `architecture-first`; narrowing `guz` to only the pattern contract. |
| 2 | `guz-init` declares intent and never measures compliance. Every `score` it writes is `null`. | An init that scores a repo it just met produces confident noise. | One skill that both interviews and audits. |
| 3 | Two separate axes: `priority` (declared by the user) and `score` (measured by audit). | A single blended number cannot distinguish "we broke a rule we care about" from "we broke a rule we do not". | One `score` field carrying both meanings. |
| 4 | No `status` field. Green/yellow/red is derived from `score` against `thresholds`. | Stored colour and stored score disagree the first time someone hand-edits the file. | Storing both, as the original sketch had it. |
| 5 | `.guz.yaml` lives at the repo root. | `.claude/` is gitignored in some repos — one of ours ignores it wholesale — and this file must be committed. | `.claude/guz.yaml`. |
| 6 | The skill is `guz-init`, accepting `/guz:guz-init` stutter. | A bare `init` collides across plugins; `ponytail` and `architecture-first` both prefix too. | `/guz:init`. |
| 7 | `modules` = top-level directories under `src/`, with no workspace detection. | Monorepo support is a second system; the monorepo gets hand-edited until it hurts enough to automate. | Reading `workspaces` / `pnpm-workspace.yaml` / `go.work`. |
| 8 | Re-running on a repo that already has `.guz.yaml` refuses outright. | Merge logic is half the skill's complexity and is exactly what silently clobbers audit scores. | Merging; re-interviewing; overwriting. |
| 9 | `priority` is asked in three buckets (10 / 7 / 5), not per item. | Twenty selected items would otherwise mean twenty questions, and nobody finishes question eight. | Asking for a 1-10 number per entry. |
| 10 | The menu is a plain numbered list, not `AskUserQuestion`. | That tool caps at four options per question; the catalog has 27 entries. A text list also lets the user mix catalog picks and free-form in one reply. | Chunking the catalog across several `AskUserQuestion` calls. |
| 11 | Free-form entries go into that repo's `.guz.yaml` only. | Appending to `references/catalog.md` mutates the plugin from inside an unrelated repo, and domain-specific rules are noise elsewhere. | Growing the shared catalog from user input. |
| 12 | The only v1 consumer is an `@.guz.yaml` pointer offered for the repo's `CLAUDE.md`. | Zero code, loads the contract every session. | A `PreToolUse` hook gating edits — a Python project of its own that blocks work when wrong. |
| 13 | The 1-10 rubric lives only in `references/scoring.md`; `thresholds` lives in `.guz.yaml`. | What a 7 means is fixed everywhere; what counts as good enough is a per-repo call. | Duplicating the rubric as YAML comments. |
| 14 | `marketplace.json` ships now, nothing is published. | It is what makes `/plugin marketplace add ~/Desktop/robota/guz` work for dogfooding. | Symlinking the skill into `~/.claude/skills/`. |

Scale anchors, fixed in the same session: 10 followed fully, 8-9 minor exceptions,
7 mediocre but acceptable, 5-6 noticeable violations, 3-4 violated more often than
followed, 1-2 not followed. Colour thresholds follow: green >= 8, yellow 5-7, red <= 4.

Directory was renamed `~/Desktop/robota/arch` → `~/Desktop/robota/guz` before any file
was created. Git is not initialised yet.

Next skill: `guz-audit` — fills `score` per module, per pattern, per style rule, and
`overall`.

## 2026-09-15 — design of `guz-audit`

Settled in one grilling session before any file was written, same as the first block.
Decision 8 is partially reversed here — see 23.

| # | Decision | Why | Rejected |
| - | -------- | --- | -------- |
| 15 | `modules[].score` is the priority-weighted average of that module's per-rule scores, not a standalone judgement. | The `priority` declared during `guz-init` has to bite somewhere, or it only decorates the report. | A holistic per-module judgement; an unweighted mean. |
| 16 | A rule that cannot apply to a module scores `n/a` and leaves both denominators. | Scoring it 10 turns every module green for the rules that never touched it. | Scoring 10; nulling the whole module. |
| 17 | One read-only `guz-module-auditor` per module, dispatched in batches of six; a module name narrows the run. | 108k lines do not fit one context, and per-module agents produce both axes in a single pass. | An agent per rule; no agents; sampling files. |
| 18 | Nothing lowers a score without a `file:line`; mechanical grep hooks run before judgement. | 680 unverifiable numbers are exactly the confident noise decision 2 exists to prevent. | Free judgement; grep-only scoring. |
| 19 | Repo-wide rule scores are weighted by module size in audited files. | Ten clean small modules would otherwise repaint a rule that a third of the codebase breaks. | Unweighted mean; a separate repo-level judgement. |
| 20 | Evidence lives in `docs/guz-audit/YYYY-MM-DD.md` — accumulating, overwritten within a day, no `latest`. | The newest audit is the largest filename: a copy drifts, a symlink breaks in Windows checkouts, and git already keeps history. | Chat only; one overwritten file; `latest.md` or a symlink; an `audited:` field in `.guz.yaml`. |
| 21 | The report carries a machine-readable per-rule matrix, and it is the only store of per-rule scores. | Without it a single-module re-audit cannot recompute the repo-wide numbers, and `.guz.yaml` quietly rots. | Keeping the matrix in `.guz.yaml`; no matrix at all. |
| 22 | Every matrix row carries its own `audited` date; partial audits inherit the rows they did not measure. | After a month of partial runs the totals mix half-year-old and same-day data with no trace of it. | A uniformly fresh-looking matrix. |
| 23 | Audit adds modules that appeared in `src/` and removes ones that vanished — reversing decision 8 for audit only. | Code keeps moving, and a module nobody audits is invisible. `guz-init`'s refusal to re-run still stands. | Freezing the list; refusing to run on drift. |
| 24 | The perimeter is everything but tests; migrations and generated code are audited. | Tests break style rules deliberately and would dominate every score. | Excluding generated code and migrations as well. |
| 25 | Graph rules are judged from the module's own side, with the agent free to grep outside its module. | Building the full import graph up front is a second system; checking one reverse import is two lines. | A pre-built graph passed to every agent; a dedicated whole-graph agent. |
| 26 | Rules outside the catalog are defined by the YAML comment above them; a missing one is asked for and written back. | Those comments are the only definition that exists, and every YAML parser drops them. | Inferring the rule from its name. |
| 27 | `overall` stays a judgement but may never exceed the worst `priority: 10` score. | Composition deserves its own number, and a repo breaking a non-negotiable rule is still not an 8. | A pure formula; an uncapped judgement. |
| 28 | Grep hooks live in `guz-audit/references/heuristics.md`, never in `catalog.md`. | `catalog.md` is a human menu for init; mixing greps into it spoils both roles. | Hooks in `catalog.md`; not writing them down. |
| 29 | `guz-module-auditor` declares no `model:`. | It inherits whatever model the session runs. | Pinning it to a cheaper model. |

`scoring.md` stays under `guz-init/references/` and is read by both skills — moving it
to a shared location would break `guz-init` for the sake of symmetry.

Still nothing enforces the contract: no hook, no CI gate. `@.guz.yaml` in `CLAUDE.md`
and a human reading the report remain the entire consumer side.

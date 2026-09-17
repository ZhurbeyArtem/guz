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

## 2026-09-17 — findings report and nested modules

Settled in one grilling session before any file was written, same as the two blocks
above. Decisions 7, 18 and 20 are each partially reversed here — see 37, 33 and 36.

| # | Decision | Why | Rejected |
| - | -------- | --- | -------- |
| 30 | The audit writes two artifacts: the dated report, unchanged, and one findings file per module holding everything found. | The three-example cap exists to protect the orchestrator's context, not to limit what gets recorded. | Raising the cap inside the report; one combined findings file for the repo. |
| 31 | The auditor agent writes its own findings file; only score, three examples and `count` return through the orchestrator. | Six grep hooks alone return ~1600 hits on a 3,200-file NestJS service. A full payload per module does not survive 120 modules in one run. | The agent returning everything and the skill writing the files. |
| 32 | Findings are grouped by source file, with the rule as a tag on each line. | The reader is a subagent fixing one file; per-rule grouping makes it invert the index or open the same file thirty times. The per-rule view already exists in the report. | Grouping by rule; carrying both views. |
| 33 | Each file splits into `Verified` and `Unverified hits` — partially reversing 18, which admitted no unverified evidence at all. | Reading all 466 `any` hits is a second audit costing more than the first; calling unread greps "problems" is the confident noise 18 exists to prevent. The split is also the fixer's queue boundary. | Verifying everything; publishing raw hits unlabelled; keeping only `count`. |
| 34 | A finding carries its enclosing symbol, not just `file:line`. | The fixer works in batches, and the first fix moves every line number below it. | Line numbers alone; hash IDs per finding. |
| 35 | No per-finding field saying how to check the fix. | It is derivable from the rule name and the rule's `.guz.yaml` comment — a format field for a skill that does not exist yet is decision 8 again. | A `test` / `suite` / `tsc+lint` column written by the auditor. |
| 36 | Findings live at `docs/guz-audit/findings/YYYY-MM-DD/<module>.md`, committed. Partial audits inherit with `cp -rn` after the agents write. | A sibling `*.md` breaks 20's "newest audit is the largest filename"; a separate directory leaves it literally true. Committed, so the report's links resolve for everyone, not just whoever ran it. `-n` leaves today's fresh files alone. | `YYYY-MM-DD.full.md`; a date directory holding both artifacts; gitignoring findings, which was chosen and then reversed once the links were considered. |
| 37 | Modules are detected recursively: every top-level directory under `src/`, plus any directory at any depth holding the stack's module-marker file. Names are paths. Partially reverses 7. | The service measured here has 26 nested modules, two of them two levels deep, whose code was silently scored as their parent's. | Top-level only; a single level of nesting; bare directory names, which collide twelve ways on `operations`. |
| 38 | A parent's perimeter stops where a nested module begins. | 19 weights repo-wide rule scores by module size; a file counted in both parent and child votes twice. | Counting nested code in the parent as well; dropping the parent once it has children. |
| 39 | `/guz:guz-audit referrals` audits that module and its whole subtree. | Whoever changed `referrals` changed `referrals/rewards`. Exact match leaves stale rows looking freshly measured. | Exact match; asking the user each time. |
| 40 | The marker is required only for nesting — a top-level directory is a module with or without one. | `common/` and `config/` carry no marker and usually hold the code most worth auditing. | Requiring a marker everywhere. |
| 41 | `guz-init` gets the same detection. | Step 2 says modules are detected "exactly as `guz-init` detects them". Diverging means every audit opens with "add 26 modules?" and the answer is always yes. | Changing audit only and letting the first audit correct the contract. |

Measured on a 3,200-file NestJS service during the session, and the basis for 31, 33 and 37: 94
top-level directories under `src/`, 90 of them with a `*.module.ts`; 26 nested modules,
24 at depth 3 and 2 at depth 4; and six grep hooks returning 466 `any`, 455 mutations,
603 `console.`, 48 `process.env` and 23 hand-built collaborators.

The consumer these findings are shaped for does not exist yet: a fix skill dispatching
subagents to work the `Verified` queue test-first, with TDD applied where the file
executes code and `tsc`/lint standing in where it does not. Nothing here waits on it —
the findings file reads on its own — but 32, 33 and 34 are its requirements, not the
report's.

Knowingly accepted: on a repo of that size this commits ~120 files per audit
under `docs/`.

## 2026-09-17 — design of `guz-fix`

Settled in one grilling round before any file was written, same as the blocks above.
Nothing here is reversed; 32, 33, 34 and 35 are consumed exactly as they were written.
The previous block ends by predicting this skill — this is it.

| # | Decision | Why | Rejected |
| - | -------- | --- | -------- |
| 42 | The unit of work is one source file with all its `Verified` findings, not one finding. | 32 grouped findings by file for this reader. Two fixes in one file collide, and 34 exists because the first edit moves every line number below it. | One agent per finding; one agent per module. |
| 43 | Only `Verified` findings enter the queue. `Unverified hits` are counted, shown, and never worked. | 33 drew that split as the fixer's queue boundary. Fixing an unread grep hit is the confident noise 2 exists to prevent. | Working both lists; re-verifying the hits first, which is a second audit. |
| 44 | Two agents per file, byte-identical brief, neither told the other exists. | An agent that knows it is being compared differentiates on purpose, and two artificially divergent diffs are worse than two honest ones. | One agent; two agents given deliberately different strategies; more than two. |
| 45 | Each agent gets a real git worktree and returns a real `git diff`, verified by a real command. | A hand-written patch does not apply, and neither variant would have met a compiler. "Variant A is better" would be guessing. | Agents proposing patches as text; agents taking turns in the main working tree. |
| 46 | `guz-fixer` declares no `model:`, same as `guz-module-auditor`. | 29, unchanged: it inherits whatever the session runs. | `subagent_type: fork` — the only documented guarantee of the session's *effort* level, but it carries the whole conversation into every agent, twice per file. |
| 47 | The agents grill themselves: `grilling`'s design-tree method with no user to answer, invoked as a skill when present and restated inline when not. | Identical brief plus identical model yields two near-identical diffs and nothing to choose between. The tree is where the divergence comes from and the first thing the reader compares. | `grill-with-docs`, whose `domain-modeling` half would fill `docs/` with competing ADRs about one-line fixes; hard-depending on `grill-me`, a one-line wrapper that lives in `~/.claude/skills/`, ships with no plugin, and is `disable-model-invocation` anyway. |
| 48 | What verification means is decided per finding by the agent: test-first where the fix changes behaviour, type-checker plus linter plus existing tests where it only changes shape. | This is where 35's "derivable from the rule" gets derived. A rule that only removes an `any` has nothing to test. | A fixed command for every fix; TDD on every finding; the `test:` column 35 rejected. |
| 49 | Files are worked in sequence. Only the pair inside one file runs in parallel. | Two fixes landing in one module collide over shared imports and helpers. | All chosen files at once. |
| 50 | Nothing is committed and `.guz.yaml` is not touched. | This runs in someone else's repository, and a score written before the diff is read is a lie about code that may yet be reverted. | A commit per applied fix; rescoring the module in place. |

The three-skill loop is closed — `guz-init` declares, `guz-audit` measures, `guz-fix`
works the queue — and the enforcement gap 12 and 29 left open is still open. Nothing
re-scores after a fix run; `/guz:guz-audit <module>` remains a thing the user remembers
to type.

Unmeasured, and the first thing a real run should settle: whether two variants per file
are worth double the tokens, or whether the second agent mostly reproduces the first.
Nothing here is designed to find that out.

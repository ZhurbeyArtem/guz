---
name: guz-fix
description: Work the findings queue a guz audit left behind - reads the newest audit report and a module's findings file, lets the user pick which files to fix, then races two isolated agents per file so the user picks the better diff. Use when asked to fix, clear or work through guz findings for a module.
---

# guz-fix

`guz-audit` writes a queue and stops. This works it.

One file at a time. Two agents per file, each in its own worktree, both handed the
identical brief and neither told the other exists — the difference between their diffs
is the whole product. The user picks one; the loser's worktree is thrown away.

Only `Verified` findings are fixed. `Unverified hits` are grep output nobody read, and
that split is the queue boundary the audit drew on purpose.

## 1. Refuse without a contract and an audit

Repo root is `git rev-parse --show-toplevel`, falling back to the current directory.

- No `<root>/.guz.yaml` → stop, tell the user to run `/guz:guz-init`.
- No `<root>/docs/guz-audit/*.md` → stop, tell the user to run `/guz:guz-audit`.

Never fix against an imagined contract, and never against a remembered one.

## 2. Find the newest report

`ls docs/guz-audit/*.md | sort | tail -1`. The newest audit is the largest filename —
there is no `latest` and no symlink. `findings/` is a directory, so it never enters
that sort.

Tell the user which report is in play and how old it is. A month-old report describes a
file that has moved; if the date looks stale, say so before anything is dispatched.

## 3. Resolve the module

`/guz:guz-fix orders` takes `orders` and every module nested under it, matching how
`/guz:guz-audit orders` scopes a re-audit. Whoever is fixing `referrals` is fixing
`referrals/rewards`.

Invoked bare, list the modules from the report's matrix worst score first and ask which
one. Never fix a whole repo in one run.

A module absent from the report was never audited. Stop and say so — there is no queue
to work.

Each module's findings file is the path in the `**All findings:**` link at the end of
its section. Follow the link; do not reconstruct the path. If the link is missing, fall
back to `docs/guz-audit/findings/<report date>/<module>.md`, and say that you did.

## 4. Build the queue

Findings are grouped by source file already. For every `##` file section across the
loaded findings files, take its `### Verified` block. A file whose `Verified` block is
empty is not in the queue, however many unverified hits it carries.

Present a plain numbered list — not `AskUserQuestion`, which caps at four options while
a red module runs to thirty files:

```
 1. src/orders/order.service.ts — 6 verified · No `any`, Money as decimal, Acyclic Module Dependencies
 2. src/orders/dto/create-order.dto.ts — 2 verified · No `any`
```

Below it, one line for what is being left out: how many unverified hits across how many
files, and that clearing them means reading them, which is a second audit.

The user answers with numbers, ranges, or `all`.

## 5. Collect the rule definitions

For every rule named in the chosen files, resolve its definition before dispatching:
from `../guz-init/references/catalog.md` if it is a catalog rule, otherwise from the
YAML comment directly above its entry in `.guz.yaml`. Read `.guz.yaml` as raw text — a
parser drops comments.

A rule with neither is not dispatchable. Ask the user for a one-sentence definition and
write it back as a comment above that entry, the same way `guz-audit` does.

Agents receive definitions. A rule name alone is what the audit refused to work from,
and a fixer guessing at one writes the wrong fix confidently.

## 6. Dispatch two fixers

One file at a time, both agents in a single message so they run concurrently:

- `subagent_type: guz-fixer`, `isolation: "worktree"`
- no `model` — the agent declares none either, so both inherit the session's

Each prompt carries, identically: the repo root, the module name, the target file path,
that file's `Verified` block verbatim, the resolved definition of every rule it cites,
and the path to `.guz.yaml`.

**The brief is byte-identical and neither agent is told the other exists.** An agent
that knows it is being compared differentiates on purpose, and two artificially divergent
diffs are worse than two honest ones.

## 7. Put the two variants to the user

Per variant: the decisions it took and why, its verification command and that command's
result, and its diff. A diff over ~150 lines arrives as `--stat` plus a worktree path;
offer to show it in full rather than dumping it.

Lead with any variant that failed verification, then show both anyway. A failing diff can
still hold the better idea, and that call is the user's.

Also name anything an agent touched beyond the target file. A fix that spread to three
more files is a real answer, but it is not what the queue entry promised.

The user picks one, or neither. Neither means the file goes back in the queue untouched.

## 8. Apply the winner

```
git -C <winning worktree> diff | git -C <root> apply -
```

Applied from the repo root, against the working tree, uncommitted. Then run that
variant's verification command once at the root: a diff that passed inside a worktree can
still fail against uncommitted work sitting outside it.

Then remove both worktrees and their branches — the harness only auto-cleans the one that
came back unchanged:

```
git worktree remove --force <path> && git branch -D <branch>
```

## 9. Next file, then stop

Loop from step 6 until the chosen files are done. Files are worked in sequence, never in
parallel: two fixes landing in one module collide over shared imports and helpers, and
the second agent of a parallel pair would be reading a file the first one already moved.

At the end: the files changed, the files skipped, and the count of unverified hits still
standing. Nothing is committed — this runs in someone else's repository, and the diff is
theirs to read first.

Close with `/guz:guz-audit <module>`. The scores in `.guz.yaml` still describe the code
as it was before any of this.

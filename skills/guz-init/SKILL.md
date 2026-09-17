---
name: guz-init
description: Create .guz.yaml, the architecture-and-style contract for a repo - detects stack and modules, then has the user pick architecture patterns and code-style rules and declare how much each one matters. Use when setting up guz in a repo, or when asked to declare or record the architecture patterns and coding conventions a project must follow.
---

# guz-init

Write `.guz.yaml` at the repo root: the architecture-and-style contract this repo
commits to. It is checked in and reviewed like any other config.

This skill declares intent. It never measures compliance — every `score` it writes is
`null`, and filling those in is the job of a future `guz-audit` skill. Do not
estimate, infer, or "roughly" assign a score here.

## 1. Refuse if the contract already exists

Repo root is `git rev-parse --show-toplevel`, falling back to the current directory.

If `<root>/.guz.yaml` exists: print it and stop. No merging, no overwriting, no
re-interview. Tell the user to edit the file by hand.

## 2. Detect `repo` and `stack`

`repo` — the `origin` remote's repository name, or the root directory name if there is
no remote.

`stack` — read whichever manifests exist: `package.json`, `go.mod`, `pyproject.toml`,
`Cargo.toml`, `composer.json`, `Gemfile`. Emit a flat array covering language,
framework, datastore, queue, transport. Omit what you cannot find; do not name a
datastore no dependency mentions.

## 3. Detect `modules`

Two passes:

- top-level directories under `src/` — or, when there is no `src/`, top-level
  directories of the repo, excluding `node_modules`, `dist`, `build`, `.git`,
  `.claude`, and dotfiles;
- then, recursively and at any depth below those, every directory holding the stack's
  module-marker file. In NestJS that file is `*.module.ts`; in another stack it is
  whatever plays the same role — translate the intent, not the filename.

A module's name is its path from `src/`: `referrals`, `referrals/rewards`,
`referrals/rewards/operations`. Bare directory names are not usable — one repo here has
twelve modules called `operations`.

The marker is what makes a nested directory a module; a top-level directory is one
whether or not it has a marker. `common/` and `config/` usually hold the code most worth
auditing.

Workspace packages are NOT used as modules. A monorepo gets the same treatment as
anything else, and the user fixes the list by hand if it is wrong.

Every module is written with `score: null`.

## 4. Scan for patterns already in use

Cheap heuristics only — directory names, framework decorators, file naming, presence of
config files. A handful of greps, not a survey.

The result has exactly one use: marking entries `[detected]` in the menu in step 5. It
never becomes a score, and it never auto-selects anything on the user's behalf.

## 5. Offer the pattern menu

Read `references/catalog.md`. Print the architecture patterns as a numbered list, one
line each: number, name, gloss, and `[detected]` where step 4 found evidence.

Ask the user to reply with the numbers they want, and say plainly that they can write
their own entries in the same reply.

Do not use `AskUserQuestion` for this — it caps at four options per question and the
catalog is longer than that. A plain numbered list also lets the user mix picks and
free-form text in one answer.

Wait for the answer.

## 6. Offer the style menu

The same, for the code-style section of the catalog. Wait for the answer.

## 7. Assign priorities in buckets

Never ask for a 1-10 number per item — twenty items would mean twenty questions.

Print everything the user selected in step 5 and step 6 as one numbered list, patterns
and style under separate headings, then ask two questions in sequence:

1. "Which of these are non-negotiable?" → those get `priority: 10`
2. From what is left: "Which of these are important?" → those get `priority: 7`

Everything still unpicked gets `priority: 5`.

The buckets map onto the rubric in `references/scoring.md`: 10 is followed fully, 7 is
mediocre but still acceptable, 5 is where noticeable violations begin.

## 8. Write `.guz.yaml`

At the repo root, in English, in this shape:

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

`overall` and every `score` are `null`. `thresholds` belongs in the file because it is
this repo's call on what counts as good enough — unlike the rubric, which is fixed and
lives in the plugin.

There is no `status` field. Green/yellow/red is derived from `score` against
`thresholds`, never stored, so the two can never disagree.

Free-form entries the user typed go into this file only. Never append them back into
`references/catalog.md` — that would mutate the plugin from inside an unrelated repo.

## 9. Offer the CLAUDE.md pointer

Ask whether to append `@.guz.yaml` to the repo's `CLAUDE.md`, or to `AGENTS.md` if that
is the file this repo uses. Ask before touching it, and skip silently if the line is
already there.

This is what makes the contract load into every session. Without it, nothing reads the
file yet.

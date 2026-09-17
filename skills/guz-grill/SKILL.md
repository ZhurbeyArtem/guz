---
name: guz-grill
description: Grill a plan, decision or idea relentlessly, as a design tree worked in rounds. Use when the user wants to stress-test their thinking or uses any 'grill' trigger phrase, and when an agent has to settle its own plan before it writes code.
---

# guz-grill

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.

## When there is no user

An agent running this alone — `guz-fixer` does — has nobody to answer. It answers its own frontier: state the question, state the recommendation, state the reason, move on. Never wait, and never hand back a round of open questions as though someone were going to reply. A question left open is a decision not taken.

Everything above still holds. The tree, the rounds, the frontier, and "finding facts is your job" are unchanged; only the source of the answers moves. Return the tree condensed — the decisions, not the deliberation.

---

_The interview method above is copied from [`grilling`](https://github.com/mattpocock/skills) by Matt Pocock, MIT._

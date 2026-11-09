#!/bin/sh
# An option nobody set reads as off, so an install that skipped the question keeps the old flow.
[ "$CLAUDE_PLUGIN_OPTION_REVIEW_BEFORE_COMMIT" = "true" ] || exit 0

cat <<'EOF'
guz review gate is on (review_before_commit). It overrides any instruction to commit on your own:

- When you finish a module, do not commit it. Run the repo's checks, show their output, ask the user to review the code, and stop.
- Commit only after the user says it can be committed. Then go on to the next module.
- Work from subagents waits for the same review. Bring it into the working tree uncommitted, and do not merge or fast-forward an agent branch before the user's OK.
- Pushing still needs its own approval.
EOF

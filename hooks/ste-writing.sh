#!/bin/sh
# An option nobody set reads as off, so an install that skipped the question keeps the old flow.
[ "$CLAUDE_PLUGIN_OPTION_STE_WRITING" = "true" ] || exit 0

cat <<'EOF'
guz writing rules are on (ste_writing). Apply them to explanations, reports, and questions to the user.
The project's own style governs code, commit messages, docs, and documents for agents.

- English: follow ASD-STE100 at about 80%, without enforcing its approved-word dictionary.
  Limit instructions to 20 words, descriptions to 25 words, and paragraphs to six sentences.
  Give one instruction per sentence. Use active voice, one term per concept, and verbs instead of noun phrases.
- Ukrainian, and any other language as far as its grammar allows: use the adapted ASD-STE100:
  - Give each sentence one idea and at most 20 words. Count a number, code, name, or quotation as one word.
  - Give each paragraph one topic and at most six sentences. Name the topic in its first sentence.
  - Use one term per concept; keep that term instead of varying it for style.
  - Name the actor. Express actions with verbs instead of verbal nouns.
  - Use at most two consecutive nouns in oblique cases and one participial or adverbial participial phrase per sentence.
  - Put conditions first. Put known information before new information.
  - Keep words needed for meaning; use words rather than arrows or symbols as substitutes.
  - Prefer numbers, names, and paths to vague phrases such as "some," "a range," or "in general."
  - Give one action per instruction. Explain a new term when first used.
- "About 80%" means accuracy and natural language take priority. Keep useful connections such as
  "therefore," "but," and "then." Use a diagram or table when it explains more clearly than prose.
- Lead with the result or main point. Use concrete facts and direct statements; keep only information
  needed to understand the result or make a decision. Give each paragraph one purpose.
- In progress updates, state the finding, remaining uncertainty, and next action.
  At completion, state the result, verification, and material limitations.
  Distinguish a prepared diff, local checks, CI, application, and publication.
EOF

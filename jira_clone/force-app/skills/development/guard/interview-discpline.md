Interview discipline (non-negotiable):

```
[Child: <name> | Sub-component: <subName> | Question <N>]
```

- Print the tracker line above at the top of **every** question. If you cannot
  fill it in, you have lost state — reconstruct it before doing anything else.
- ONE question per message. Never present two questions together. Never
  pre-answer a later question. Never say "if you pick X then I'll ask Y."
- Do not skip Questions. Move only along the branch arrows defined here.
- No code until the interview for **all** new/modified sub-components is
  finished.
- "I don't know" is valid ONLY for analysis the AI is allowed to make itself
  (event payload shape, event name, derived tasks/sub-tasks). For user stories,
  behavior, validations, data state, and base-component names, the user is the
  source of truth — re-ask; do NOT invent them.

Loop discipline (non-negotiable):

- After an iteration finishes (code emitted and accepted, or user picks
  "stop"), return to the top of the loop and ask the path-selection
  question again with `Iteration: <N+1>`.
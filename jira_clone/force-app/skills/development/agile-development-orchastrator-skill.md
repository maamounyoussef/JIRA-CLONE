---
name: agile-development-orchastrator
description: >
  Contains the top-level branching for any development request on this
  project. Asks bug vs. task, then for TASK walks the three task options
  (A: create new component, B: create new functionality, C: add an existing
  component to another) and the parent-vs-child sub-question, and finally
  delegates to the matching task-skill in `task-skill/`. Also contains the
  loop-back rule so each iteration runs a single task-skill end-to-end before
  returning to the option menu.
---

# Agile Development Orchestrator

Routes a free-form development request ("I want to work on something",
"add a feature", "build this") into the correct downstream task-skill in
one pass. The orchestrator does not implement any task itself — it only
classifies the request (bug vs. task; create vs. extend; parent vs. child)
and hands off to the matching sub-skill, then loops back when that sub-skill
completes.

---

## Instructions

### Step 1 — Detect the entry point

Run this skill when the user message refers to **development** work on
this project — e.g. "let's do some development", "I want to build
something", "add a feature", "work on a task", "fix a bug". If the message
is purely a question, a code review, a refactor without new behavior, or
work outside `force-app/`, skip — this is not the right skill.

---

### Step 2 — Bug or task

Ask the user via the interactive `AskUserQuestion` tool (NOT plain text):

> *"Is this a bug or a task?"*

- **Bug** → exit this skill; the bug-handling flow is owned elsewhere.
- **Task** → continue to Step 3.

---

### Step 3 — Pick the task option

Ask the user via `AskUserQuestion`:

> *"Which option?
> (A) Create a new component
> (B) Create a new functionality
> (C) Add an existing component to another one"*

---

### Step 4 — Pick parent or child (options A and B only)

For option C, skip this step — C is always a parent-side concern.

For options A and B, ask via `AskUserQuestion`:

> *"Parent (pather) or child?"*

---

### Step 5 — Delegate to the matching task-skill

Run the chosen sub-skill end-to-end before doing anything else. Each
sub-skill owns its own interview, its own checklist, and its own code
emission — this orchestrator does not interleave them.

| Option | Parent / Child | Sub-skill | Mandatory guards |
|---|---|---|---|
| A — create new component | parent | [task-skill/create-new-parent-lwc-component.md](./task-skill/create-new-parent-lwc-component.md) | `lwc-apex-loading` + `lwc-error-handling` |
| A — create new component | child | [task-skill/create-new-child-lwc-component.md](./task-skill/create-new-child-lwc-component.md) | `lwc-error-handling` |
| B — create new functionality | parent | [task-skill/add-interactive-with-data-persistance-functionality-in-pather.md](./task-skill/add-interactive-with-data-persistance-functionality-in-pather.md) | `lwc-apex-loading` + `lwc-error-handling` |
| B — create new functionality | child | [task-skill/add-functionality-in-child-lwc-component.md](./task-skill/add-functionality-in-child-lwc-component.md) | `lwc-error-handling` |
| C — add existing component to another | (parent only) | [task-skill/lwc-parent-event-handler-generator.md](./task-skill/lwc-parent-event-handler-generator.md) | `lwc-apex-loading` + `lwc-error-handling` |

---

### Step 5b — Mandatory LWC guards (run every iteration, without being asked)

Before the chosen sub-skill's code is presented as complete, the relevant
guard skills MUST have been applied. These are not optional and are not
gated on a user question — they run silently as part of every LWC iteration:

- **All LWC (parent AND child)** → **`lwc-error-handling`**
  (`force-app/skills/development/guard/lwc-error-handling-skill.md`).
  Every failure path the sub-skill emits — imperative Apex `.catch`, a
  `@wire` `error` / `success === false` branch, or a synchronous validation
  failure — surfaces through `ShowToastEvent` (`variant: 'error'`), never a
  tracked `errorMessage` inline banner. Applies to new error paths added to
  an existing component too.

- **Pather (parent) LWC only** → **`lwc-apex-loading`**
  (`force-app/skills/development/guard/lwc-apex-loading.md`).
  Every user-initiated imperative Apex call (`apexMethod(...).then(...).catch(...)`)
  or `@wire`-with-function-handler in the parent JS is wired to the
  component's `isLoading` flag, with a `.loading-overlay` spinner stacked
  above modals/peek-panels in the HTML and CSS. Reuse the existing loading
  flag rather than introducing a per-handler boolean.

Each guard's own SKIP conditions still hold (e.g. `lwc-error-handling` does
not flip a component already committed to the legacy inline `errorMessage`
pattern; `lwc-apex-loading` skips private helpers already covered by a public
handler that owns the flag). When you skip a guard, state the skip reason in
the iteration message — silence is not an allowed outcome.

Child task-skills (A-child, B-child) run **only** `lwc-error-handling`;
parents and option C run **both**. Confirm both guards' completion
checklists pass before looping back.

---

### Step 6 — Loop back

When the chosen sub-skill finishes (code emitted and accepted, or the
sub-skill exits cleanly), return to Step 3 and ask the option question
again as the next iteration. Continue until the user says they are done.

---

## Resources

### Iteration tracker

Print this line at the top of every orchestrator-level message so the loop
state is always visible:

```
[Orchestrator | Iteration: <N> | Option: <pending|A|B|C> | Target: <pending|parent|child>]
```

Once a sub-skill is running, switch to that sub-skill's tracker line for
the duration of the iteration, then switch back here when looping.

### Why an orchestrator (instead of jumping straight to a task-skill)

- Most "I want to add X" requests are ambiguous between create-new vs.
  extend-existing, and between parent-side vs. child-side. The two
  classification questions eliminate the ambiguity in two messages.
- Each task-skill is built to be run end-to-end on a single, well-scoped
  request. The orchestrator keeps that contract intact by running them one
  at a time in a loop, rather than trying to drive all of them at once.

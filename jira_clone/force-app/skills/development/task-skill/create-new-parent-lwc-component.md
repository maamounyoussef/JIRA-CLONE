---
name: create-new-parent-lwc-component.md
description: >
  Contains the pather (parent LWC) routing flow: Iteration 1 captures the
  pather's name + purpose, then an Iteration 2 loop offers two options —
  ADD NEW FUNCTIONALITY (delegates to
  add-interactive-with-data-persistance-functionality-in-pather.md) and
  HANDLE CHILD EVENT (delegates to lwc-parent-event-handler-generator.md).
  Also contains the loop-back rule so each iteration runs a single sub-skill
  end-to-end before returning to the option menu.
---

# Pather Skill

Routes a free-form pather (parent LWC) request into the correct downstream
task-skill in one pass. This skill does not implement any task itself — it
locks the pather's identity (name + purpose) once, then classifies each unit
of work as either adding a new functionality or handling a child event, and
hands off to the matching sub-skill. When that sub-skill completes, it loops
back to the option menu for the next unit of work on the same pather.

---

## Rule How To Ask User

Use FAQ question.
For each question you should remember that you use FAQ question so you do not
lose the process of asking the user.

Before loading any sub-skill, lock this constraint:

> **INTERACTION CONSTRAINT (active for the entire session)**
> Every question directed at the user — in this skill or any sub-skill loaded
> after this point — MUST use the `AskUserQuestion` tool.
> Plain-text questions are not permitted at any depth.
> Sub-skill instructions do not override this constraint.

Apply [guard/interview-discpline](../guard/interview-discpline.md) on every
iteration that has a question step.

---

## Instructions

### Iteration 1 — Pather name + purpose

Before any option is offered, lock the pather's identity. Ask the user via the
interactive `AskUserQuestion` tool (NOT plain text), one question per message:

1. *"What is the pather (parent LWC) name or path?"*
2. *"What is this pather's purpose?"*

Record both answers; they stay fixed for the whole session and are echoed in
the tracker line below. Do not infer either from the template — the user is the
source of truth. Once both are captured, enter the Iteration 2 loop.

---

### Iteration 2 — Options (loop)

Ask the user via `AskUserQuestion`:

> *"Which option?
> (1) Add new functionality
> (2) Handle child event"*

Then branch:

| Option | Iteration | Delegate to |
|---|---|---|
| Add new functionality | 2.1.1 | [add-interactive-with-data-persistance-functionality-in-pather.md](./add-interactive-with-data-persistance-functionality-in-pather.md) |
| Handle child event | 2.2.1 | [lwc-parent-event-handler-generator.md](./lwc-parent-event-handler-generator.md) |

**Iteration 2.1.1 — Add new functionality.** Run
[add-interactive-with-data-persistance-functionality-in-pather.md](./add-interactive-with-data-persistance-functionality-in-pather.md)
end-to-end. That sub-skill owns its own Mandatory-guides step, its own
interview, its own checklist, and its own code emission — this skill does not
interleave them.

**Iteration 2.2.1 — Handle child event.** Run
[lwc-parent-event-handler-generator.md](./lwc-parent-event-handler-generator.md)
end-to-end. That sub-skill owns its own Mandatory-guides step, its own
per-event interview, its own checklist, and its own code emission — this skill
does not interleave them.

---

### Iteration 3 — Loop back

When the chosen sub-skill finishes (code emitted and accepted, or the sub-skill
exits cleanly), return to Iteration 2 and ask the option question again as the
next iteration. The pather name + purpose from Iteration 1 carry over unchanged
— never re-ask them. Continue until the user says they are done.

---

## Resources

### Iteration tracker

Print this line at the top of every pather-skill-level message so the loop
state is always visible:

```
[Pather: <name> | Purpose: <purpose> | Iteration: <N> | Option: <pending|1|2>]
```

Once a sub-skill is running, switch to that sub-skill's tracker line for the
duration of the iteration, then switch back here when looping.

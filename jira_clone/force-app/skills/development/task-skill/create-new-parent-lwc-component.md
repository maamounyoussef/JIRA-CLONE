---
name: create-new-parent-lwc-component.md
description: >
  Contains the pather (parent LWC) routing flow for a brand-new pather:
  Iteration 1 captures the pather's name + purpose (this skill's own entry
  point — the pather is created here), then an Iteration 2 loop offers two
  options — ADD NEW FUNCTIONALITY (runs the shared FAQ
  shared/pather-add-functionality-faq.md) and HANDLE CHILD EVENT (runs the
  shared FAQ shared/pather-event-handler-faq.md). It references only shared FAQs
  and guides, never sibling task-skills, and because the pather was just created
  here the "must already exist" entry gate that guards the standalone
  task-skills never applies. Also contains the loop-back rule so each iteration
  runs one FAQ end-to-end before returning to the option menu.
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

The pather was just created in Iteration 1, so the "must already exist" entry
gate that guards the standalone task-skills does **not** apply here — route
straight to the matching shared FAQ. Pass this iteration's number as the FAQ
prefix; the FAQ's first question captures the parent LWC (it does not assume
existence), which is the pather named in Iteration 1.

Then branch:

| Option | Iteration | Run |
|---|---|---|
| Add new functionality | 2.1.1 | [shared/pather-add-functionality-faq.md](./shared/pather-add-functionality-faq.md) |
| Handle child event | 2.2.1 | [shared/pather-event-handler-faq.md](./shared/pather-event-handler-faq.md) |

**Iteration 2.1.1 — Add new functionality.** Run
[shared/pather-add-functionality-faq.md](./shared/pather-add-functionality-faq.md)
end-to-end (one question per message). When it hands the answers back, apply
the standard pather analysis on those named answers — the parent Mandatory
guides (per CLAUDE.md), the behavior-coverage check, the layering map, the
[guide/pather_lwc_state_management_checklist-guide.md](./guide/pather_lwc_state_management_checklist-guide.md),
and the optional [guide/lwc-css-design-guide.md](./guide/lwc-css-design-guide.md) —
then emit the code. This skill never interleaves the FAQ's questions with the
analysis.

**Iteration 2.2.1 — Handle child event.** Identify the child and the events it
dispatches, then run
[shared/pather-event-handler-faq.md](./shared/pather-event-handler-faq.md)
end-to-end for each event (one question per message). When it hands each event's
answers back, apply the standard pather analysis — the parent Mandatory guides
(per CLAUDE.md), handler placement, the
[guide/pather_lwc_state_management_checklist-guide.md](./guide/pather_lwc_state_management_checklist-guide.md),
and the optional [guide/lwc-css-design-guide.md](./guide/lwc-css-design-guide.md) —
then emit the code.

---

### Iteration 3 — Loop back

When the chosen FAQ and its analysis finish (code emitted and accepted, or the
flow exits cleanly), return to Iteration 2 and ask the option question again as
the next iteration. The pather name + purpose from Iteration 1 carry over
unchanged — never re-ask them. Continue until the user says they are done.

---

## Resources

### Iteration tracker

Print this line at the top of every pather-skill-level message so the loop
state is always visible:

```
[Pather: <name> | Purpose: <purpose> | Iteration: <N> | Option: <pending|1|2>]
```

Once a FAQ is running, switch to that FAQ's tracker line for the duration of
the iteration (it carries this iteration's number as its prefix), then switch
back here when looping.

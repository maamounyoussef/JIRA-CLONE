---
name: create-new-parent-lwc-component
description: >
  Routing flow for a brand-new pather (parent LWC). Step 0 settles the parent
  Mandatory guides per their `activation:` contract; Step 1 is this skill's own
  entry point — it locks the pather's name + purpose (the pather is created
  here, so the "must already exist" gate that guards the standalone task-skills
  never applies) and opens a two-option loop: ADD NEW FUNCTIONALITY (runs the
  shared FAQ shared/pather-add-functionality-faq.md) and HANDLE CHILD EVENT
  (runs the shared FAQ shared/pather-event-handler-faq.md). Step 2 runs the
  matching shared FAQ end-to-end and then runs the answer-driven guide; Step 3
  places the emitted code/handlers in the right layer; Step 4 verifies against
  the state-management execution checklist; Step 5 loops back for the next unit
  of work and optionally applies the CSS guide. It references only shared FAQs
  and guides, never sibling task-skills.
---

# Create New Parent LWC Component

Routes a free-form pather (parent LWC) request into the correct downstream work
in one pass. This skill does not implement any task itself — it locks the
pather's identity (name + purpose) once, then classifies each unit of work as
either adding a new functionality or handling a child event, runs the matching
shared FAQ, runs the guide its answers drive, places the code, and verifies it.
When a unit of work completes it loops back to the option menu for the next unit
of work on the same pather.

---

## Rule — How To Ask User

Use FAQ questions. For each question, remember that you are inside an FAQ
iteration so you never lose the process of asking the user.

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

### Step 0 — Mandatory guides

The code this skill generates lives in a **pather (parent)** component. Apply
each guide below per its own `activation:` contract — see CLAUDE.md →
"Mandatory‑guides step" for how required / optional guides are read. Settle
every matching guide before the first interview question.

- **`lwc-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md`)
- **`lwc-apex-call-implementation-guide`** (`force-app/skills/development/task-skill/guide/lwc-apex-call-implementation-guide.md`)
- **`lwc-error-handling-guide`** (`force-app/skills/development/task-skill/guide/lwc-error-handling-guide.md`)
- **`lwc-request-loading-guide`** (`force-app/skills/development/task-skill/guide/lwc-request-loading-guide.md`)
- **`pather_lwc_state_management_checklist-guide`** (`force-app/skills/development/task-skill/guide/pather_lwc_state_management_checklist-guide.md`)
- **`apex-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-path-architecture-guide.md`)
- **`apex-input-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-input-architecture-guide.md`)

The project-wide soft-delete filter (`soql-exclude-deleted`) is **not** listed
here: it fires automatically from CLAUDE.md whenever a new or edited `SELECT`
touches a `RecordStatus__c` object, so no per-skill question gates it.

---

### Step 1 — Entry point (lock the pather, then open the option loop)

This is the skill's own entry point: the pather is **created here**, so the
"must already exist" gate that guards the standalone task-skills does **not**
apply. Before any option is offered, lock the pather's identity. Ask the user
via the interactive `AskUserQuestion` tool (NOT plain text), one question per
message:

1. *"What is the pather (parent LWC) name or path?"*
2. *"What is this pather's purpose?"*

Record both answers; they stay fixed for the whole session and are echoed in the
tracker line (see Resources). Do not infer either from the template — the user
is the source of truth.

Once both are captured, open the option loop. Ask the user via
`AskUserQuestion`:

> *"Which option?
> (1) Add new functionality
> (2) Handle child event"*

For **Handle child event**, first identify the child and the events it
dispatches (`onxxx` handlers / `dispatchEvent` calls) and list them back for
confirmation — the per-event loop in Step 2 runs once per event.

Then go to Step 2, passing this step's number as the FAQ prefix; the FAQ's first
question captures the parent LWC (it does not assume existence), which is the
pather named above.

---

### Step 2 — Run the FAQ, then run the guide

Branch on the option chosen in Step 1:

| Option | Prefix | Run the FAQ |
|---|---|---|
| Add new functionality | 1.1 | [shared/pather-add-functionality-faq.md](./shared/pather-add-functionality-faq.md) |
| Handle child event | 1.2 | [shared/pather-event-handler-faq.md](./shared/pather-event-handler-faq.md) |

**Add new functionality.** Run
[shared/pather-add-functionality-faq.md](./shared/pather-add-functionality-faq.md)
end-to-end (one question per message). It returns, by name: the sub-components,
the user stories, the behavior prompt, the validation rules, the data state
(object + field), the reusable base component, and the resolved Apex method with
its cacheability. When it hands the answers back, run the answer-driven guides:
the behavior-coverage check against the user stories, the layering map, and
[guide/lwc-apex-call-implementation-guide.md](./guide/lwc-apex-call-implementation-guide.md)
for the call style. This skill never interleaves the FAQ's questions with the
analysis.

**Handle child event.** For each event identified in Step 1, run
[shared/pather-event-handler-faq.md](./shared/pather-event-handler-faq.md)
end-to-end (one question per message), passing the prefix. It returns, per
event: the **state** (UPDATE / LOAD / SEARCH; array vs. single value), the
resolved **Apex method** with its **cacheability**, the **concurrent-writes**
answer, the **expand-action** answer, and the **load-timing** answer. When it
hands each event's answers back, run
[guide/lwc-apex-call-implementation-guide.md](./guide/lwc-apex-call-implementation-guide.md):
its Step 0 gate uses the method + cacheability to choose imperative-vs-`@wire`
automatically — do not restate that decision here. Follow the guide's
answer-to-action mapping verbatim (the visibility-urgency branch from the
concurrent-writes answer, the `connectedCallback` auto-wire question, the
separate-`wired<State>` rule, and the wire's gating field on expand-driven loads
from the expand-action + load-timing answers).

When the unit of work is decided, run Steps 3–4 for it, then return to Step 1's
option menu (Step 5).

---

### Step 3 — Place the code in the right layer

Place the emitted code in the layer it belongs to: child data surfaces as
derived **getters** (never a parallel tracked copy of child state); each child
event gets exactly one `handle<Child><Event>` handler wired with
`onxxx={handler}`; mutations go through find/update/delete/create mutators that
spread every level on the path to the leaf and use `Id` to find / `_key` to flag
the change; failures raise a `ShowToastEvent`. Keep the parent as the
orchestration layer — it listens, calls Apex, and updates the de-normalised
principal state from the response; it does not optimistically mutate state
before the Apex result lands.

---

### Step 4 — Verify with the execution checklist

Respect the checklist in
[guide/pather_lwc_state_management_checklist-guide.md](./guide/pather_lwc_state_management_checklist-guide.md).
Run it against the emitted code before the unit of work is considered done.

---

### Step 5 — Loop back (and optionally apply `lwc-css-design-guide`)

When the chosen FAQ, its guide, the placement, and the checklist all finish
(code emitted and accepted, or the flow exits cleanly), return to **Step 1's
option menu** and ask the option question again as the next iteration. The
pather name + purpose from Step 1 carry over unchanged — never re-ask them.
Continue until the user says they are done.

After the handlers are emitted and accepted, ASK the user via the interactive
`AskUserQuestion` tool (NOT plain text) whether to also apply the
**`lwc-css-design-guide`** skill
(`force-app/skills/development/task-skill/guide/lwc-css-design-guide.md`) to
style any new parent-side UI that surfaces this work (toasts, error banners,
loading overlays, modals, peek panels, bulk bars). Frame it as a single yes/no
choice ("Apply the project's CSS design system to the new parent-side UI now?"
with options "Yes, apply lwc-css-design-guide" / "No, skip styling").

- Yes → follow `lwc-css-design-guide` end-to-end (Atlassian/Jira palette, type
  scale, spacing, BEM naming, interactive-state recipes, shared patterns).
- No → continue the loop.

Never invent CSS without invoking `lwc-css-design-guide` — it codifies the
project's visual language so new parent-side UI blends with the rest of
`manageBacklog` / `manageWorkflow` without any visual tuning.

---

## Resources

### Iteration tracker

Print this line at the top of every pather-skill-level message so the loop state
is always visible:

```
[Pather: <name> | Purpose: <purpose> | Step: <N> | Option: <pending|1|2>]
```

Once a FAQ is running, switch to that FAQ's tracker line for the duration of the
iteration (it carries this step's number as its prefix), then switch back here
when looping.

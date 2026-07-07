---
name: update-existing-functionality
description: >
  Updates an already-shipped functionality in place. Opens with its own
  Mandatory-guides step, then detects one thing — does the functionality live in
  a **child** (with a pather handling its dispatched event) or **directly in a
  pather**? For the child branch it runs the child extend-in-place interview to
  update the child, records the dispatched event(s), asks whether the pather's
  Apex call must change, and if so runs the pather event-handler interview with
  the child name, the dispatched event(s), the state kind and the expand-action
  answer PRE-FILLED from the child work — only the Apex-method, concurrent-writes
  and load-timing questions are still asked. For the pather branch it runs the
  pather-direct functionality interview. The carry-forward mapping (what is
  pre-filled vs. still asked once the event is known) is the contract this skill
  owns.
---

# Update Existing Functionality

Turns an "update / change the behavior of a functionality we already built"
request into the correct extend-in-place interview, without re-asking anything
the update itself already fixes. An existing functionality sits in one of two
shapes: split across a **child** (UI + draft state + dispatched event) and a
**pather** (event handler + Apex call), or held **directly in a pather**
(interactive UI + Apex call, no child). This skill detects the shape, runs the
matching interview in *modify-in-place* mode, and — when a child change also
forces the pather's Apex call to change — carries the already-known event
answers forward so nothing is asked twice.

---

## Instructions

### Step 0 — Mandatory guides

This skill updates functionality that lives in a **child**, a **pather**, or
both (a child plus its pather handler). Apply each guide below per its own
`activation:` contract — see CLAUDE.md → "Mandatory‑guides step" for how
required / optional guides are read. Each guide's `applies_when` scopes it to the
branch chosen in Step 1: the presentation guides fire for a child update, and the
Apex / pather guides fire once the pather's Apex call comes into scope (Step 2c
or Step 3). Settle every matching guide before the first interview question of
the branch you enter.

- **`lwc-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md`)
- **`pather_lwc_state_management_checklist-guide`** (`force-app/skills/development/task-skill/guide/pather_lwc_state_management_checklist-guide.md`)
- **`lwc-error-handling-guide`** (`force-app/skills/development/task-skill/guide/lwc-error-handling-guide.md`)
- **`lwc-apex-call-implementation-guide`** (`force-app/skills/development/task-skill/guide/lwc-apex-call-implementation-guide.md`)
- **`lwc-request-loading-guide`** (`force-app/skills/development/task-skill/guide/lwc-request-loading-guide.md`)
- **`apex-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-path-architecture-guide.md`)
- **`apex-input-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-input-architecture-guide.md`)

The project-wide soft-delete filter (`soql-exclude-deleted`) is **not** listed
here: it fires automatically from CLAUDE.md whenever a new or edited `SELECT`
touches a `RecordStatus__c` object, so no per-skill question gates it.

Every question in this skill MUST use the interactive `AskUserQuestion` tool, not
plain text, per CLAUDE.md interview discipline.

---

### Step 1 — Detect the interview entry point

This skill applies when the request is to **change the behavior** of a
functionality that already exists (not create a new one, not a template-only
tweak, not a bug fix). Confirm that first; if it is a create / cosmetic / bug
request, skip — see "When to skip".

Then ask the user via `AskUserQuestion`:

> *"Where does the functionality you're updating live?
> (1) In a **child** component — a pather handles its dispatched event.
> (2) **Directly in a pather**."*

- Answer **(1) child** → run **Step 2**.
- Answer **(2) pather** → run **Step 3**.

Ask nothing else here — which component, which stories, and which code all belong
to the branch's own interview. This step only picks the branch.

---

### Step 2 — Child branch

#### Step 2a — Update the child

Run the child extend-in-place interview in
[add-functionality-in-child-lwc-component.md](add-functionality-in-child-lwc-component.md)
(its five-question per-sub-component loop and its Step 4 checklist), in *update*
framing: gather the **changed** user stories / behavior / validations, and
preserve every existing sub-component, getter, handler and dispatched event that
is not being changed (its checklist row 10 enforces this). Its Step 0 guides are
the presentation subset already settled in Step 0 above — do not re-ask them.

When the child edits are accepted, **record the dispatched event(s)** the child
now produces or changed. For each event capture: the **child name**, the **event
name**, the **operation** (Create / Update / Delete / Load / Search), and the
**payload shape** (per that skill's "Event payload shapes" table). These four
facts are the answers carried forward in Step 2c.

#### Step 2b — Does the pather's Apex call change?

Ask the user via `AskUserQuestion`:

> *"Do you need to update the Apex call in the pather that handles this
> event?"* (Yes / No.)

- **No** → the child change is self-contained. Exit this skill.
- **Yes** → run Step 2c.

#### Step 2c — Update the pather, carrying the child's answers forward

Run the pather event-handler flow: its per-event FAQ
[shared/pather-event-handler-faq.md](shared/pather-event-handler-faq.md) followed
by the wire-implementation guide, placement and checklist described in
[lwc-parent-event-handler-generator.md](lwc-parent-event-handler-generator.md).
But **do NOT re-ask what Step 2a already established** — the dispatched event is
known, so pre-fill it. Apply this mapping, then ask only the questions left
un-filled:

| Question in the pather flow | Normally asks | In this update flow |
|---|---|---|
| **Entry detection** (child name + event list) | which child, then "identify every event it dispatches, list them back" | **PRE-FILLED** from 2a — same child, same event(s). State the child + event list back for confirmation only. |
| **FAQ `.1` — State identification** (UPDATE / LOAD / SEARCH; array vs single) | asks the user | **PRE-FILLED** from the event's operation + payload shape recorded in 2a; the operation was fixed by the child interview. Do not ask. |
| **FAQ `.2` — Apex method resolution** | asks the user | **STILL ASK** — the backing controller method + cacheability is pather-side, not known from the child. |
| **FAQ `.3` — Concurrent writes** | asks the user | **STILL ASK** — visibility / urgency is a pather-side decision, not known from the child. |
| **FAQ `.4` — Expand action** | asks the user | **PRE-FILLED** from the event name recorded in 2a — an `<object><nested>expand` Load event ⇒ yes; otherwise no. Do not ask. |
| **FAQ `.5` — Load timing** | asked only when `.4` is an expand | **STILL ASK, but only if** the pre-filled `.4` is an expand action; otherwise record "n/a". |

Exactly three questions survive: **`.2` Apex method resolution**, **`.3`
concurrent writes**, and **`.5` load timing (expand events only)**. Everything the
dispatched event determines — child name, event, state kind, expand-action — is
filled from 2a without asking. Then let the pather flow run its wire-implementation
guide, handler placement, state-management checklist and optional CSS exactly as
written.

---

### Step 3 — Pather-direct branch

The functionality lives directly in the pather (interactive UI + Apex call, no
child dispatching an event). Run
[add-interactive-with-data-persistance-functionality-in-pather.md](add-interactive-with-data-persistance-functionality-in-pather.md)
in *update* framing — gather the **changed** stories / behavior / validations /
data-state / Apex method, and preserve the rest of the parent. Its entry gate
(an existing parent that already uses Apex), its FAQ, its wire-implementation
guide, its checklist and its optional CSS all apply as written; its Step 0 guides
are the Apex / pather set already settled in Step 0 above. This branch asks
nothing extra beyond that interview.

---

### Step 4 — Verify before emitting code

The branch you ran owns the execution checklist that gates its code
(`add-functionality-in-child-lwc-component` Step 4 for the child edits,
`pather_lwc_state_management_checklist-guide` for the pather edits). Walk that
checklist and fix any failing row before presenting code. In addition, for an
update specifically confirm:

- No existing user story, sub-component, getter, handler or dispatched event was
  dropped unless the user explicitly asked to remove it.
- In the child branch, if 2b was **Yes**, the event name/payload the child now
  dispatches matches exactly what the pather handler in 2c reads — the two passes
  agree on the one shared event.

---

## Optional Logic

### The carry-forward contract (the thing this skill protects)

When a child change forces a pather change, the dispatched event is the shared
key between the two passes. Its name, operation and payload shape are fixed the
moment the child interview finishes, so re-asking "which state?", "which event?"
or "was this an expand?" on the pather side is redundant and invites drift
between the two passes. The Step 2c mapping is the contract that prevents it: the
event-derived answers are pre-filled, and only the genuinely pather-side unknowns
(Apex method, concurrent writes, expand load-timing) are asked.

### When to skip

Skip this skill when:

- The work **creates** brand-new functionality rather than updating an existing
  one — use option B in the orchestrator
  (`add-functionality-in-child-lwc-component` for a child,
  `add-interactive-with-data-persistance-functionality-in-pather` for a pather).
- The update is **template-only** (CSS, layout, label text) with no change to
  behavior, validation, dispatched events, or the Apex call — apply the relevant
  guide directly; no interview is warranted.
- The change is a **bug fix** rather than a behavior update — the bug flow is
  owned elsewhere.

### One iteration stays in one branch

The child branch may end after 2a (child-only change) or continue through 2c
(child + pather change). It never falls through to Step 3 — Step 3 is only for
functionality with no child. Pick the branch in Step 1 and stay in it.

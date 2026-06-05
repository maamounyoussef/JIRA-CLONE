---
name: lwc-parent-event-handler-generator
description: >
  Entry point + analysis for wiring a parent LWC to handle `CustomEvent`s
  dispatched by a child. Owns the entry detection (which child + which events)
  and then runs the shared per-event question iteration in
  shared/pather-event-handler-faq.md; it does not contain the interview
  questions itself. Also contains the analysis the FAQ answers feed: the Apex
  call-style decision tables (`@wire` vs imperative, with or without
  `refreshApex`, expand-gated vs `activeObjectId` wires), the output contract
  (one `handle<Child><Event>` per event, derived child props as getters,
  find/update/delete/create mutators with the spread + `_key` pattern,
  `ShowToastEvent` on failure, `onxxx={handler}` wiring), and the optional
  `lwc-css-design-guide` handoff.
---

# LWC Parent Event Handler Generator

Turns a free-form "the child dispatches X, what do I do in the parent?" request
into a disciplined question-by-question interview that produces correct,
state-coherent parent code in one pass — independent of how many events the
child emits. Parents are the orchestration layer: they listen for child events,
choose between `@wire` (with or without `refreshApex`) and imperative Apex, and
update the de-normalised principal state from the response. Skipping the
interview produces parents that optimistically mutate state before the Apex
result lands, store duplicate copies of child data, miss `refreshApex` on
concurrent writes, or wire the load on the wrong gating field (e.g.
`activeObjectId` instead of an expand flag) — all of which surface as silent
data drift the day a second user edits the same record.

---

## Instructions

### Step 0 — Mandatory guides

The handlers this skill generates live in a **pather (parent)** component. Apply
each guide below per its own `activation:` contract — see CLAUDE.md →
"Mandatory‑guides step" for how required / optional guides are read. Settle every
matching guide before the first interview question.

- **`lwc-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md`)
- **`lwc-apex-call-implementation-guide`** (`force-app/skills/development/task-skill/guide/lwc-apex-call-implementation-guide.md`)
- **`lwc-error-handling-guide`** (`force-app/skills/development/task-skill/guide/lwc-error-handling-guide.md`)
- **`lwc-request-loading-guide`** (`force-app/skills/development/task-skill/guide/lwc-request-loading-guide.md`)
- **`pather_lwc_state_management_checklist-guide`** (`force-app/skills/development/task-skill/guide/pather_lwc_state_management_checklist-guide.md`)
- **`apex-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-path-architecture-guide.md`)

The project-wide soft-delete filter (`soql-exclude-deleted`) is **not** listed
here: it fires automatically from CLAUDE.md whenever a new or edited `SELECT`
touches a `RecordStatus__c` object, so no per-skill question gates it.

---

### Step 1 — Detect the interview entry point

Before writing any handler, identify which child + event pair the work targets.
If **any** signal matches, run the per-event loop in Step 2:

| # | Signal | Example |
|---|--------|---------|
| 1 | User names a child and says "handle its events in the parent" | "wire `c-ticket-view` events into `manageBacklog`" |
| 2 | User pastes a `dispatchEvent(new CustomEvent(...))` and asks how to receive it | "the child fires `ticketsummaryupdate` — what does the parent do?" |
| 3 | User pastes an `onxxx={handler}` attribute and asks what `handler` should look like | "what goes inside `handleTicketLinkedToExpand`?" |
| 4 | User mentions concurrent writes, refresh, or "show to other users ASAP" | "two people might edit this — how do I keep the parent in sync?" |
| 5 | User asks whether to use `@wire` or imperative Apex for a given event | "should this be `@wire` or `callApex`?" |

If none match (the change is template-only, or strictly inside the child),
skip — this is not a parent-handler task.

Before any step, ask only:

> *"What is the child component's name or path?"*

After you have the child, identify every event it dispatches (`onxxx` handlers
/ `dispatchEvent` calls). List them back for confirmation, then begin the
per-event loop with the first event.

---

### Step 2 — Run the per-event FAQ, then run the wire-implementation guide

For each event identified in Step 1, run the shared FAQ
[shared/pather-event-handler-faq.md](shared/pather-event-handler-faq.md),
passing this step's number as the FAQ's prefix. It returns these answers, per
event (by name): the **state** the parent works on (UPDATE / LOAD / SEARCH;
array vs. single value), the resolved **Apex method** with its **cacheability**,
the **concurrent-writes** answer, the **expand-action** answer, and the
**load-timing** answer.

Then run the shared step defined in
[guide/lwc-apex-call-implementation-guide.md](guide/lwc-apex-call-implementation-guide.md),
keeping this step's number in the tracker line. The Apex method and its
cacheability are already known (from the FAQ): that guide's Step 0 gate uses it
to choose imperative-vs-`@wire` automatically — do not restate that decision
here. Follow the guide's answer-to-action mapping verbatim — the
visibility-urgency branch (from the concurrent-writes answer), the
`connectedCallback` auto-wire question, and the separate-`wired<State>` rule.
For the wire's gating field on expand-driven loads, apply the wire-input mapping
in Resources from the expand-action + load-timing answers. Do not invent a
fourth option.

When the event is decided, run Steps 3–4 for it, then return here for the next
event until every event is handled.

---

### Step 3 — Place the handlers in the right layer


### Step 4 — Verify with the execution checklist
respect the checklist in : [guide/pather_lwc_state_management_checklist-guide.md](guide/pather_lwc_state_management_checklist-guide.md)

---

### Step 5 — Optionally apply `lwc-css-design-guide`

After the handlers are emitted and accepted, ASK the user via the
interactive `AskUserQuestion` tool (NOT plain text) whether to also apply
the **`lwc-css-design-guide`** skill
(`force-app/skills/development/task-skill/guide/lwc-css-design-guide.md`) to style any
new parent-side UI that surfaces these handlers (toasts, error banners,
loading overlays, modals, peek panels, bulk bars). Frame it as a single
yes/no choice (e.g. "Apply the project's CSS design system to the new
parent-side UI now?" with options "Yes, apply lwc-css-design-guide" / "No, skip
styling").

- Yes → follow `lwc-css-design-guide` end-to-end: produce/update the parent
  `.css` file using the project's Atlassian/Jira palette, type scale,
  spacing, BEM naming, interactive-state recipes, and shared patterns
  (modal, peek panel, error banner, empty state, bulk bar, drag-and-drop).
- No → exit this skill.

Never invent CSS without invoking `lwc-css-design-guide` — it codifies the
project's visual language so new parent-side UI blends with the rest of
`manageBacklog` / `manageWorkflow` without any visual tuning.

---

## Resources

### Reference rewrite

`force-app/main/default/lwc/manageBacklog/` — worked example of this skill
applied to the Manage Backlog screen handling every event dispatched by
`c-ticket-view` (`ticketsummaryupdate`, `ticketstatuschange`,
`ticketdescriptionupdate`, `ticketsearch`, `ticketlinkcreate`,
`ticketlinkedtoexpand`, `closeticketview`). Demonstrates the wired-function
form of Rule 0, the `_linkedToTargetTicketId` expand-gated wire, and the
`_patchTicketEverywhere` / `_deleteTicketsFromSprints` mutators from Rule 5.

### Reference state-update mutators

`force-app/main/default/lwc/manageBacklog/manageBacklog.js` — template for
find/update/delete/create against the de-normalised principal state
(`backlogTickets` + `sprints[].tickets`). Use as the template when adding any
new mutator: spread every level on the path to the leaf (Rule 7) and use
`Id` to find, `_key` to flag the change.

### Apex call-style decision table (the contract this skill protects)

| Concurrent writes? | Visibility urgency | Call style |
|---|---|---|
| No | — | `@wire` (no `refreshApex`) |
| Yes | Very important | `@wire` + `refreshApex` on **every** child request |
| Yes | Important | `@wire` + `refreshApex` only on related actions |
| Yes | Not important | `@wire` (no `refreshApex`) |
| State is "separate" (single value) | — | Imperative Apex, update state in `.then()` |

| Expand-driven load? | Load timing | Wire input |
|---|---|---|
| No | — | `activeObjectId` |
| Yes | On expand | `_expandTargetId` (new state field, set by the expand handler) |
| Yes | On create | `activeObjectId` |

Salesforce LWC reactivity rules these tables encode:
- `@wire(fn, { x: '$_field' })` re-fires whenever `_field` changes — so
  choosing the right gating field is what makes the load fire at the right
  moment.
- `refreshApex(this.wiredResult)` is the **only** correct way to re-pull a
  previously wired result; calling the imperative version pollutes the cache.
- The wired-property form (`@wire(...) prop;`) does not let you update other
  principal state from the response — always use the wired-function form when
  Rule 0 applies.

---

## Optional Logic

### Integration with `lwc-child` and `lwc-architecture` skills

Before generating the parent, confirm the child dispatches its events under the
`lwc-child` contract (lowercase names, correct payload shape per operation).
After generating the parent, run the `lwc-architecture` skill on the chosen
`@AuraEnabled` controller method so the response envelope (`APIResponse`)
matches what Rule 0 reads (`result.data.success`, `result.data.data?.xxx`).

### When to skip

Skip the interview (Step 2) only when:

- The change is **template-only** (CSS, layout, label text) and does not touch
  Apex calls or principal state.
- The parent **already handles** the event correctly and the user only wants a
  cosmetic tweak (rename a getter, adjust a toast message) that does not
  change Apex resolution or the state-update path.
- The work belongs in the **child** (validation, draft state, edit-mode toggle,
  dispatched payload shape) — use the `lwc-child` skill instead.

Do **not** skip on the basis that "we'll just update state optimistically and
trust the Apex call" — that pattern produces silent drift between principal
state and the database, and is the failure mode this skill exists to prevent.

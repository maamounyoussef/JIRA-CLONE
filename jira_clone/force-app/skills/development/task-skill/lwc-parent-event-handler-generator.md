---
name: lwc-parent-event-handler-generator
description: >
  Contains the per-event interview (Steps 0–10, run in the order state
  identification → Apex resolution → concurrent writes → visibility urgency →
  expand-timing) used
  when wiring a parent LWC to handle `CustomEvent`s dispatched by a child.
  Also contains the Apex call-style decision tables (`@wire` vs imperative,
  with or without `refreshApex`, expand-gated vs `activeObjectId` wires), the
  output contract (one `handle<Child><Event>` per event, derived child props
  as getters, find/update/delete/create mutators with the spread + `_key`
  pattern, `ShowToastEvent` on failure, `onxxx={handler}` wiring), and the
  optional `lwc-css-design-guide` handoff.
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

The handlers this skill generates live in a **pather (parent)** component, so
ALL guides below are mandatory on every event handler that emits JS/HTML/CSS.
They run silently — never gated on a user question, and must be settled before
any interview question:

- **`lwc-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md`)
  — required: settle the LWC layering (page vs child, principal state, sidecars,
  `meta.xml` exposure, naming / event conventions) before any interview
  question.
- **`apex-method-resolution-guide`** (`force-app/skills/development/task-skill/guide/apex-method-resolution-guide.md`)
  — required: resolve which Apex method backs each event handler (existing-known,
  existing-find, or create-new), recursively resolving any dependent
  class/method before code is emitted.
- **`lwc-apex-call-implementation-guide`** (`force-app/skills/development/task-skill/guide/lwc-apex-call-implementation-guide.md`)
  — required: decide the call style (`@wire` vs imperative, with or without
  `refreshApex`) from the method's cacheability and the visibility-urgency
  branch.
- **`lwc-error-handling-guide`** (`force-app/skills/development/task-skill/guide/lwc-error-handling-guide.md`)
  — required: every failure path (Apex `.catch`, `@wire` error / `success ===
  false`) surfaces through `ShowToastEvent` (`variant: 'error'`), never a
  tracked inline `errorMessage` banner.
- **`lwc-request-loading-guide`** (`force-app/skills/development/task-skill/guide/lwc-request-loading-guide.md`)
  — required: the `handle<Child><Event>` mutator's imperative Apex call (or its
  `@wire`-with-function-handler, including the expand-gated / `activeObjectId`
  wires this skill chooses between) is wired to the component's `isLoading`
  flag, with a `.loading-overlay` spinner stacked above modals/peek-panels.
  Reuse the existing loading flag; never add a per-handler boolean.
- **`pather_lwc_state_management_checklist-guide`** (`force-app/skills/development/task-skill/guide/pather_lwc_state_management_checklist-guide.md`)
  — required: walk the state-management checklist (Rules 0–7) and fix every
  failing row before emitting code.
- **`apex-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-path-architecture-guide.md`)
  — required: apply it (no user question) whenever a new Apex method is
  implemented for this event handler. It settles WHERE the method lives and HOW
  the layers connect (Controller → APIResponse → Service → DomainCorrectness),
  including the rule that a Service only queries/DMLs its own object and routes
  cross-domain reads through the owning Service (e.g. `TicketService` calls
  `SprintService.findSprintById` instead of querying `Sprint__c` itself). Skip
  only when no new Apex method is implemented.
- **`soql-exclude-deleted-guide`** (`force-app/skills/development/task-skill/guide/soql-exclude-deleted-guide.md`)
  — optional: ask the user whether to apply it, and apply it only on "yes". It
  is relevant **only when an Apex method is created** for this event handler
  (a new `[SELECT ... FROM <Object>__c]` against a custom object that carries a
  `RecordStatus__c` field); it adds the `RecordStatus__c != 'delete'` filter so
  soft‑deleted rows never leak to callers. Skip the question entirely when no
  Apex method is created.

Each guide's own SKIP conditions still hold; when you skip one, state the
reason in the iteration message. Confirm each guide's completion checklist
passes before reporting the handler done.

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

### Step 2 — Run the per-event interview

Apply the **eleven steps**, one question per message, for every dispatched
event, following the branch arrows below. The traversal order is
`0 → 10 → 1 → 2 → 6 → 7 → 8 → 9`: **Apex method resolution (Step 10) runs
before the wire-implementation question (Step 2)** so the call style (`@wire`
vs imperative) and its `refreshApex` follow-ups are only asked once the method
— and its cacheability — is known. Every event must walk the full flow before
code is emitted.

Interview discipline (non-negotiable):

```
[Child: <name> | Event: <eventName> | Step <N>]
```

- Print the tracker line above at the top of **every** question. If you cannot
  fill it in, you have lost state — reconstruct it before doing anything else.
- ONE question per message. Never present two steps together. Never pre-answer
  a later step. Never say "if you pick X then I'll ask Y."
- Do not skip steps. Move only along the branch arrows defined in the flow.
- No code until the interview for the current event is finished (after Step
  10).
- "I don't know" is a valid answer — the AI analyses the available info
  (dispatched event name, RULES, state shape) and makes the best decision, then
  proceeds. Do not stall.
- After finishing one event, return to the top of the loop for the next event.

**Step 0 — State identification.** Ask which state the parent is working on
(UPDATE / LOAD / SEARCH). Check whether it is stored in an **array** or as a
**single (separate)** value.
- *Separate* → imperative Apex call, update state with the response. **→ Step 10.**
- *No specific state* → `@wire` with its own state to remember values if
  needed. **→ Step 10.**
- *Otherwise* → **→ Step 10.**

**Step 10 — Apex method resolution.** Run the shared sub-step defined in
[guide/apex-method-resolution-guide.md](guide/apex-method-resolution-guide.md). Keep
this skill's step prefix (`Step 10`, with sub-questions `Step 10.01` /
`Step 10.02`) in the tracker line, but follow the branches and the Creation
Sub-Loop verbatim from the shared file — do not inline them here. **Resolve the
method first** — including whether it is cacheable (the cacheable sub-question in
the Creation Sub-Loop) — so the wire question in Step 2 is meaningful: a method
that does not exist yet and is created **non-cacheable** is an imperative call,
and the `@wire` / `refreshApex` branches never arise for it.
- If Step 0 was *separate* (single value) → the call is imperative; you now have
  the method. **→ done.**
- Otherwise → **Step 1.**

**Step 1 — Concurrent writes.** *"Can other users or other browser sessions
modify this data while this component is open?"* Yes → Step 2. No → finish.

**Step 2 — Wire implementation (visibility urgency + auto-wire gating).** Run
the shared sub-step defined in
[guide/lwc-apex-call-implementation-guide.md](guide/lwc-apex-call-implementation-guide.md).
The Apex method is already resolved (Step 10), so its `cacheable`. **→ Step 6.**

**Step 6 — Expand action check.** *"Was this dispatch caused by an expand
action?"* (Yes / No / Do your own check from the event name.) Yes → Step 7. No
→ Step 9.

**Step 7 — Load timing.** *"Load on child *creation* or on *expand*?"* Expanded
→ Step 8. Created → Step 9.

**Step 8 — Expand-gated wire.** New state field separate from `activeObjectId`
gates the `@wire`. **→ done.**

**Step 9 — Active-object wire.** `@wire` on `activeObjectId`. **→ done.**

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
form of Rule 0, the `_linkedToTargetTicketId` expand-gated wire from Step 8,
and the `_patchTicketEverywhere` / `_deleteTicketsFromSprints` mutators from
Rule 5.

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

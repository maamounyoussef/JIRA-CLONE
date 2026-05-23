---
name: lwc-parent-event-handler-generator
description: >
  Generate the parent-component logic that handles `CustomEvent`s dispatched
  from a child LWC: choose the right Apex call style (`@wire` vs imperative,
  with or without `refreshApex`), wire it to the correct Apex method, and update
  the de-normalised principal state from the response — never from optimistic
  local values. This is an interview-driven skill: it walks the user one
  question at a time through state identification, concurrency, visibility
  urgency, expand-timing, and Apex resolution before emitting any code.

  TRIGGER (apply silently) when the user is working on a Salesforce LWC parent
  component and ANY of these is true: a request to "add an event handler",
  "handle this event in the parent", "connect child to parent", "listen to this
  event"; the user pastes a child LWC `dispatchEvent` call or an `onxxx`
  attribute and asks how to respond to it in the parent; the user mentions a
  child that "fires" or "dispatches" something the parent must react to; the
  user is wiring an `@wire` / imperative Apex call in direct response to a child
  event.

  SKIP when the work is purely inside the child (use `lwc-child` instead), when
  the parent change is cosmetic (CSS / template-only) and does not touch Apex
  or principal state, or when the parent already handles the event and the user
  only wants a one-line tweak that does not change Apex resolution or state
  update.
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

Apply the **eleven steps (0 → 10)** in order, one question per message, for
every dispatched event. Every event must walk the full flow before code is
emitted.

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
  needed. **→ Step 1.**
- *Otherwise* → continue to Step 1.

**Step 1 — Concurrent writes.** *"Can other users or other browser sessions
modify this data while this component is open?"* Yes → Step 2. No → Step 6.

**Step 2 — Visibility urgency.** *"Do you want this value to be visible to
other users as soon as possible?"*
- *Very important* → Step 3.
- *Important* → Step 4.
- *Not important* → Step 5.

**Step 3.** `@wire` with `refreshApex` on **every** applicable request from the
child. **→ Step 6.**

**Step 4.** `@wire` with `refreshApex` only on actions **related to this data**.
**→ Step 6.**

**Step 5.** `@wire` **without** `refreshApex`. **→ Step 6.**

**Step 6 — Expand action check.** *"Was this dispatch caused by an expand
action?"* (Yes / No / Do your own check from the event name.) Yes → Step 7. No
→ Step 9.

**Step 7 — Load timing.** *"Load on child *creation* or on *expand*?"* Expanded
→ Step 8. Created → Step 9.

**Step 8 — Expand-gated wire.** New state field separate from `activeObjectId`
gates the `@wire`. **→ Step 10.**

**Step 9 — Active-object wire.** `@wire` on `activeObjectId`. **→ Step 10.**

**Step 10 — Apex method resolution.** *"Which Apex method should handle this?
(A) class + method + line, (B) point to a folder/class and AI finds it, (C)
method doesn't exist — create it."*
- *Branch A:* user supplied the line — record `<ApexClass>.<method>` and skip
  verification entirely. **→ Final Output.**
- *Branch B:* search the named location, identify the method, confirm. **→
  Final Output.**
- *Branch C:* run the **Creation Sub-Loop** below.

> *Creation Sub-Loop (Branch C).* Ask **Step 10.01** (*"What should the
> controller do?"*) — then parse the answer for any other class/method it
> references. For each referenced symbol that doesn't exist, recurse: *"You
> mentioned `<Class>.<method>`, which doesn't exist. What should it do?"*
> Continue until no description references an unresolved class/method. Track
> depth in the tracker line (`[... | Step 10.01 | depth 2: FooSvc.bar]`). Then
> ask **Step 10.02** (*"Where should the controller live?"*) for every method
> created during the recursion.

Anti-pattern to detect:

```javascript
// ❌ Optimistic mutation; wired-property form; duplicates child data into
//     parent state; loads on activeObjectId when the user wanted expand-gated.
@wire(loadTicketLinkedTo, { ticketId: '$activeTicketViewId' }) ticketLinkedTo;

handleTicketSummaryUpdate(event) {
    const { ticketId, summary } = event.detail;
    // mutate principal state BEFORE Apex returns
    this._patchTicketEverywhere(ticketId, { Summary__c: summary });
    saveTicketSummary({ ticketId, summary }); // fire-and-forget
}
```

Correct form (per the rules, after the interview):

```javascript
// ✅ Wired-function form, expand-gated where requested, state updated FROM
//    the Apex response (Rule 0), one handler per event (Rule 1).
@track _linkedToTargetTicketId = null;

handleTicketLinkedToExpand(event) {
    this._linkedToTargetTicketId = event.detail.ticketId;
}

@wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' })
wiredTicketLinkedTo(result) {
    if (result.data && result.data.success && this._linkedToTargetTicketId) {
        const linkedTo = result.data.data?.ticketLinkTo || [];
        this._patchTicketEverywhere(this._linkedToTargetTicketId, { linkedTo });
    }
}

handleTicketSummaryUpdate(event) {
    const { ticketId, summary } = event.detail;
    updateTicketSummary({ ticketId, summary })
        .then(res => {
            if (res?.success) {
                this._patchTicketEverywhere(ticketId, { Summary__c: summary });
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Update failed', message: res?.message, variant: 'error'
                }));
            }
        });
}
```

---

### Step 3 — Place the handlers in the right layer

Layering still applies (see `lwc-architecture` and `lwc-child`):

- The **child** dispatches `CustomEvent`s only. It never calls Apex and never
  mutates `@api` state.
- The **parent** orchestrator owns: event handlers (one per event), the
  `@wire`/imperative Apex calls, the `_activeXxxId` data state, the
  find/update/delete/create mutators, and the de-normalised principal state.
- **Derived child props** are getters that read principal state — never a new
  data state duplicated alongside it.
- The `@AuraEnabled` controller and its `Service` belong in the Apex layer; the
  parent never inlines business logic that should live there.

---

### Step 4 — Verify with the execution checklist

Before presenting the generated code, walk the checklist. If any row fails, fix
it before emitting code:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | Is principal state updated from the Apex **response data**, not from optimistic local values? (Rule 0) | Move the `_patchXxx` call inside `.then()` / the wired-function body. |
| 2 | Is `@wire` used in **wired-function form** when it must update principal state? (Rule 0) | Replace `@wire(...) prop;` with `@wire(...) wiredXxx(result) { ... }`. |
| 3 | Is there one handler function per dispatched event, named `handle<Child><Event>`? (Rule 1) | Split combined handlers; rename per pattern. |
| 4 | Are child props derived from principal state via getters, not stored in a new data state? (Rule 2) | Replace the `@track` field with `get childProp() { return ... }`. |
| 5 | Is every presentation state exposed through a getter? (Rule 3) | Wrap in `get isXxxOpen() { return this._xxxId !== null; }`. |
| 6 | Is the active-object ID stored separately from the principal state? (Rule 4) | Add `@track _activeXxxId = null`. |
| 7 | Are there find / update / delete / create mutators (e.g. `_patchTicketEverywhere`)? (Rule 5) | Add them; never mutate state inline inside a handler. |
| 8 | On Apex failure, is a `ShowToastEvent` dispatched? (Rule 6) | Add the toast in the `.then()` failure branch. |
| 9 | When updating, are all levels on the path to the leaf spread, and is `_key` regenerated to flag the change? (Rule 7) | Apply the spread pattern; use `Id` to find, `_key` to flag. |
| 10 | Does every dispatched event from the child have a handler wired via `onxxx={handler}` in the template? | Add the missing `on<event>={handle<Child><Event>}` attribute. |

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

### Compact and final output

When all events have walked Step 0 → Step 10, emit the code in one pass. The
final output must include:

| # | Item |
|---|------|
| a | Chosen Apex call style with one-line justification |
| b | Event handler stub per dispatched event (Rule 1) |
| c | Wire or imperative call with Rule 0-compliant state update |
| d | Derived getter(s) for child props (Rule 2) |
| e | Find / update / delete / create mutators (Rule 5) |
| f | Presentation state declarations + their getters (Rules 3, 4) |
| g | `ShowToastEvent` on the failure branch (Rule 6) |
| h | Spread/`_key` pattern wherever principal state is updated (Rule 7) |

Do not emit code in chat during the interview — only at the end, after the full
analysis of the rules + the user's answers.

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

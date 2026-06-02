---
name: how-to-handle-apex-call-implementation
description: >
  Shared interview sub-step for deciding the `@wire` call style . 
  Goal is to know frontEnd level implementation of a lwc component.
---

# How To Handle Wire Implementation (shared interview sub-step)

Use this protocol at the point in any parent-interview where the data **can be
modified concurrently** (other users / other browser sessions) and you must
choose how aggressively the parent re-pulls it. The calling skill keeps its own
step number (e.g. `Step 2`, `Step 10`) and substitutes it into the tracker line
— the protocol itself is the same.

This is the visibility-urgency branch lifted from
[../lwc-parent-event-handler-generator.md](../lwc-parent-event-handler-generator.md)
(its Steps 2 → 3/4/5). Follow the answer-to-action mapping below verbatim; do
not invent a fourth option.

## Step 0 — gate: is the called Apex method `cacheable`?

`@wire` can only bind to an Apex method annotated
`@AuraEnabled(cacheable=true)`. Before doing anything below, check the method
the component calls:

- **Not cacheable** (`@AuraEnabled` without `cacheable=true`) → `@wire` is
  impossible. Use an **imperative call** instead (import the method and invoke
  it from `connectedCallback` / an action handler, updating principal state in
  the `.then(...)`). Skip the question and the `@wire` branches entirely.
- **Cacheable** (`@AuraEnabled(cacheable=true)`) → `@wire` is available.
  Proceed to the visibility-urgency question below.

```javascript
// Not cacheable → imperative call, no @wire.
import loadTickets from '@salesforce/apex/TicketController.loadTickets';

connectedCallback() {
    loadTickets({ sprintId: this.activeSprintId })
        .then(res => {
            if (res?.success) {
                this._tickets = res.data?.tickets || [];
            }
        });
}
```

## Question

> *"Do you want this value to be visible to other users as soon as possible?"*
> - *Very important*
> - *Important*
> - *Not important*

## Branches

### Very important → `@wire` + `refreshApex` on **every** applicable request

The freshest possible view: call `refreshApex(this.wiredResult)` after **every**
applicable request the child dispatches, so any concurrent write by another user
is pulled back immediately. Update principal state from the wired-function body
(Rule 0), never optimistically.

```javascript
// Very important: re-pull on every child request so other users' writes
// surface ASAP. Store the wired result so refreshApex can re-fire it.
_wiredTickets;

@wire(loadTickets, { sprintId: '$activeSprintId' })
wiredTickets(result) {
    this._wiredTickets = result;                 // keep for refreshApex
    if (result.data && result.data.success) {
        this._tickets = result.data.data?.tickets || [];
    }
}

handleTicketStatusChange(event) {
    const { ticketId, status } = event.detail;
    updateTicketStatus({ ticketId, status })
        .then(res => {
            if (res?.success) {
                return refreshApex(this._wiredTickets);   // every request
            }
            this.dispatchEvent(new ShowToastEvent({
                title: 'Update failed', message: res?.message, variant: 'error'
            }));
        });
}
```

### Important → `@wire` + `refreshApex` only on actions **related to this data**

Refresh selectively: call `refreshApex` only when the dispatched event actually
touches this data set, and skip it for unrelated child events. Cheaper than
"very important", still coherent for the writes that matter.

```javascript
// Important: refreshApex only on actions related to THIS data
// (status changes affect the list; a summary edit on one row does not).
_wiredTickets;

@wire(loadTickets, { sprintId: '$activeSprintId' })
wiredTickets(result) {
    this._wiredTickets = result;
    if (result.data && result.data.success) {
        this._tickets = result.data.data?.tickets || [];
    }
}

handleTicketStatusChange(event) {        // related → refresh
    const { ticketId, status } = event.detail;
    updateTicketStatus({ ticketId, status })
        .then(res => {
            if (res?.success) {
                return refreshApex(this._wiredTickets);
            }
            this.dispatchEvent(new ShowToastEvent({
                title: 'Update failed', message: res?.message, variant: 'error'
            }));
        });
}

handleTicketSummaryUpdate(event) {       // unrelated to the list → no refresh
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

### Not important → `@wire` **without** `refreshApex`

Stale-tolerant: wire the load once and let it re-fire only when its gating field
changes. No `refreshApex` — concurrent writes by others are not pulled back
until the wire naturally re-runs.

```javascript
// Not important: plain wired-function form, no refreshApex. The wire re-fires
// only when activeSprintId changes; concurrent edits by others are tolerated.
@wire(loadTickets, { sprintId: '$activeSprintId' })
wiredTickets(result) {
    if (result.data && result.data.success) {
        this._tickets = result.data.data?.tickets || [];
    }
}
```

## Second question — prevent the auto wire call in `connectedCallback`?

After the visibility-urgency branch is chosen, ask:

> *"Do you want to prevent the auto `@wire` call in `connectedCallback`?"*
> - *Yes*
> - *No*

### Yes → initialize all reactive (gating) state as `undefined`

A reactive `@wire` fires as soon as **all** of its `'$gating'` parameters are
defined. If you do not want it to run on first render, declare every reactive
parameter it depends on as `undefined` (do **not** seed it with a value in
`connectedCallback`). The wire stays dormant until a real user action assigns
a defined value to the gating field.

```javascript
// Yes: do not let the wire fire on connect. Every gating parameter starts
// undefined, so loadTickets is NOT called until something sets _wiredSprintId.
_wiredSprintId;            // undefined → wire dormant on first render

@wire(loadTickets, { sprintId: '$_wiredSprintId' })
wiredTickets(result) {
    if (result.data && result.data.success) {
        this._tickets = result.data.data?.tickets || [];
    }
}
```

## Rule — separate `wiredState` from the principal active id

**Always use a separate `wired<State>` field to drive the wire's reactivity.**
When a state change must trigger an Apex call, do **not** set the gating field
inside the wired function, and do **not** reuse the principal `active…Id` as the
wire parameter. Instead:

- The principal `active…Id` is for **UI update only** — it reflects selection /
  highlight and is set wherever the user interacts.
- A **separate** `_wired…Id` is the wire's gating parameter. It is assigned
  **only in the actual method that needs the wire to run**, not in the wired
  callback and not as a side effect of the UI selection.

Keeping the two apart means the wire fires exactly when the work that needs the
data happens — not every time the UI selection changes — and prevents the wired
function from feeding its own gating field (which would re-trigger itself).

```javascript
// Principal state: UI only. Selecting a sprint highlights it, no Apex call.
@track activeSprintId;

// Separate wire gate. Stays undefined until the method that needs data sets it.
_wiredSprintId;

@wire(loadTickets, { sprintId: '$_wiredSprintId' })
wiredTickets(result) {
    this._wiredTickets = result;
    if (result.data && result.data.success) {
        this._tickets = result.data.data?.tickets || [];
    }
    // NOTE: never assign this._wiredSprintId here.
}

handleSprintSelect(event) {
    // UI update only — does NOT load tickets.
    this.activeSprintId = event.detail.sprintId;
}

openSprintBoard() {
    // The method that actually needs the data sets the wire gate here.
    this._wiredSprintId = this.activeSprintId;
}
```


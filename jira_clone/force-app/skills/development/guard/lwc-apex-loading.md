---
name: lwc-apex-loading
description: >
  When a new (or newly edited) JavaScript handler in an LWC parent component
  makes an imperative Apex call (`apexMethod(...).then(...).catch(...)`),
  wire it to the component's `isLoading` flag so the user sees a spinner while
  the round-trip is in flight, AND make sure the spinner renders on top of any
  open modal/peek-panel via a dedicated `.loading-overlay` wrapper.

  TRIGGER (apply silently) when ALL of these are true: (1) the file under edit
  is an LWC parent JS (`force-app/main/default/lwc/<name>/<name>.js`), (2) the
  function being added or edited calls an imperatively-imported Apex method
  (any symbol imported from `@salesforce/apex/...`) via `.then(...).catch(...)`,
  and (3) the function is event-driven (a `handleXxx` user action), not a
  silent background refresh. The skill applies even when the handler is one of
  many in the same file — wire it up regardless.

  ALSO TRIGGER when the Apex call is declarative via `@wire` with a function
  handler: in that case the loading flag is owned by the **user-action
  handler that updates the reactive parameter** (the `$param` the wire
  depends on) — flip the flag on there, and flip it off inside the wire
  callback when `{ data, error }` arrives. See "Wire with function handler"
  below.

  SKIP when the function is a private helper that is ALREADY called by a
  public handler that owns the loading flag (don't double-toggle), when the
  component intentionally uses a different loading flag than `isLoading`
  (e.g. `backlogIsLoading`, `_isSavingComment`) — in that case, reuse the
  existing flag instead of introducing a new one, or when the component has
  no template/CSS at all (pure utility module).
---

# LWC Apex Loading Spinner

Every imperative Apex call in an LWC parent component is a network round-trip
the user is waiting on. Without a visible spinner, double-clicks turn into
duplicate writes, and modals close silently while the user wonders if their
action did anything. This skill enforces a single, consistent loading pattern
across the component:

1. The JS handler flips an `isLoading` flag for the lifetime of the Apex
   promise (`try` at the top, `finally` at the bottom).
2. The HTML renders a `<lightning-spinner>` wrapped in a `.loading-overlay`
   div that is fixed-positioned and stacked above every other surface in the
   component — modals, peek panels, bulk bars, etc.
3. The CSS gives that overlay a z-index strictly greater than every other
   z-index used in the file (modals are typically `9001`, so the overlay
   sits at `9999`).

The third point is the trap most implementations miss: a bare
`<lightning-spinner>` inside a `<section class="panel">` inherits the panel's
stacking context, so it disappears behind any open modal. The overlay
wrapper exists for exactly that reason.

---

## Instructions

### Step 1 — Confirm the handler is in scope

Before touching code, confirm ALL of the following:

| # | Check | How |
|---|-------|-----|
| 1 | The file is an LWC parent JS | Path matches `force-app/main/default/lwc/<name>/<name>.js` |
| 2 | The function imperatively calls Apex | Body contains `<importedSymbol>(...).then(...)` where `<importedSymbol>` is imported via `import ... from '@salesforce/apex/...'` |
| 3 | The function is user-initiated | Method name starts with `handle` OR is invoked from an event/onclick |
| 4 | No `@wire` is driving the same call | The promise chain is hand-written, not declarative |

If ANY of these fails, do NOT apply the skill — let the function be.

### Step 2 — Pick the loading flag

Inspect the component class for an existing loading flag, in this priority
order:

1. A scoped flag that already covers this exact section (e.g.
   `backlogIsLoading` for backlog-area handlers). **Reuse it.**
2. The conventional top-level flag `isLoading` declared on the class. Reuse
   it.
3. No flag exists. Declare `isLoading = false;` near the top of the
   `PROPERTIES & STATE` block.

NEVER introduce a new flag if a suitable one already exists — the goal is one
spinner-driving flag per visual region, not one per handler.

### Step 3 — Patch the JS handler

Apply this exact shape to the handler body:

```js
handleSomething(event) {
    const data = event.detail;
    this.isLoading = true;                       // ← added
    apexMethod({ ...data })
        .then(res => {
            if (!res.success) throw new Error(res.message || 'Error ...');
            // ... happy path: update state, close modal, toast
        })
        .catch(err => this._showError(err.body?.message || err.message || 'Error ...'))
        .finally(() => { this.isLoading = false; }); // ← added
}
```

Rules:

- The `isLoading = true` assignment goes **after** any cheap synchronous
  validation that might `return` early. Don't flip the spinner on if the
  function is about to bail out without ever calling Apex.
- The `.finally` goes **after** `.catch`, never before it. Promise chains
  resolve in declared order; putting `finally` first means a synchronous
  error in `then` won't reset the flag.
- Use the arrow form `() => { this.isLoading = false; }` so `this` stays
  bound to the component instance.
- Do NOT also set `isLoading = false` inside `then` or `catch` — `finally`
  covers both paths and double-resets are noise.

### Step 3b — Wire with function handler

When the Apex call is declarative (`@wire(apexMethod, { p: '$reactiveParam' })`
with a function handler that receives `{ data, error }`), the loading
toggle is **split across two methods**:

- The user-action handler that sets the reactive parameter (`this._foo = ...`)
  owns the `isLoading = true` assignment. Setting the param is what causes the
  wire to refire, so that's the moment the network request starts conceptually.
- The wire callback itself owns the `isLoading = false` assignment — that's
  when the response (or error) actually arrives.

```js

handleTicketLinkedToExpand(event) {
    this.isLoading = true;                              // ← flip ON here
    this._linkedToTargetTicketId = event.detail.ticketId; // ← triggers the wire
}
```

Rules specific to the wire form:

- Do NOT try to wrap the wire in a promise chain — the framework owns the
  lifecycle. `isLoading = false` lives inside the callback, not in a `finally`.
- Reset the flag on **both** branches (`data` and `error`). A single
  assignment at the bottom of the callback (after the `if/else`) is the
  cleanest way to guarantee that.
- Guard against the initial `null`/`undefined` call the wire fires before
  the user has triggered anything — early-return so you don't toggle the
  spinner for a no-op invocation.
- If the same reactive param is set by multiple handlers (e.g. open ticket
  view, refresh ticket view), every one of them must flip `isLoading = true`
  — the wire callback is the single source of truth for flipping it off.

### Step 4 — Ensure the HTML renders the overlay

In `<name>.html`, look for an existing render of the loading flag. Three
cases:

**Case A — no spinner exists yet.** Add this block once, near the top of the
relevant `<section>` (or the root `<template>` if the spinner should cover
the whole component):

```html
<template if:true={isLoading}>
    <div class="loading-overlay">
        <lightning-spinner alternative-text="Loading..." size="medium"></lightning-spinner>
    </div>
</template>
```

**Case B — a bare spinner exists** (`<lightning-spinner ...>` directly under
an `if:true={isLoading}` template, no wrapper div). Wrap it in the
`.loading-overlay` div:

```html
<!-- BEFORE -->
<template if:true={isLoading}>
    <lightning-spinner alternative-text="Loading..."></lightning-spinner>
</template>

<!-- AFTER -->
<template if:true={isLoading}>
    <div class="loading-overlay">
        <lightning-spinner alternative-text="Loading..." size="medium"></lightning-spinner>
    </div>
</template>
```

**Case C — overlay already present.** Leave it untouched.

### Step 5 — Ensure the CSS has the overlay class

In `<name>.css`, search for `.loading-overlay`. If absent, append:

```css
/* ── Full-page loading overlay (above modals) ────────────────────────────── */
.loading-overlay {
    position: fixed;
    inset: 0;
    background-color: rgba(9, 30, 66, 0.30);
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
}
```

Then verify the z-index ordering. Grep the same CSS file for `z-index:`:

- Every other z-index in the file must be **strictly less than** `9999`.
- Modal backdrop / modal / peek-panel are typically `9000` / `9001`. If the
  file uses anything `>= 9999`, raise the overlay above it (e.g. `99999`)
  rather than lowering the other surface.

The fixed-position overlay also dims the page behind it — that's intentional;
it both signals "the app is busy" and blocks click-throughs on whatever the
user was just interacting with (modal buttons, ticket rows, drag handles).

### Step 6 — Spot-check sibling handlers (optional cleanup)

After the new handler is wired, scan the same JS file for OTHER imperative
Apex handlers that are missing the same `isLoading` / `.finally` pair. If
you find one or two trivial omissions, mention them to the user as a
suggested follow-up — do NOT silently fix them all in the same edit, since
the user only asked about the one handler. The goal is to surface the
inconsistency, not to balloon the diff.

---

## Anti-patterns to refuse

| Anti-pattern | Why it's wrong | Fix |
|--------------|----------------|-----|
| Setting `isLoading = false` in BOTH `.then` and `.catch` | `.finally` already covers both — duplicates drift apart when one is edited | Use `.finally` only |
| Putting `.finally` before `.catch` | A handler in `.then` that throws skips straight to `.catch`, and `.finally` only sees the post-catch state — order matters for readability and tooling | `.then` → `.catch` → `.finally` |
| Bare `<lightning-spinner>` with no overlay | Inherits parent stacking context, hides behind modals | Wrap in `.loading-overlay` div |
| New per-handler boolean (`isSavingComment`, `isDeletingThing`) | One spinner-driving flag per visual region is enough; per-handler flags multiply state | Reuse the existing `isLoading` (or the region-scoped flag) |
| Flipping `isLoading = true` BEFORE early-return validation | Spinner flashes and clears for actions that never hit the network | Do validation first, then flip the flag |
| Lowering modal z-index to make the spinner show | Other modals in the codebase still expect `9001` — you've created an inconsistency | Raise the overlay's z-index above the modal, never the reverse |

---

## Worked example (from this codebase)

`manageBacklog.handleSprintTicketCreate` was added to dispatch
`createTicketFromSprint` but did not toggle `isLoading`. Three coordinated
edits made it correct:

**JS** (`manageBacklog.js`):

```js
handleSprintTicketCreate(event) {
    const data = event.detail;
    this.isLoading = true;
    createTicketFromSprint(data)
        .then(res => {
            if (!res.success) throw new Error(res.message || 'Error creating ticket from sprint');
            const ticket        = formatTicket(res.data.createdTicket, this.ticketTypeOptions, data.ticketTypeId);
            const updatedSprint = formatSprint(res.data.updatedSprint);
            this._enrichSprintWithAddedTicket(updatedSprint, ticket);
            this.showSprintTicketModal = false;
            this._showSuccess('Ticket added to sprint');
        })
        .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from sprint'))
        .finally(() => { this.isLoading = false; });
}
```

**HTML** (`manageBacklog.html`):

```html
<template if:true={isLoading}>
    <div class="loading-overlay">
        <lightning-spinner alternative-text="Loading..." size="medium"></lightning-spinner>
    </div>
</template>
```

**CSS** (`manageBacklog.css`):

```css
.loading-overlay {
    position: fixed;
    inset: 0;
    background-color: rgba(9, 30, 66, 0.30);
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
}
```

The modal sits at `z-index: 9001`; the overlay at `9999` covers it.

---

## Completion checklist

Before reporting the task as done, confirm:

**Imperative Apex case:**
- [ ] `this.isLoading = true;` appears **after** any synchronous early-return validation, **before** the Apex call.
- [ ] `.finally(() => { this.isLoading = false; })` is the **last** link in the promise chain.
- [ ] No `isLoading = false` assignment exists inside `.then` or `.catch`.

**`@wire` with function handler case:**
- [ ] Every user-action handler that mutates the reactive parameter sets `this.isLoading = true;`.
- [ ] The wire callback contains a single `this.isLoading = false;` reached on **both** the `data` and `error` branches.
- [ ] The wire callback guards against the initial null/undefined call before flipping any state.

**Shared (both cases):**
- [ ] The HTML renders `<lightning-spinner>` inside a `<div class="loading-overlay">` under `<template if:true={isLoading}>`.
- [ ] `.loading-overlay` exists in the CSS with `position: fixed`, `inset: 0`, and `z-index` strictly greater than every other z-index in the same file.
- [ ] The same loading flag is used (not a new per-handler boolean).

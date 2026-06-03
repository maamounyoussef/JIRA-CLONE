---
name: add-functionality-in-child-lwc-component
description: >
  Contains the per-sub-component interview (5 questions: user stories, behavior
  prompt, validation rules, `@api` data state, reusable base component) used
  when extending an existing child LWC with a new sub-component or new
  functionality. Also contains the child-contract checklist (no Apex, no `@api`
  mutation, `_` + `@track` draft state, lowercase event names, payload shapes
  per Create / Update / Delete / Load operation, sub-components inlined as
  `<section>`s in one template) and the optional `lwc-css-design-guide` handoff.
---

# Add Functionality In Child LWC Component

Turns a free-form "add a section to my child" or "add functionality to this
sub-component" request into a disciplined question-by-question interview that
extends an existing child correctly in one pass — independent of how many
sub-components the user stacks into the child. Children are presentation layers
only: they receive data through `@api`, keep their own draft/edit state,
validate locally, and emit `CustomEvent`s upward. Skipping the interview
produces additions that call Apex directly, mutate `@api` inputs, or split
sub-components into separate LWC files — patterns that break the architecture
and silently leak business logic into the view.

---

## Instructions

### Step 0 — Mandatory guides

Follow every guide below before any interview question in this skill. They are
required and run silently — never gated on a user question:

- **`lwc-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md`)
  — required: settle the LWC layering (page vs child, principal state, sidecars,
  naming / event conventions) before any interview question.
- **`pather_lwc_state_management_checklist-guide`** (`force-app/skills/development/task-skill/guide/pather_lwc_state_management_checklist-guide.md`)
  — required: the parent that handles the events this child dispatches must pass
  the state-management checklist (Rules 0–7).
- **`lwc-error-handling-guide`** ([guide/lwc-error-handling-guide](guide/lwc-error-handling-guide.md))
  — required: route every failure this functionality surfaces (synchronous
  validation, `success === false`, or error branch handled before emitting
  upward) through `ShowToastEvent`, never a tracked inline `errorMessage` banner.

Never start the per-sub-component interview without these settled — Steps 1–4
here assume them.

---

### Step 1 — Detect the interview entry point

Before writing any code, identify which branch of the interview applies. If
**any** signal matches, run the per-sub-component loop in Step 2:

| # | Signal | Example |
|---|--------|---------|
| 1 | Request to add a sub-component to an existing child | "add a Linked Items section to `ticketView`" |
| 2 | Request to add new functionality to an existing sub-component | "add an inline edit toggle to the Summary section" |
| 3 | User describes additional UI in an existing child that dispatches a payload upward | "when the user clicks save on the new Status section, fire an event" |
| 4 | User describes new draft state, edit-mode flags, or local validation in an existing child | "the description should now be editable, with a confirm/cancel button" |

If none match (e.g. the user wants to create a brand-new child, the parent
orchestrator that calls Apex, or a pure base wrapper with no domain), skip —
this is not an add-to-existing-child task.

Before any Question, ask only:

> "Which existing child are we modifying? Give me its name/path AND its current
> code (JS + HTML, and any validator). And in one line — what do you need to
> add?"

Do not assume the existing code — request it. Once received, begin the
per-sub-component loop at Question 1, scoped to that existing child; the final
build MODIFIES that child in place.

---

### Step 2 — Run the per-sub-component interview

Apply the **five questions** in order, one at a time, for every new or modified
sub-component. Every sub-component must pass all five before moving to the next:

1. **User stories.** Ask the user for the user stories that apply to this
   sub-component. Each operation (Load / Update / Create / Delete — or any
   combination) must have its **own** user story. The user writes the stories —
   never invent them.
2. **Behavior prompt.** Ask: *"Give me the component behavior prompt. It must
   cover every user story."* Verify coverage by semantic comparison, not keyword
   matching. If a story is not covered, reply: *"The following user story is not
   covered: `<quote>`. Please provide the behavior prompt again, including this
   part."* Never suggest the missing behavior.
3. **Validation rules.** Run the shared step defined in
   [shared/ask-user-for-lwc-validation.md](shared/ask-user-for-lwc-validation.md).
   Do not inline the branches here — load that file and follow it verbatim.
   Validations live in a sibling `<name>Validator.js` file, not inline.
4. **Data state.** Ask which `@api` state provides the data for this
   sub-component. The user supplies the source object and field.
5. **Reusable base component.** Ask whether an existing base LWC component
   (`c-ao-input`, `c-ao-btn`, `c-ao-combobox`, `lightning-*`) should be used
   instead of writing the UI from scratch. The user provides the name.


Anti-pattern to detect:

```javascript
// ❌ Child calls Apex directly, mutates @api input, splits into separate LWC
import saveTicket from '@salesforce/apex/TicketController.saveTicket';
export default class TicketSummary extends LightningElement {
    @api ticket;
    handleSave() {
        this.ticket.summary = this.draftSummary;       // mutates @api
        saveTicket({ ticket: this.ticket });           // calls Apex from child
    }
}
```

Interview-driven form to write instead:

```javascript
// ✅ Child holds local draft, validates, dispatches event upward
import { validateTicketSummary } from './ticketViewValidator';
export default class TicketView extends LightningElement {
    _ticket = {};
    @api get ticket() { return this._ticket; }
    set ticket(value) {
        this._ticket = value || {};
        this._draftSummary = this._ticket.summary || '';
    }

    @track _isSummaryEditing = false;
    @track _draftSummary     = '';
    @track _summaryError     = null;

    get isSummaryEditing() { return this._isSummaryEditing; }
    get draftSummary()     { return this._draftSummary; }
    get summaryError()     { return this._summaryError; }

    handleTicketSummarySave() {
        const error = validateTicketSummary(this._draftSummary);
        if (error) { this._summaryError = error; return; }
        const detail = { ticketId: this._ticket.id, summary: this._draftSummary.trim() };
        this.dispatchEvent(new CustomEvent('ticketsummaryupdate', {
            detail, bubbles: true, composed: true
        }));
        this._isSummaryEditing = false;
    }
}
```

---

### Step 3 — Place sub-components in the right layer

Layering still applies (see `lwc-architecture`):

- The **child** (`lwc/<childName>/**`) owns presentation state and dispatches
  events. It never calls Apex.
- All sub-components (Summary, Status, Description, Linked Items, etc.) live
  inside the **same** LWC template as sections — they are NOT extracted into
  separate LWC files.
- The **parent** orchestrator listens for the dispatched events and calls Apex.
- Validations live in a sibling `<childName>Validator.js` module — never inline
  inside the component class.

When extending an existing child, NEW sub-components are added as additional
`<section>`s in the same `.html`, NEW state fields go into the same `.js` with
the `_` + `@track` convention, and NEW validators are appended to the existing
sibling `<childName>Validator.js` — never spun out into a separate file.

---

### Step 4 — Verify with the execution checklist

Before presenting the modified code (after `compact`), walk the checklist. If
any row fails, fix it before emitting code:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | Does the child (after edits) import or call any `@salesforce/apex/...` method? | Remove — dispatch a `CustomEvent` instead; the parent calls Apex. |
| 2 | Is every newly displayed value sourced from an `@api` property via a private backing field (`_ticket`) and exposed via a getter? | Add the backing field, the `@api` getter/setter, and a getter for every template-bound value. |
| 3 | Does any new handler mutate the `@api` object in place? | Replace with a dispatched event carrying the change. |
| 4 | Is every new local presentation field prefixed with `_` and decorated `@track`? | Rename and add `@track`. |
| 5 | Are all sub-components (existing + new) rendered inside one LWC template (no separate child LWC files)? | Inline new ones as `<section>`s in the same `.html`. |
| 6 | Are all newly dispatched event names lowercase (no camelCase, no hyphens)? | Rename: `ticketSummaryUpdate` → `ticketsummaryupdate`. |
| 7 | Does every newly dispatched event carry the right payload shape (Create / Update / Delete / Load)? | See "Event payload shapes" in Resources. |
| 8 | Is every newly bound template value exposed through a getter (never a raw class field)? | Wrap in a `get xxx() { return this._xxx; }`. |
| 9 | Does each new user story map to at least one task and one dispatched event? | Report the gap and ask the user to resolve it BEFORE coding. |
| 10 | Have existing sub-components, getters, handlers, and dispatched events been preserved (no accidental removal)? | Re-add anything dropped during the edit. |

---

### Step 5 — Optionally apply `lwc-css-design-guide`

After the code is emitted and accepted, ASK the user via the interactive
`AskUserQuestion` tool (NOT plain text) whether to also apply the
**`lwc-css-design-guide`** skill
(`force-app/skills/development/task-skill/guide/lwc-css-design-guide.md`) to style the
new/modified sections. Frame it as a single yes/no choice (e.g. "Apply the
project's CSS design system to the new section(s) now?" with options "Yes,
apply lwc-css-design-guide" / "No, skip styling").

- Yes → follow `lwc-css-design-guide` end-to-end: produce/update the `.css` file
  using the project's Atlassian/Jira palette, type scale, spacing, BEM
  naming, interactive-state recipes, and shared patterns (modal, peek panel,
  error banner, empty state, bulk bar, drag-and-drop).
- No → exit this skill.

Never invent CSS without invoking `lwc-css-design-guide` — it codifies the
project's visual language so a new section drops in next to `ticketView` /
`manageBacklog` / `aoBtn` without any visual tuning.

---

## Resources

### Reference rewrite

`force-app/main/default/lwc/ticketView/` — worked example of this skill applied
to the Ticket View screen: Summary, Status, Description, and Linked Items
sub-components all in one LWC, each dispatching a typed `CustomEvent`
(`ticketsummaryupdate`, `ticketstatuschange`, `ticketdescriptionupdate`,
`ticketlinkedtoexpand`, `ticketlinkcreate`, `ticketsearch`, `closeticketview`).
Use as the canonical "before/after" when extending a child.

### Reference validator

`force-app/main/default/lwc/ticketView/ticketViewValidator.js` — template for
LWC-side validation: one `validateXxx(value)` function per field, returning the
error message string or `null`.  Append new `validateXxx` functions
here when adding validations in Question 3 — never spin out a new validator
file.

### Event payload shapes (the contract this skill protects)

| Operation | Payload | Event-name pattern |
|---|---|---|
| **Create** | the new data of the object; include the **parent ID** if nested in an array of a higher-level object | `<object>create`, e.g. `ticketlinkcreate` |
| **Update** (single field) | object's **ID** + the changed field | `<object><field>update`, e.g. `ticketsummaryupdate` |
| **Update** (full object) | object's **ID** + the changed data | `<object>update`, e.g. `ticketupdate` |
| **Delete** | object's **ID** only | `<object>delete` |
| **Load** | the **ID of the higher-level object** owning the nested data | `<object><nested>expand`, e.g. `ticketlinkedtoexpand` |

All event names are **lowercase** — no camelCase, no hyphens. Every dispatch uses
`bubbles: true, composed: true` so the parent can listen at any level.

---

## Optional Logic

### Compact and build

`compact` is the signal that the interview is finished and code should now be
produced.

- **Trigger:** the user types `compact`, OR gives any unambiguous instruction
  meaning "we're done, build it now."
- **Before building, you compact** — consolidate everything gathered into one
  specification: full list of user stories per new/modified sub-component,
  derived tasks (Load / Update / Create / Delete), behavior, validation rules,
  `@api` data state, base components, and dispatched events.
- **Coverage gate:** confirm every collected user story maps to at least one
  task and one dispatched event. If any story is uncovered, report the gap and
  ask the user to resolve it BEFORE coding — do not silently fill it.
- **Then, and only then,** modify the existing `<childName>.js`,
  `<childName>.html`, and `<childName>Validator.js` in one pass, in line with
  all checks in Step 4. Preserve all existing sub-components and handlers
  unless the user explicitly asked to remove them.

### Integration with `lwc-architecture` skill

After extending the child, run the `lwc-architecture` skill on the parent
orchestrator so that any NEW event names this child now dispatches are wired to
the correct `@AuraEnabled` controller method and the `APIResponse` envelope is
honored end-to-end.

### When to skip

Skip the interview (Step 2) only when:

- The work is **creating a brand-new** child — use
  `create-new-child-lwc-component` instead.
- The work is the **parent** LWC orchestrator that calls Apex — use the parent /
  `lwc-architecture` skill instead.
- The work is a **pure base wrapper** (`c-ao-*`, `lightning-*`) with no domain
  user stories — no interview is needed because there are no user stories,
  validations, or dispatched events to gather.
- The user explicitly asks for a one-line tweak (rename a getter, change a CSS
  class) that does not change behavior, validation, or dispatched events.

Do **not** skip on the basis that "the addition is small" — small additions
that skip the interview routinely end up calling Apex, mutating `@api`, or
splitting into separate LWC files, and have to be rewritten on the next pass.

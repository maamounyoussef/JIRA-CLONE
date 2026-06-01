# Create New Child LWC Component

Turns a free-form "create me a new child component" request into a disciplined
question-by-question interview that produces correct, layered LWC code in one
pass — independent of how many sub-components the user stacks into the child.
Children are presentation layers only: they receive data through `@api`, keep
their own draft/edit state, validate locally, and emit `CustomEvent`s upward.
Skipping the interview produces children that call Apex directly, mutate `@api`
inputs, or split sub-components across separate LWC files — patterns that break
the architecture and silently leak business logic into the view.

---

## Instructions

### Step 1 — Detect the interview entry point

Before writing any code, identify which branch of the interview applies. If
**any** signal matches, run the per-sub-component loop in Step 2:

| # | Signal | Example |
|---|--------|---------|
| 1 | Request to create a brand-new child | "create a child component called `ticketView`" |
| 2 | User describes UI in a new child that dispatches a payload upward | "when the user clicks save, fire an event with the new summary" |
| 3 | User describes draft state, edit-mode flags, or local validation in a new child | "the summary should be editable, with a confirm/cancel button" |

If none match (e.g. the user wants to add to an existing child, the parent
orchestrator that calls Apex, or a pure base wrapper with no domain), skip —
this is not a create-new-child task.

Before any Question, ask only:

> "What is the new child's name, and in one line — what does it need to do?"

Then begin the per-sub-component loop at Question 1 for the first sub-component.

---

### Step 2 — Run the per-sub-component interview

Apply the **five questions** in order, one at a time, for every sub-component.
Every sub-component must pass all five before moving to the next:

1. **User stories.** Ask the user for the user stories that apply to this
   sub-component. Each operation (Load / Update / Create / Delete — or any
   combination) must have its **own** user story. The user writes the stories —
   never invent them.
2. **Behavior prompt.** Ask: *"Give me the component behavior prompt. It must
   cover every user story."* Verify coverage by semantic comparison, not keyword
   matching. If a story is not covered, reply: *"The following user story is not
   covered: `<quote>`. Please provide the behavior prompt again, including this
   part."* Never suggest the missing behavior.
3. **Validation rules.** Ask for the validations to enforce before dispatching
   any event. The user provides them. Validations live in a sibling
   `<name>Validator.js` file, not inline.
4. **Data state.** Ask which `@api` state provides the data for this
   sub-component. The user supplies the source object and field.
5. **Reusable base component.** Ask whether an existing base LWC component
   (`c-ao-input`, `c-ao-btn`, `c-ao-combobox`, `lightning-*`) should be used
   instead of writing the UI from scratch. The user provides the name.

Interview discipline (non-negotiable):

```
[Child: <name> | Sub-component: <subName> | Question <N>]
```

- Print the tracker line above at the top of **every** question. If you cannot
  fill it in, you have lost state — reconstruct it before doing anything else.
- ONE question per message. Never present two questions together. Never
  pre-answer a later question. Never say "if you pick X then I'll ask Y."
- Do not skip Questions. Move only along the branch arrows defined here.
- No code until the interview for **all** sub-components is finished.
- "I don't know" is valid ONLY for analysis the AI is allowed to make itself
  (event payload shape, event name, derived tasks/sub-tasks). For user stories,
  behavior, validations, data state, and base-component names, the user is the
  source of truth — re-ask; do NOT invent them.
- After finishing one sub-component (Question 1 → Question 5), return to the top
  of the loop for the next sub-component, until the user runs `compact`.

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

---

### Step 4 — Verify with the execution checklist

Before presenting the generated code (after `compact`), walk the checklist. If
any row fails, fix it before emitting code:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | Does the child import or call any `@salesforce/apex/...` method? | Remove — dispatch a `CustomEvent` instead; the parent calls Apex. |
| 2 | Is every displayed value sourced from an `@api` property via a private backing field (`_ticket`) and exposed via a getter? | Add the backing field, the `@api` getter/setter, and a getter for every template-bound value. |
| 3 | Does the child mutate the `@api` object in place? | Replace with a dispatched event carrying the change. |
| 4 | Is every local presentation field prefixed with `_` and decorated `@track`? | Rename and add `@track`. |
| 5 | Are all sub-components rendered inside one LWC template (no separate child LWC files)? | Inline them as `<section>`s in the same `.html`. |
| 6 | Are all dispatched event names lowercase (no camelCase, no hyphens)? | Rename: `ticketSummaryUpdate` → `ticketsummaryupdate`. |
| 7 | Does every dispatched event carry the right payload shape (Create / Update / Delete / Load)? | See "Event payload shapes" in Resources. |
| 8 | Is every value bound in the template exposed through a getter (never a raw class field)? | Wrap in a `get xxx() { return this._xxx; }`. |
| 9 | Does each user story map to at least one task and one dispatched event? | Report the gap and ask the user to resolve it BEFORE coding. |

---

## Resources

### Reference rewrite

`force-app/main/default/lwc/ticketView/` — worked example of this skill applied
to the Ticket View screen: Summary, Status, Description, and Linked Items
sub-components all in one LWC, each dispatching a typed `CustomEvent`
(`ticketsummaryupdate`, `ticketstatuschange`, `ticketdescriptionupdate`,
`ticketlinkedtoexpand`, `ticketlinkcreate`, `ticketsearch`, `closeticketview`).
Use as the canonical "before/after" for any new child.

### Reference validator

`force-app/main/default/lwc/ticketView/ticketViewValidator.js` — template for
LWC-side validation: one `validateXxx(value)` function per field, returning the
error message string or `null`. Required-field messages come from
`OBJECT_VALIDATION_LWC_APEX.md` (LWC table). Use as the template when adding
validations in Question 3.

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
  specification: full list of user stories per sub-component, derived tasks
  (Load / Update / Create / Delete), behavior, validation rules, `@api` data
  state, base components, and dispatched events.
- **Coverage gate:** confirm every collected user story maps to at least one
  task and one dispatched event. If any story is uncovered, report the gap and
  ask the user to resolve it BEFORE coding — do not silently fill it.
- **Then, and only then,** generate `<childName>.js`, `<childName>.html`, and
  `<childName>Validator.js` in one pass, in line with all checks in Step 4.

### Integration with `lwc-architecture` skill

After producing the child, run the `lwc-architecture` skill on the parent
orchestrator so that the event names this child dispatches are wired to the
correct `@AuraEnabled` controller method and the `APIResponse` envelope is
honored end-to-end.

### When to skip

Skip the interview (Step 2) only when:

- The work is adding to an **existing** child — use
  `add-functionality-in-child-lwc-component` instead.
- The work is the **parent** LWC orchestrator that calls Apex — use the parent /
  `lwc-architecture` skill instead.
- The work is a **pure base wrapper** (`c-ao-*`, `lightning-*`) with no domain
  user stories — no interview is needed because there are no user stories,
  validations, or dispatched events to gather.

Do **not** skip on the basis that "the child is small" — small children that
skip the interview routinely end up calling Apex, mutating `@api`, or splitting
into separate LWC files, and have to be rewritten on the next pass.

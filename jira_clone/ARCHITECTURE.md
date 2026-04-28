# Salesforce LWC — Custom Layered Architecture

---

## Final Architecture

```
classes/
|
|__ controller/                         ← Entry Points (per page)
|   |__ manageBacklog/
|   |   |__ ManageBacklogController.cls
|   |   |__ ManageBacklogControllerTest.cls
|   |
|   |__ manageWorkflow/
|       |__ ManageWorkflowController.cls
|       |__ ManageWorkflowControllerTest.cls
|
|__ domain/                             ← Business Logic (per domain object)
    |__ DomainCompleteValidator.cls
    |__ EpicService.cls
    |__ ProjectService.cls
    |__ SprintService.cls
    |__ StatusService.cls
    |__ TicketService.cls
```

### Call Flow

```
LWC Page
  |
  |__ Page Controller
        |
        |__ Domain Service
              |
              |__ DomainCompleteValidator
              |
              |__ SOQL / DML
```

### Layer Responsibilities

| Layer | Unit | Responsibility |
|---|---|---|
| Controller | Per page | Receives LWC calls, delegates to services |
| Service | Per domain object | Business operations |
| DomainCompleteValidator | Per object | Cross-field / cross-object business rules |

### Reusable Modal Pattern

```
Reusable Modal (createTicketModal, createEpicModal, ...)
  |
  |__ dispatches CustomEvent + payload
        |
        |__ ManageBacklogPage → ManageBacklogController → TicketService
        |__ ManageWorkflowPage → ManageWorkflowController → TicketService
```

> The modal owns: UI, input collection, dispatching.
> The page owns: reacting, calling Apex, post-action behavior.

---

---

## The Story — How We Got Here

---

### Step 1 — The Starting Point: High Dependency Between Domains

The project has tightly coupled domains. Every object depends on others.
Finding clean boundaries to split the system into independent modules was not possible —
it looked like one single boundary, not many.

```
Epic ←→ Sprint ←→ Ticket ←→ Project ←→ Status
  ↑_____________________________________________↑
              (everything depends on everything)
```

We could not find separated boundaries — the system behaves as one single boundary, not many.

---

### Step 2 — Rejecting Modular Architecture Per Boundary

Layering the architecture per domain was considered:

```
classes/
|__ epic/
|   |__ EpicController.cls
|   |__ EpicService.cls
|   |__ EpicRepository.cls
|
|__ sprint/
|   |__ SprintController.cls
|   |__ SprintService.cls
|   |__ SprintRepository.cls
|
|__ ticket/
    |__ TicketController.cls
    |__ TicketService.cls
    |__ TicketRepository.cls
```

**Why this was rejected:**
- Salesforce charges per metadata item — too many classes
- Navigation and search become very hard across many folders
- High inter-domain dependency means services would still call each other across folders
- No real isolation gained despite the extra cost

---

### Step 3 — Rejecting Micro-Kernel

The pages are configurable, which made micro-kernel appealing —
the idea of a core with pluggable domain plugins.

```
core/
|__ CoreEngine.cls       ← core
|
plugins/
|__ EpicPlugin.cls       ← plugin
|__ SprintPlugin.cls     ← plugin
|__ TicketPlugin.cls     ← plugin
```

**Why this was rejected:**
- Plugins must be independent and plug-and-play
- But domains depend on each other — EpicPlugin needs SprintPlugin, TicketPlugin needs EpicPlugin
- Adding a new plugin always requires modifying the core
- This fully breaks the micro-kernel contract

---

### Step 4 — The Custom Architecture Decision

Given the constraints, a custom layered architecture was designed around two principles:

- **Shared is the principle** — logic is shared across pages, not duplicated
- **Page is the entry point** — all actions flow through the page controller

```
classes/
|
|__ controller/                    ← per PAGE
|   |__ manageBacklog/
|   |   |__ ManageBacklogController.cls
|   |
|   |__ manageWorkflow/
|       |__ ManageWorkflowController.cls
|
|__ domain/                        ← per DOMAIN OBJECT
    |__ EpicService.cls
    |__ SprintService.cls
    |__ TicketService.cls
    |__ ProjectService.cls
    |__ StatusService.cls
```

Controller per page handles the configurable nature of pages.
Service per domain handles the shared business logic.

---

### Step 5 — Why Service + Repository, Then Why Repository Was Dropped

Initially a repository layer was considered to isolate data access
and remove SOQL from services — keeping services focused only on business logic.

```
classes/
|
|__ controller/
|   |__ ManageBacklogController.cls
|
|__ domain/
|   |__ EpicService.cls          ← business logic only
|   |__ SprintService.cls
|
|__ repository/
    |__ EpicRepository.cls       ← data access only
    |__ SprintRepository.cls
```

**Why repository was dropped:**
- Salesforce charges per metadata item — adding a full repository layer doubles the class count
- The benefit of isolating SOQL did not justify the cost at this scale
- Services calling SOQL directly is acceptable

---

### Step 6 — Introducing DomainCompleteValidator

Removing the repository layer created a new problem:
business rules that span multiple fields or objects had no clean home.

SObject definitions live in different metadata paths, so a single object cannot
validate all its own rules. A dedicated validator was introduced:

```
classes/
|
|__ controller/
|   |__ ManageBacklogController.cls
|
|__ domain/
    |__ DomainCompleteValidator.cls   ← NEW: cross-field / cross-object rules
    |__ EpicService.cls
    |__ SprintService.cls
    |__ TicketService.cls
    |__ ProjectService.cls
    |__ StatusService.cls
```

```
Domain Service
  |
  |__ DomainCompleteValidator   ← checks business rules
  |
  |__ SOQL / DML                ← data access directly
```

This is the final backend architecture.

---

### Step 7 — The LWC Challenge: Reusable Modals

With the backend settled, a new challenge appeared on the frontend.

Some modals are reusable — they appear on multiple pages with the same UI and flow:

```
ManageBacklogPage ──┐
                    ├──► createTicketModal
ManageWorkflowPage ─┘

ManageBacklogPage ──┐
                    ├──► createEpicModal
ManageSprintPage ───┘
```

---

### Step 8 — Option 1 Rejected: Modal Calls Apex Directly

The modal could call a controller directly:

```
createTicketModal → ManageBacklogController.createTicket()
```

**Why rejected:**
- The modal is now coupled to one specific controller
- It cannot be used from ManageWorkflowPage without modification
- Reusability is broken

---

### Step 9 — Option 2 Rejected: Dedicated Modal Controller

A new controller could be created just for the modal:

```
classes/
|__ controller/
|   |__ manageBacklog/
|   |   |__ ManageBacklogController.cls
|   |
|   |__ manageWorkflow/
|   |   |__ ManageWorkflowController.cls
|   |
|   |__ modal/                          ← REJECTED
|       |__ CreateTicketModalController.cls
```

**Why rejected:**
- Controllers are per page — this breaks the architectural principle
- It is overkill and inconsistent
- Each parent may need different post-action behavior (refresh different data, navigate differently)
- The modal still cannot behave differently depending on which page it is on

---

### Step 10 — Final Solution: Modal Dispatches Event, Parent Calls Apex

The modal owns only the UI and input collection.
It dispatches a custom event with the data as payload.
Each parent page handles the event its own way.

```
createTicketModal
  |
  |__ dispatches: CustomEvent("ticketcreate", { detail: formData })
        |
        |__ ManageBacklogPage
        |     |__ handleTicketCreate(event)
        |           |__ ManageBacklogController.createTicket(event.detail)
        |
        |__ ManageWorkflowPage
              |__ handleTicketCreate(event)
                    |__ ManageWorkflowController.createTicket(event.detail)
```

**Why this works:**
- Modal has zero dependency on any controller — fully reusable
- Each parent decides what to do after the action
- Consistent with the architecture — Apex is always called from the page controller
- Maximum dependency depth stays at 2 levels: LWC → Controller → Service

---

### Step 11 — New Problem: The Modal Does Not Know If the Request Succeeded

Step 10 solved reusability — but introduced a new gap.

The modal dispatches an event and hands off control to the parent.
From that point, the modal is blind: it does not know whether the Apex call succeeded or failed.

```
createTicketModal
  |__ dispatches event → ManageBacklogPage → ManageBacklogController
                                                        |
                                           success? fail? ← modal has no visibility here
```

**The problem has two sides:**

- On **failure** — the error must be shown inside the modal, not on the parent page.
  The modal is still open, the user is still looking at it.
  Displaying the error on the parent behind the modal makes no sense.

- On **success** — the parent simply sets `show` to `false`, closing the modal.
  No explicit signal is needed — the disappearance of the modal is the confirmation.

---

**The solution: `@api errors` with getter and setter**

The parent passes the error down to the modal through a public `@api` property.

```
ManageBacklogPage
  |__ calls Apex
  |__ on fail  → sets this.errors = error  → flows down into modal via @api errors
  |__ on success → sets this.show = false   → modal closes, no error needed
```

**Why getter and setter, not a plain `@api` property:**

A plain `@api` property would work for passing data down —
but a setter allows the modal to react the moment the value changes:
clear a previous error, scroll to the error message, reset a spinner, or trigger an animation.

```javascript
// In createTicketModal.js

_errors;

@api
get errors() {
    return this._errors;
}

set errors(value) {
    this._errors = value;
    // React to the incoming error:
    // scroll to error, stop spinner, highlight fields, etc.
}
```

```javascript
// In ManageBacklogPage.js

errors; // bound to modal via errors={errors}

async handleTicketCreate(event) {
    try {
        await createTicket({ data: event.detail });
        this.show = false;      // success: close the modal
    } catch (error) {
        this.errors = error;    // fail: push error into modal
    }
}
```

```html
<!-- In manageBacklogPage.html -->

<c-create-ticket-modal
    if:true={show}
    errors={errors}
    oncreateticket={handleTicketCreate}>
</c-create-ticket-modal>
```

**Why this works:**
- The modal stays responsible for displaying its own errors — consistent with it owning the UI
- The parent stays responsible for calling Apex and reacting to the outcome — consistent with the architecture
- Success requires no extra signal — closing the modal is the signal
- The setter gives the modal a reactive hook without breaking encapsulation
# Salesforce LWC — Custom Layered Architecture

---

## Goal

The goal was to find an architecture that is the best fit for this project within the constraints that Salesforce imposes at the architecture level.

Salesforce is not a neutral runtime — it shapes architectural decisions directly.
Every Apex class is a metadata item with a deployment cost, an org limit, and a maintenance surface.
Standard patterns from other ecosystems do not translate cleanly here.

Two factors were treated as primary throughout every decision:

- **Maintainability** — the architecture must be navigable, readable, and easy to change by a single developer or a small team. Complexity that serves a pattern but not the project is rejected.
- **Metadata cost** — every additional class has a real cost in Salesforce: it counts against org limits, increases deployment time, and adds navigation overhead. No layer is added unless it earns its place.

Every step in the story below is a decision made against these two constraints.
Patterns that are standard elsewhere were rejected when they conflicted with them.
The result is a custom architecture shaped by what this project actually needs inside Salesforce — not by what looks correct in the abstract.

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
    |__ DomainCorrectnessValidator.cls
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
        |__ DomainCorrectnessValidator   ← runs BEFORE service call
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
| Controller | Per page | Receives LWC calls, validates correctness, delegates to services |
| DomainCorrectnessValidator | Per object | Structural / referential correctness rules (called by controller) |
| Service | Per domain object | Business operations |
| DomainCompleteValidator | Per object | Cross-field / cross-object business rules (called by service) |

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

---

### Step 12 — Splitting DomainCompleteValidator: The Repeated Validation Problem

Services call each other. `TicketService` calls `SprintService`. `SprintService` calls `ProjectService`.
Each service ran its own `DomainCompleteValidator` checks at the start.

This meant that a check like "does this Project ID exist?" ran once inside `ProjectService`,
then again inside `SprintService` when it called `ProjectService`, then again inside `TicketService`
when it called `SprintService` — the same SOQL query firing multiple times for the same record.

```
TicketService
  |__ DomainCompleteValidator.validateTicket()   ← checks project id
  |
  |__ SprintService
        |__ DomainCompleteValidator.validateSprint()   ← checks project id again
        |
        |__ ProjectService
              |__ DomainCompleteValidator.validateProject()   ← checks project id again
```

The deeper the call chain, the more times the same checks repeated.

---

**The solution: move correctness checks up to the controller**

The controller is the single entry point — it runs once, before any service is called.
Running correctness checks there means they run exactly once, regardless of how many
services call each other downstream.

`DomainCompleteValidator` is split into two classes:

- `DomainCompleteValidator` — keeps the business rules. Still called by services, unchanged.
- `DomainCorrectnessValidator` — takes the correctness checks. Called by the controller only, before any service.

```
classes/
|
|__ controller/
|   |__ ManageBacklogController.cls
|   |__ ManageWorkflowController.cls
|
|__ domain/
    |__ DomainCompleteValidator.cls     ← business rules  (called by service)
    |__ DomainCorrectnessValidator.cls  ← correctness     (called by controller, once)
    |__ EpicService.cls
    |__ SprintService.cls
    |__ TicketService.cls
    |__ ProjectService.cls
    |__ StatusService.cls
```

---

**The new call flow:**

```
LWC Page
  |
  |__ Page Controller
        |
        |__ [1] Input validation
        |
        |__ [2] DomainCorrectnessValidator   ← runs once, here, never again
        |
        |__ [3] Domain Service
                  |
                  |__ calls other services freely — no repeated checks
                  |
                  |__ DomainCompleteValidator   ← business rules only
                  |
                  |__ SOQL / DML
```

---

**What changed in the Apex:**

1. `DomainCompleteValidator` — correctness checks are removed. Business rules only remain.

2. `DomainCorrectnessValidator` — new class. Contains all correctness checks extracted
   from the old validator.

3. Controllers — call `DomainCorrectnessValidator` after input validation, before any service call.

4. Services — correctness checks removed. They call each other freely without re-validating.

---

**Controller pattern (after the change):**

```apex
// ManageBacklogController.cls

@AuraEnabled
public static void addSubTask(Id ticketId, Map<String, Object> subTaskInformation) {
    // [1] Input validation (example)
    if (subTaskInformation == null || subTaskInformation.get('title') == null) {
        throw new AuraHandledException('Title is required.');
    }

    // [2] Correctness — runs once, here
    DomainCorrectnessValidator.checkTicketExist(ticketId);

    // [3] Business operation
    TicketService.updateSubTask(ticketId, subTaskInformation);
}
```

**Service pattern (after the change):**

```apex
// TicketService.cls

public static void updateSubTask(Id ticketId, Map<String, Object> subTaskInformation) {
    // Business rules only — correctness already guaranteed
    DomainCompleteValidator.validateTicketExist(ticketId);
    DomainCompleteValidator.validateTicketOfTypeTask(ticketId);

    // Calls other services freely
    SprintService.doSomething(subTaskInformation);

    // Create SubTask record (example)
    SubTask__c subTask = new SubTask__c();
    subTask.Title__c = (String) subTaskInformation.get('title');
    subTask.Ticket__c = ticketId;

    insert subTask;
}
```

**Why this works:**
- Correctness checks run exactly once per request, at the controller level
- Services call each other without triggering repeated SOQL checks
- The split is mechanical — business rules stay where they were, correctness moves up one layer
---

### Step 13 — New Problem: Repeated DB Retrieval Across Correctness and Service Layers

Step 12 moved correctness checks to the controller level — eliminating repeated SOQL across chained service calls.
But a new problem remained: the same object is retrieved from the database multiple times within a single request.

```
Controller
  |__ [1] Input validation
  |
  |__ [2] DomainCorrectnessValidator
  |         |__ checkTicketExist(ticketId)
  |               |__ SELECT ... WHERE Id = ticketId   ← retrieves object (1st time)
  |
  |__ [3] TicketService
                |__ DomainCompleteValidator.validateTicketExist(ticketId)
                |         |__ SELECT ... WHERE Id = ticketId   ← retrieves object (2nd time)
                |
                |__ DomainCompleteValidator.validateTicketOfTypeTask(ticketId)
                          |__ SELECT ... WHERE Id = ticketId   ← retrieves object (3rd time)
```

The correctness check confirms the object exists — but discards the result.
The service then retrieves the same object again to apply business rules, and potentially again inside each validator method.

The deeper or more complex the operation, the more times the same record is fetched for no reason.

---

**Why this is a real problem in this architecture**

In some systems, this redundancy is absorbed automatically:
- A request-scoped cache means the second fetch for the same ID costs nothing
- A centralized data access layer (repository) means the query is issued once and the result is shared

Neither exists here.

Salesforce has no built-in per-request query cache — every `SELECT` is a real database hit,
counted against governor limits. Two fetches of the same record costs twice the SOQL queries.

The architecture also has no centralized DB call layer. The repository was deliberately dropped in Step 5
because the class count cost outweighed the benefit. Without it, there is no single place
that could deduplicate fetches automatically.

So the redundancy is real, it hits governor limits, and it cannot be absorbed by infrastructure.
It has to be solved explicitly in the call flow.

---

**The solution: pass the object, not the ID**

Three targeted changes eliminate the redundant queries:

**1. Correctness should return the object**

`DomainCorrectnessValidator` already queries the record to confirm it exists.
Instead of discarding the result, it returns the object to the controller.

**2. Pass the object to the service, not the ID**

The controller receives the object from correctness, then passes it directly into the service.
The service never needs to query for it again.

**Before** — service receives an Id and queries the DB again:

```apex
// TicketService.cls — BEFORE

public static Ticket__c updateTicketPriority(String ticketId, String priority) {
    try {
        Ticket__c existing = findTicketById(ticketId);   // ← redundant DB call
        existing.Priority__c = priority;
        return updateTicket(existing);
    } catch (Exception ex) {
        throw new ServiceException('Error updating ticket priority: ' + ex.getMessage());
    }
}
```

**After** — service receives the already-fetched object, no query needed:

```apex
// TicketService.cls — AFTER

public static Ticket__c updateTicketPriority(Ticket__c existing, String priority) {
    try {
        existing.Priority__c = priority;   // ← object is already here, no fetch
        return updateTicket(existing);
    } catch (Exception ex) {
        throw new ServiceException('Error updating ticket priority: ' + ex.getMessage());
    }
}
```

**3. Domain validators check the object in memory, not the database**

`DomainCompleteValidator` methods receive the already-fetched object.
They validate against its fields directly — no SOQL needed.

```apex
// DomainCompleteValidator.cls — AFTER

public static ProjectMember__c requireCurrentUserMemberForProject(ProjectMember__c member, String userId) {
    if (member == null || member.User__c != userId) {
        throw new ServiceException('User ' + userId + ' is not an active member of this project');
    }
    return member;   // ← pure in-memory check, zero DB calls
}
```

Notice that `DomainCompleteValidator` never touches the database.
The responsibility of fetching the object belongs to whoever needs it — in this case the service —
and the validator simply receives the result and checks its fields.

The following real example shows this pattern in full.
The service owns the SOQL, builds the object, then passes it into the validator:

```apex
// TicketService.cls

public static Ticket__c createTicket(Ticket__c ticket) {
    try {
        TicketType__c ticketType = getTicketTypeById(ticket.Ticket_Type__c);
        String projectId = ticketType.Project__c;

        if (String.isBlank(ticket.Creator__c)) {
            String userId = UserInfo.getUserId();

            // Service owns the SOQL — fetches the member record
            List<ProjectMember__c> rows = [
                SELECT Id, User__c, Project__c, RecordStatus__c
                FROM ProjectMember__c
                WHERE User__c = :userId AND Project__c = :projectId AND RecordStatus__c != 'delete'
                LIMIT 1
            ];
            ProjectMember__c creator = rows.isEmpty() ? null : rows[0];

            // Passes the object to the validator — no DB call inside the validator
            DomainCompleteValidator.requireCurrentUserMemberForProject(creator, userId);

            ticket.Creator__c = creator.Id;
        }

        if (String.isBlank(ticket.Priority__c)) ticket.Priority__c = 'Medium';

        if (String.isBlank(ticket.CurrentState__c)) {
            ticket.CurrentState__c = getTodoStatus(projectId).Id;
        } else {
            List<Status__c> existing = [SELECT Id FROM Status__c WHERE Id = :ticket.CurrentState__c LIMIT 1];
            if (existing.isEmpty()) {
                ticket.CurrentState__c = getTodoStatus(projectId).Id;
            }
        }

        ticket.RecordStatus__c = 'active';
        insert ticket;
        return ticket;
    } catch (DmlException dex) {
        throw new ServiceException('DML error creating ticket: ' + dex.getMessage());
    } catch (Exception ex) {
        throw new ServiceException('Error creating ticket: ' + ex.getMessage());
    }
}
```

The split is clear:
- **Service** — knows what to query, when, and why. Owns all SOQL.
- **Validator** — knows the rules. Receives data, checks fields, throws if invalid. Never queries.

---

**The new call flow:**

```
Controller
  |__ [1] Input validation
  |
  |__ [2] DomainCorrectnessValidator
  |         |__ checkTicketExist(ticketId)
  |               |__ SELECT ... WHERE Id = ticketId   ← retrieves object ONCE
  |               |__ returns Ticket__c object
  |
  |__ [3] TicketService(ticket, ...)                   ← receives the object, not the ID
                |__ DomainCompleteValidator.validateTicketOfTypeTask(ticket)
                          |__ checks ticket.Type__c    ← in memory, no DB call
```

---

**Summary of the three rules:**

| Rule | Before | After |
|---|---|---|
| Correctness return value | void — object discarded | returns the fetched object |
| Service input | receives Id, queries again | receives the object directly |
| DomainCompleteValidator | queries DB per check | validates in memory from the object |

**Why this works:**
- The object is retrieved exactly once per request — inside the correctness check, where it was already being fetched
- Services and validators operate on memory — no hidden SOQL inside validation methods
- The controller remains the single coordination point: validate, fetch, pass, execute
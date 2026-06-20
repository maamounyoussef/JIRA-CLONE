# SDD — Global: Jira Clone

**Document type:** Software Design Document (Global / Project-wide)
**Platform:** Salesforce — Lightning Web Components front end + Apex `@AuraEnabled` back end, persisting to custom objects (`*__c`).
**Scope:** This document covers the two project-wide design layers only:

1. **Architecture Design** — how the layers (LWC ↔ Apex ↔ domain ↔ data) are structured and how they communicate. Derived from [apex-path-architecture-guide](../force-app/skills/development/task-skill/guide/apex-path-architecture-guide.md) and [lwc-path-architecture-guide](../force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md).
2. **Data Design** — the data model (custom objects, fields, relationships) as defined under [force-app/main/default/objects/](../force-app/main/default/objects/).

Feature-specific designs (functions, screens, UI/UX states) live in their own function-specific SDDs (e.g. [manage-backlog-sdd.md](manage-backlog-sdd.md)).

---

## 1. Architecture Design

### 1.1 Layered overview

Every request flows in one direction — from a smart LWC page, through a thin Apex
controller, into a domain service that owns the data — and returns as a single
wrapped `APIResponse` envelope. No layer reaches around the one beneath it.

```
┌────────────────────────────────────────────────────────────────────────┐
│  LWC LAYER                                                               │
│                                                                          │
│   PAGE component (smart)              CHILD components (presentation)    │
│   - owns principal state              - receive data via @api           │
│   - calls Apex (imperative / @wire)   - own local presentation state    │
│   - handles child events              - dispatch CustomEvents up         │
│   - sidecars: <feature>Utils.js,      - NEVER call Apex                  │
│     <feature>Validator.js             - NEVER mutate @api                │
└───────────────┬──────────────────────────────────────────────────────────┘
                │ import <method> from '@salesforce/apex/<Controller>.<method>'
                ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  APEX LAYER                                                                │
│                                                                            │
│   controller/<feature>/<Name>Controller.cls   (thin, @AuraEnabled)        │
│     • returns APIResponse(success, message, data) ALWAYS                  │
│     • wraps everything in try/catch                                        │
│     • validates preconditions via DomainCorrectness.requireXExists()       │
│     • delegates business logic to a Service                                │
│                          │                                                 │
│                          ▼                                                 │
│   domain/<Name>Service.cls      (business logic + SOQL/DML, one per object)│
│     • throws ServiceException on failure                                   │
│   domain/DomainCorrectness.cls  (existence / precondition guards)          │
│   domain/<Name>Dto.cls          (composite / nested response shapes)       │
│                                                                            │
│   shared/APIResponse.cls        (the response envelope)                    │
│   shared/ServiceException.cls   (the only exception services throw)        │
│   shared/<...>Enum/Util/Constants.cls                                      │
└───────────────┬──────────────────────────────────────────────────────────┘
                │ SOQL / DML (each service against its OWN object only)
                ▼
                DATA LAYER  (custom objects — see §2)
```

### 1.2 LWC layer

| Concern | Rule |
|---------|------|
| **Page (smart) component** | Owns the **principal state**, calls Apex (imperative or `@wire`), handles events bubbled from children, and orchestrates the screen. One per feature (e.g. `manageBacklog`). |
| **Child (presentation) component** | Receives data via `@api`, owns only local presentation state, and communicates upward by dispatching `CustomEvent`s. **Never** calls Apex and **never** mutates an `@api` value. |
| **Derived state** | The page holds exactly one principal (non-structural) state; every UI value is a **getter derived from it**, never a parallel tracked field kept in sync by hand. |
| **Sidecars** | Pure logic lives beside the bundle in `<feature>Utils.js` (formatting/mapping helpers) and `<feature>Validator.js` (client-side input validation). |

**Naming & folder conventions**

- LWC bundle folder = camelCase feature name (`manageBacklog`); referenced in markup as `c-manage-backlog`.
- Event names: lowercase, no camelCase, no hyphens (`ticketsummaryupdate`).
- Presentation/local state fields are `_`-prefixed and bound through getters.

### 1.3 Apex layer

**Controller — `classes/controller/<feature>/<Name>Controller.cls`**
- Thin orchestration only. Every public method is `@AuraEnabled` (`@AuraEnabled(cacheable=true)` for pure reads used by `@wire`).
- ALWAYS returns `APIResponse`: `new APIResponse(true, 'msg', data)` on success, `new APIResponse(false, 'msg')` on failure.
- Wraps the body in `try/catch`; on `Exception ex` returns `new APIResponse(false, 'Error …: ' + ex.getMessage())`.
- Guards inputs (`String.isBlank(...)`) then asserts referenced records exist via `DomainCorrectness.requireXExists(id)`.
- Delegates real work to a Service — no business SOQL/DML in the controller.

**Service — `classes/domain/<Name>Service.cls`**
- `public with sharing`. Holds the SOQL/DML and business rules. Static methods named for the use case (`createStatus`, `loadStatuses`, `findStatus`).
- Throws `ServiceException` (never a bare `Exception`).
- **A service only queries/DMLs its OWN object.** Cross-domain reads are routed through the owning service — e.g. `TicketService` calls `SprintService.findSprintById(id)` rather than writing `[SELECT … FROM Sprint__c]` itself. This keeps every object's SOQL/DML in exactly one place.

**Guards — `classes/domain/DomainCorrectness.cls`**
- `requireXExists(id)` returns the record or throws `ServiceException`; `requireOptionalXExists(id)` no-ops on blank, else asserts. A new `requireXExists` is added here when a new object is introduced.

**DTOs — `classes/domain/<Name>Dto.cls`**
- Used when a response is a composite/nested shape (not a single SObject), with `@AuraEnabled` properties matching the client shape the LWC expects.

**Shared — `classes/guide/` & `classes/shared/`**
- `APIResponse` (envelope), `ServiceException` (the only thrown type), plus shared enums/utils/constants — never duplicated per feature.

### 1.4 Validation layering

Validation responsibility is split by layer so each rule has one home:

| Layer | Responsibility |
|-------|----------------|
| **LWC `<feature>Validator.js`** | Client-side input correctness for fast UX feedback (required, format, allowed values). |
| **Apex Controller** | Input correctness on the server (blank checks) + existence guards via `DomainCorrectness`. |
| **Apex Service** | Business validation — each business rule is one named method in the domain validator. |

### 1.5 Request / response envelope

Every Apex method returns the standard envelope; the LWC reads `success` to branch
and `data` for the payload:

```jsonc
{
  "success": <boolean>,
  "message": <string>,
  "data":    <object | array | null>
}
```

### 1.6 Cross-cutting rules

- **Bulkification** — any Apex that reads/updates more than one record runs the bulk-safe shape (one query per object into a `Map<Id, SObject>`, in-memory validation, one DML per object after the loop), so SOQL/DML counts stay flat as input grows.
- **Soft-delete filtering** — objects carrying `RecordStatus__c` are queried with a `WHERE` clause that excludes soft-deleted rows; deletes are soft deletes (set `RecordStatus__c`), not physical `delete` DML.

---

## 2. Data Design

The data model is rooted at **`Project__c`**. Project-scoped configuration
(members, statuses, workflows, ticket types, epics, sprints, name sequences) hangs
off the project; work items (`Ticket__c`, `Subtask__c`) reference that
configuration; and link objects (`EpicLink__c`, `TicketLink__c`) and the workflow
rule chain (`WorkflowTransition__c`, `ValidationRule__c`) connect them.

### 2.1 Entity relationship overview

```
                                 ┌─────────────┐
                                 │  Project__c │ (root)
                                 └──────┬──────┘
        ┌───────────┬──────────┬────────┼────────────┬───────────┬─────────────┐
        ▼           ▼          ▼         ▼            ▼           ▼             ▼
 ProjectMember  Status__c  Workflow  TicketType   Epic__c    Sprint__c   NameSequence
   __c            │         __c        __c          │          │            __c
     │            │          │          │           │          │
     │            │          │   (Workflow__c)      │          │
     │            │          ▼          │           │          │
     │            │   WorkflowTransition │          │          │
     │            │      __c             │          │          │
     │            │  (From/ToStatus__c)  │          │          │
     │            │          │           │          │          │
     │            │          ▼           │          │          │
     │            │   ValidationRule__c  │          │          │
     │            │                      │          │          │
     └──────┐     └──────────┐    ┌──────┘          │          │
            ▼ (Assigned/     ▼    ▼ (Ticket_Type__c)│          │
              Creator)  (CurrentState__c)           │          │
                       ┌──────────────┐  (Epic__c)  │ (Sprint__c)
                       │   Ticket__c   │◄────────────┘◄─────────┘
                       └──────┬────────┘
              ┌───────────────┼──────────────────┐
              ▼               ▼                   ▼
        Subtask__c       EpicLink__c         TicketLink__c
   (Ticket__c,          (Epic__c,           (LinkedFromTicket__c,
    Assignee__c,         Ticket__c)          LinkedToTicket__c)
    CurrentState__c)
```

All relationships are **Lookup** relationships. `User` is the standard Salesforce
User object; every other reference target is a custom object.

### 2.2 Object catalogue

The 14 custom objects, grouped by role:

| Group | Objects |
|-------|---------|
| **Root** | `Project__c` |
| **Project configuration** | `ProjectMember__c`, `Status__c`, `Workflow__c`, `WorkflowTransition__c`, `ValidationRule__c`, `TicketType__c`, `NameSequence__c` |
| **Planning** | `Epic__c`, `Sprint__c` |
| **Work items** | `Ticket__c`, `Subtask__c` |
| **Links** | `EpicLink__c`, `TicketLink__c` |

### 2.3 Field reference

> `req` = required. Lookup targets are shown in the **References** column. Fields
> named `RecordStatus__c` are the **soft-delete marker** (see §2.4).

#### Project__c — root
| Field | Type | Req | References |
|-------|------|:---:|------------|
| BacklogMaxScore__c | Text | – | |

#### ProjectMember__c — a User's membership/role in a project
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| User__c | Lookup | – | User (standard) |
| Role__c | Picklist | – | |
| RecordStatus__c | Text | – | |

#### Status__c — a workflow status within a project
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| isStart__c | Checkbox | – | |
| isEnd__c | Checkbox | – | |

#### Workflow__c — a workflow belonging to a project
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| RecordStatus__c | Text | ✔ | |

#### WorkflowTransition__c — an allowed status transition within a workflow
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Workflow__c | Lookup | ✔ | Workflow__c |
| FromStatus__c | Lookup | ✔ | Status__c |
| ToStatus__c | Lookup | ✔ | Status__c |
| RecordStatus__c | Text | ✔ | |

#### ValidationRule__c — a rule gating a workflow transition
| Field | Type | Req | References |
|-------|------|:---:|------------|
| WorkflowTransition__c | Lookup | ✔ | WorkflowTransition__c |
| TicketField__c | Text | ✔ | |
| Type__c | Picklist | ✔ | |
| RecordStatus__c | Text | ✔ | |

#### TicketType__c — a ticket type bound to a workflow
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| Workflow__c | Lookup | ✔ | Workflow__c |
| Description__c | TextArea | ✔ | |
| IconUrl__c | Text | ✔ | |
| RecordStatus__c | TextArea | ✔ | |

#### NameSequence__c — per-project name/number sequence counters
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| SprintLastSequence__c | Number | ✔ | |
| TicketLastSequence__c | Number | ✔ | |
| SubtaskLastSequence__c | Number | ✔ | |

#### Epic__c — a project epic
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| Summary__c | Text | ✔ | |
| Description__c | TextArea | – | |
| StartDate__c | DateTime | – | |
| EndDate__c | DateTime | – | |
| CreatedAt__c | DateTime | ✔ | |
| UpdatedAt__c | DateTime | ✔ | |

#### Sprint__c — a project sprint
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Project__c | Lookup | ✔ | Project__c |
| Duration__c | Number | ✔ | |
| Goal__c | TextArea | ✔ | |
| StartDate__c | Date | – | |
| MaxScore__c | Text | – | |
| TotalStoryPoint__c | Number | – | |
| TotalEndedStoryPoint__c | Number | – | |
| RecordStatus__c | Text | ✔ | |

#### Ticket__c — a work item
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Summary__c | Text | ✔ | |
| Description__c | TextArea | ✔ | |
| Ticket_Type__c | Lookup | ✔ | TicketType__c |
| CurrentState__c | Lookup | ✔ | Status__c |
| Creator__c | Lookup | ✔ | ProjectMember__c |
| AssignedTo__c | Lookup | – | ProjectMember__c |
| Epic__c | Lookup | – | Epic__c |
| Sprint__c | Lookup | – | Sprint__c |
| Priority__c | Picklist | ✔ | |
| Score__c | Text | ✔ | |
| StoryPoint__c | Number | – | |
| StartDate__c | DateTime | – | |
| EndDate__c | DateTime | – | |
| RecordStatus__c | Text | ✔ | |

#### Subtask__c — a sub-item of a ticket
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Ticket__c | Lookup | ✔ | Ticket__c |
| Summary__c | Text | ✔ | |
| Description__c | TextArea | – | |
| Assignee__c | Lookup | – | ProjectMember__c |
| CurrentState__c | Lookup | – | Status__c |
| StoryPoint__c | Number | – | |
| StartDate__c | DateTime | – | |
| RecordStatus__c | Text | – | |

#### EpicLink__c — links a ticket to an epic
| Field | Type | Req | References |
|-------|------|:---:|------------|
| Epic__c | Lookup | ✔ | Epic__c |
| Ticket__c | Lookup | ✔ | Ticket__c |
| Type__c | Text | ✔ | |
| IsActive__c | Checkbox | – | |

#### TicketLink__c — links one ticket to another
| Field | Type | Req | References |
|-------|------|:---:|------------|
| LinkedFromTicket__c | Lookup | ✔ | Ticket__c |
| LinkedToTicket__c | Lookup | ✔ | Ticket__c |
| Type__c | Picklist | ✔ | |
| RecordStatus__c | Text | ✔ | |

### 2.4 Soft-delete (`RecordStatus__c`)

The following objects carry a `RecordStatus__c` field and participate in the
project-wide soft-delete convention — rows are retired by setting
`RecordStatus__c` rather than being physically deleted, and every SOQL query
against them must exclude soft-deleted rows in its `WHERE` clause:

`ProjectMember__c`, `Workflow__c`, `WorkflowTransition__c`, `ValidationRule__c`,
`TicketType__c`, `Sprint__c`, `Ticket__c`, `Subtask__c`, `TicketLink__c`.

Objects **without** `RecordStatus__c` (`Project__c`, `Status__c`, `Epic__c`,
`EpicLink__c`, `NameSequence__c`) are not subject to the soft-delete filter.

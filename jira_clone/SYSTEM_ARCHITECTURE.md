# Jira Clone — System Architecture

Module architecture derived from `force-app/main/default/**`. The app is a layered
Salesforce application:

```
LWC (UI)  →  Apex Controllers (@AuraEnabled API)  →  Domain Services  →  Custom Objects (data)
```

Cross-cutting concerns (shared kernel, DTOs, validators, triggers) sit beside these layers.
Two architectural rules drive the design (see [project memory](#conventions)):

- **One controller per page** — each LWC page talks to exactly one Apex controller.
- **Service isolation** — each domain service SOQL/DMLs **only its own object**; any
  cross-object read/write goes *through the owning service* (e.g. `TicketService` never
  queries `Sprint__c`; it calls `SprintService`).

---

## 1. Layered architecture (high level)

```mermaid
flowchart TD
    subgraph UI["🖥️ Presentation — LWC"]
        PAGES["Page components<br/>(one per route)"]
        WIDGETS["Domain widgets<br/>(ticket board, modals…)"]
        DS["Design system<br/>(ao-* primitives)"]
    end

    subgraph API["⚙️ API — Apex Controllers (@AuraEnabled)"]
        CTRL["7 page controllers<br/>+ InputSecurityValidator"]
    end

    subgraph DOMAIN["🧠 Domain — Services & Validators"]
        SVC["9 domain services"]
        VAL["DomainCorrectness<br/>DomainCompleteValidator"]
    end

    subgraph TRIG["🔁 Triggers"]
        TR["ProjectTrigger → Handler<br/>StatusTrigger → Handler"]
    end

    subgraph SHARED["📦 Shared kernel"]
        SH["APIResponse · ServiceException<br/>TicketFieldEnum/Util · WorkflowConstants<br/>DTOs"]
    end

    subgraph DATA["🗄️ Data — 15 Custom Objects (*__c) + User"]
        OBJ[("Project__c · Ticket__c · Sprint__c<br/>Workflow__c · Status__c · …")]
    end

    PAGES --> CTRL
    WIDGETS --> CTRL
    PAGES --> WIDGETS
    WIDGETS --> DS
    PAGES --> DS

    CTRL --> SVC
    CTRL -.uses.-> VAL
    CTRL -.wraps result in.-> SH
    SVC --> VAL
    SVC --> OBJ
    TR --> OBJ
    SVC -.uses.-> SH
    VAL -.uses.-> SH

    classDef ui fill:#e3f2fd,stroke:#1976d2,color:#0d47a1;
    classDef api fill:#ede7f6,stroke:#5e35b1,color:#311b92;
    classDef dom fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20;
    classDef sh fill:#fff8e1,stroke:#f9a825,color:#e65100;
    classDef dat fill:#fce4ec,stroke:#c2185b,color:#880e4f;
    class PAGES,WIDGETS,DS ui;
    class CTRL api;
    class SVC,VAL,TR,TR dom;
    class SH sh;
    class OBJ dat;
```

---

## 2. Feature modules (page → controller → services → objects)

Each row is one self-contained feature. The controller is the only entry point the LWC
page calls; it fans out to the domain services it needs.

```mermaid
flowchart LR
    %% ---- Pages ----
    P_CHOOSE["chooseProject"]:::ui
    P_BACKLOG["manageBacklog"]:::ui
    P_TRACK["manageTicketTracking"]:::ui
    P_WF["manageWorkflow"]:::ui
    P_TT["manageTicketType"]:::ui
    P_PM["manageProjectMember"]:::ui
    P_REP["reportPage"]:::ui

    %% ---- Controllers ----
    C_SPLASH["ProjectSplashController"]:::api
    C_BACKLOG["ManageBacklogController"]:::api
    C_TRACK["ManageTicketTrackingController"]:::api
    C_WF["ManageWorkflowPageController"]:::api
    C_TT["ManageTicketTypeController"]:::api
    C_PM["ManageProjectMemberController"]:::api
    C_REP["ReportController"]:::api

    %% ---- Services ----
    S_PROJ["ProjectService"]:::dom
    S_TICKET["TicketService"]:::dom
    S_SPRINT["SprintService"]:::dom
    S_STATUS["StatusService"]:::dom
    S_WF["WorkflowService"]:::dom
    S_EPIC["EpicService"]:::dom
    S_VF["ValidateFieldService"]:::dom
    S_USER["UserService"]:::dom

    %% page -> controller
    P_CHOOSE --> C_SPLASH
    P_BACKLOG --> C_BACKLOG
    P_TRACK --> C_TRACK
    P_WF --> C_WF
    P_TT --> C_TT
    P_PM --> C_PM
    P_REP --> C_REP

    %% controller -> services
    C_SPLASH --> S_PROJ

    C_BACKLOG --> S_PROJ
    C_BACKLOG --> S_TICKET
    C_BACKLOG --> S_SPRINT
    C_BACKLOG --> S_STATUS
    C_BACKLOG --> S_EPIC
    C_BACKLOG --> S_WF
    C_BACKLOG --> S_USER

    C_TRACK --> S_TICKET
    C_TRACK --> S_SPRINT
    C_TRACK --> S_STATUS
    C_TRACK --> S_WF
    C_TRACK --> S_PROJ

    C_WF --> S_WF
    C_WF --> S_STATUS
    C_WF --> S_VF

    C_TT --> S_TICKET
    C_TT --> S_WF
    C_TT --> S_PROJ

    C_PM --> S_PROJ

    C_REP -->|"mock/in-memory<br/>burndown data"| C_REP

    classDef ui fill:#e3f2fd,stroke:#1976d2,color:#0d47a1;
    classDef api fill:#ede7f6,stroke:#5e35b1,color:#311b92;
    classDef dom fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20;
```

> **Note:** `ReportController` currently builds the burndown chart from hard-coded
> in-memory history rows (no service / SOQL yet) — it's the one controller without a
> service dependency.

---

## 3. Domain service dependency graph

Services collaborate **only** through other services (never by querying a foreign
object). Validators are shared by all services.

```mermaid
flowchart TD
    S_TICKET["TicketService<br/><i>Ticket__c · Subtask__c<br/>TicketType__c · TicketComment__c · TicketLink__c</i>"]:::dom
    S_SPRINT["SprintService<br/><i>Sprint__c</i>"]:::dom
    S_PROJ["ProjectService<br/><i>Project__c · ProjectMember__c</i>"]:::dom
    S_STATUS["StatusService<br/><i>Status__c</i>"]:::dom
    S_WF["WorkflowService<br/><i>Workflow__c · WorkflowTransition__c</i>"]:::dom
    S_VF["ValidateFieldService<br/><i>ValidateField__c</i>"]:::dom
    S_EPIC["EpicService<br/><i>Epic__c · EpicLink__c</i>"]:::dom
    S_NAME["NameSequenceService<br/><i>NameSequence__c</i>"]:::dom
    S_USER["UserService<br/><i>User</i>"]:::dom

    VAL["DomainCompleteValidator<br/>DomainCorrectness"]:::val

    S_TICKET --> S_SPRINT
    S_TICKET --> S_STATUS
    S_TICKET --> S_PROJ
    S_TICKET --> S_VF
    S_TICKET --> S_NAME

    S_SPRINT --> S_TICKET
    S_SPRINT --> S_NAME

    S_PROJ --> S_NAME

    S_TICKET -.-> VAL
    S_SPRINT -.-> VAL
    S_WF -.-> VAL
    S_VF -.-> VAL
    S_PROJ -.-> VAL

    classDef dom fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20;
    classDef val fill:#fff3e0,stroke:#ef6c00,color:#e65100;
```

> `SprintService` and `TicketService` call each other (sprint completion clears tickets;
> ticket state changes roll story points up to the sprint) — the only bidirectional pair.

---

## 4. LWC component breakdown

```mermaid
flowchart TD
    subgraph PAGES["Page components (route-level)"]
        chooseProject
        manageBacklog
        manageTicketTracking
        manageWorkflow
        manageTicketType
        manageProjectMember
        reportPage
    end

    subgraph WIDGETS["Domain widgets (reused across pages)"]
        aoTicketItem
        aoCreateTicketModal
        ticketBoardColumn
        ticketView
        ticketLinkedTo
        autoCompleteComboBox
        projectSelector
        projectMember
        project
    end

    subgraph DS["Design system — ao-* primitives"]
        aoBtn
        aoInput
        aoCombobox
        aoCheckbox
        aoSpinner
        aoCardButton
    end

    PAGES --> WIDGETS
    PAGES --> DS
    WIDGETS --> DS

    classDef ui fill:#e3f2fd,stroke:#1976d2,color:#0d47a1;
    class chooseProject,manageBacklog,manageTicketTracking,manageWorkflow,manageTicketType,manageProjectMember,reportPage,aoTicketItem,aoCreateTicketModal,ticketBoardColumn,ticketView,ticketLinkedTo,autoCompleteComboBox,projectSelector,projectMember,project,aoBtn,aoInput,aoCombobox,aoCheckbox,aoSpinner,aoCardButton ui;
```

Each page bundles its own co-located `*Validator.js` / `*Utils.js` helpers
(e.g. `backlogTicketValidator.js`, `workflowUtils.js`) for client-side validation and
view-model derivation — keeping business rules out of the templates.

---

## 5. Module inventory

| Layer | Module | Responsibility |
|---|---|---|
| **UI – pages** | `chooseProject` | Project picker / splash |
| | `manageBacklog` | Backlog, sprints, epics, ticket CRUD |
| | `manageTicketTracking` | Active-sprint board & ticket workflow |
| | `manageWorkflow` | Workflow / transition / validation-rule editor |
| | `manageTicketType` | Ticket-type config + workflow binding |
| | `manageProjectMember` | Project membership & roles |
| | `reportPage` | Burndown / reporting |
| **UI – widgets** | `aoTicketItem`, `aoCreateTicketModal`, `ticketBoardColumn`, `ticketView`, `ticketLinkedTo`, `autoCompleteComboBox`, `projectSelector`, `projectMember`, `project` | Reusable feature widgets |
| **UI – design system** | `aoBtn`, `aoInput`, `aoCombobox`, `aoCheckbox`, `aoSpinner`, `aoCardButton` | Branded UI primitives |
| **API** | `ProjectSplashController`, `ManageBacklogController`, `ManageTicketTrackingController`, `ManageWorkflowPageController`, `ManageTicketTypeController`, `ManageProjectMemberController`, `ReportController` | `@AuraEnabled` endpoints, one per page |
| | `InputSecurityValidator` | Cross-cutting input sanitization |
| **Domain** | `ProjectService`, `TicketService`, `SprintService`, `StatusService`, `WorkflowService`, `EpicService`, `ValidateFieldService`, `NameSequenceService`, `UserService` | Business logic + persistence, scoped to one object each |
| | `DomainCorrectness`, `DomainCompleteValidator` | Existence/input correctness vs. business-rule validation |
| **Triggers** | `ProjectTrigger`→`ProjectTriggerHandler`, `StatusTrigger`→`StatusTriggerHandler` | Record-level automation |
| **Shared** | `APIResponse`, `ServiceException`, `TicketFieldEnum`, `TicketFieldUtil`, `WorkflowConstants` | Kernel utilities |
| | `CreateTicketResponse`, `ChangeTicketStateDto`, `TicketLinkToDto`, `TicketCommentDto`, `TicketHistoryDto`, `WorkflowConfigDTO`, `ComparableHistoryRow` | Transport DTOs |
| **Data** | 15 `*__c` custom objects + standard `User` | See [ER_DIAGRAM.md](ER_DIAGRAM.md) |

---

## Conventions

- **`APIResponse`** is the uniform envelope every controller returns (`success`, `message`, `data`).
- **`ServiceException`** is thrown by services and translated to a failed `APIResponse` at the controller boundary.
- **Validators split by intent:** `DomainCorrectness` = "does this exist / is the input well-formed", `DomainCompleteValidator` = named business rules (one method per rule).
- See [ER_DIAGRAM.md](ER_DIAGRAM.md) for the full data model.

# Use Case Diagram — Manage Backlog

Source: [`ManageBacklogController.cls`](force-app/main/default/classes/controller/managebacklog/ManageBacklogController.cls)

This document models **all 49 endpoints** of the Manage Backlog controller as UML
use cases, grouped under `Manage …` parent use cases, with the four standard
relationships:

| Relationship | Notation | Meaning in this model |
|---|---|---|
| **Association** | `Actor --> UseCase` | The actor performs the use case. |
| **Generalization** | `Child --|> Parent` | The child is a *specialized kind of* the parent (e.g. *Create Ticket in Sprint* is a kind of *Create Ticket*). Hollow triangle points at the parent. |
| **«include»** | `Base ..> Sub : <<include>>` | The base use case **always** runs the sub use case (mandatory sub-behavior, e.g. an aggregate load, sprint recalculation, workflow validation). |
| **«extend»** | `Ext ..> Base : <<extend>>` | The extension runs **only under a condition** (optional field set, end-status reached). Arrow points at the base. |

**Rendering:** PlantUML blocks render in VS Code (PlantUML extension), IntelliJ, or
`plantuml`/Kroki export to `usecase-svg/`. A Mermaid overview is included first for
GitHub-native preview.

---

## Actor

There is a single human actor exposed by this controller — every method is an
`@AuraEnabled` action invoked from the Manage Backlog LWC on behalf of a signed-in
project user. (The controller does **not** branch on role — see *Notes* at the end.)

- **Project Member** — a user working the backlog board (create/edit/move/link
  tickets, run sprints, manage epics, subtasks, members).

Two internal *included* use cases are reused across the model and drawn as shared
nodes rather than repeated 40×:

- **Validate Entity Exists** — every write resolves its inputs through
  `DomainCorrectness.require*` before mutating.
- **Recalculate Sprint Rollup** — any operation that changes a ticket's sprint
  membership or completion returns the recomputed `updatedSprint`.

---

## Overview (Mermaid — GitHub preview)

```mermaid
flowchart LR
  U(["👤 Project Member"])

  MB["Manage Backlog"]
  U --> MB

  MB -. include .-> VBB["View Backlog Board"]
  MB -. include .-> MT["Manage Ticket"]
  MB -. include .-> MS["Manage Subtask"]
  MB -. include .-> MSP["Manage Sprint"]
  MB -. include .-> ME["Manage Epic"]
  MB -. include .-> MTT["Manage Ticket Type"]
  MB -. include .-> MP["Manage Project"]
  MB -. include .-> MM["Manage Member"]

  ST["Search Tickets"] -. extend .-> VBB
  LBT["Load Backlog Tickets (paged)"] -. extend .-> VBB
  LST["Load Sprint Tickets (paged)"] -. extend .-> VBB
```

---

## Diagram 0 — Context / Package Overview (PlantUML)

```plantuml
@startuml UC0_Overview
left to right direction
skinparam packageStyle rectangle
actor "Project Member" as U

usecase "Manage Backlog" as MB

usecase "View Backlog Board"   as VBB
usecase "Manage Ticket"        as MT
usecase "Manage Subtask"       as MS
usecase "Manage Sprint"        as MSP
usecase "Manage Epic"          as ME
usecase "Manage Ticket Type"   as MTT
usecase "Manage Project"       as MP
usecase "Manage Member"        as MM

U --> MB

MB ..> VBB : <<include>>
MB ..> MT  : <<include>>
MB ..> MS  : <<include>>
MB ..> MSP : <<include>>
MB ..> ME  : <<include>>
MB ..> MTT : <<include>>
MB ..> MP  : <<include>>
MB ..> MM  : <<include>>

usecase "Validate Entity Exists" as VE
usecase "Recalculate Sprint Rollup" as RS
note bottom of VE
  Shared <<include>> — pulled in by every
  write use case (DomainCorrectness.require*).
end note
note bottom of RS
  Shared <<include>> — pulled in whenever a
  ticket's sprint membership/completion changes.
end note
@enduml
```

---

## Diagram 1 — View Backlog Board  *(page bootstrap)*

`loadBacklogData` is one call that aggregates seven sub-loads → all «include».
Search and paged loads are optional refinements of the board → «extend».

```plantuml
@startuml UC1_Board
left to right direction
actor "Project Member" as U

usecase "View Backlog Board" as VBB
usecase "Load Sprints"         as L1
usecase "Load Statuses"        as L2
usecase "Load Ticket Types"    as L3
usecase "Load Members"         as L4
usecase "Load Epics"           as L5
usecase "Load Backlog Tickets" as L6
usecase "Load Priority Options" as L7

usecase "Search Tickets"               as ST
usecase "Load Backlog Tickets (paged)" as LBT
usecase "Load Sprint Tickets (paged)"  as LST

U --> VBB
U --> ST

VBB ..> L1 : <<include>>
VBB ..> L2 : <<include>>
VBB ..> L3 : <<include>>
VBB ..> L4 : <<include>>
VBB ..> L5 : <<include>>
VBB ..> L6 : <<include>>
VBB ..> L7 : <<include>>

ST  ..> VBB : <<extend>>
LBT ..> VBB : <<extend>>
LST ..> VBB : <<extend>>
@enduml
```

---

## Diagram 2 — Manage Ticket  *(the core domain)*

Two-level generalization: `Create / Edit / Move / Delete Ticket` are kinds of
*Manage Ticket*, and each concrete operation is a kind of its parent. Sprint
side-effects and workflow checks are «include»; optional fields and end-status
handling are «extend».

```plantuml
@startuml UC2_Ticket
left to right direction
skinparam packageStyle rectangle
actor "Project Member" as U

usecase "Manage Ticket" as MT

' ---- Create branch ----
usecase "Create Ticket"            as C
usecase "Create Ticket in Backlog" as C1
usecase "Create Ticket in Sprint"  as C2
usecase "Set Epic (optional)"      as CE
usecase "Set Assignee (optional)"  as CA
usecase "Set Priority (optional)"  as CP

' ---- Edit branch ----
usecase "Edit Ticket"          as E
usecase "Update Ticket Details" as E1
usecase "Update Summary"        as E2
usecase "Update Description"    as E3
usecase "Update Priority"       as E4
usecase "Assign Member"         as E5
usecase "Update Epic"           as E6

' ---- Move branch ----
usecase "Move Ticket"      as M
usecase "Move to Sprint"   as M1
usecase "Move to Backlog"  as M2
usecase "Reorder Position" as M3

' ---- Delete branch ----
usecase "Delete Ticket"           as D
usecase "Delete Single Ticket"    as D1
usecase "Delete Multiple Tickets" as D2

' ---- Standalone ----
usecase "Change Ticket State" as CS
usecase "Link Ticket"         as LK
usecase "View Ticket Details" as V
usecase "Add Comment"         as AC

' ---- Sub / detail loads ----
usecase "Load Link Types"       as LT
usecase "View Linked Tickets"   as VL
usecase "View Ticket History"   as VH
usecase "View Ticket Comments"  as VC
usecase "View Subtasks"         as VS

' ---- Shared ----
usecase "Validate Entity Exists"     as VE
usecase "Validate Workflow Transition" as VW
usecase "Recalculate Sprint Rollup"  as RS
usecase "Handle End Status"          as ES

U --> MT

C  --|> MT
E  --|> MT
M  --|> MT
D  --|> MT
CS --|> MT
LK --|> MT
V  --|> MT
AC --|> MT

C1 --|> C
C2 --|> C
E1 --|> E
E2 --|> E
E3 --|> E
E4 --|> E
E5 --|> E
E6 --|> E
M1 --|> M
M2 --|> M
M3 --|> M
D1 --|> D
D2 --|> D

' optional field extensions on create
CE ..> C : <<extend>>
CA ..> C : <<extend>>
CP ..> C : <<extend>>

' mandatory sub-behaviors
C2 ..> RS : <<include>>
M1 ..> RS : <<include>>
M2 ..> RS : <<include>>
D1 ..> RS : <<include>>
D2 ..> RS : <<include>>
CS ..> VW : <<include>>
ES ..> CS : <<extend>>
ES ..> RS : <<include>>

LK ..> LT : <<include>>
V  ..> VL : <<include>>
V  ..> VH : <<include>>
V  ..> VC : <<include>>
V  ..> VS : <<include>>

' representative validation includes (applies to every write)
C  ..> VE : <<include>>
E  ..> VE : <<include>>
M  ..> VE : <<include>>
D  ..> VE : <<include>>
CS ..> VE : <<include>>
LK ..> VE : <<include>>
E5 ..> VE : <<include>>
@enduml
```

---

## Diagram 3 — Manage Sprint  *(lifecycle)*

Pure generalization from the `Manage Sprint` parent; *Complete Sprint* recomputes
the rollup.

```plantuml
@startuml UC3_Sprint
left to right direction
actor "Project Member" as U

usecase "Manage Sprint"   as MSP
usecase "Create Sprint"   as S1
usecase "Update Sprint"   as S2
usecase "Start Sprint"    as S3
usecase "Complete Sprint" as S4
usecase "Delete Sprint"   as S5
usecase "Recalculate Sprint Rollup" as RS

U --> MSP
S1 --|> MSP
S2 --|> MSP
S3 --|> MSP
S4 --|> MSP
S5 --|> MSP
S4 ..> RS : <<include>>
@enduml
```

---

## Diagram 4 — Manage Epic

```plantuml
@startuml UC4_Epic
left to right direction
actor "Project Member" as U

usecase "Manage Epic"  as ME
usecase "Create Epic"  as E1
usecase "Update Epic"  as E2
usecase "View Epics"   as E3
usecase "View Epic"    as E4
usecase "Validate Epic" as VEP

U --> ME
E1 --|> ME
E2 --|> ME
E3 --|> ME
E4 --|> ME
E1 ..> VEP : <<include>>
@enduml
```

---

## Diagram 5 — Manage Subtask

`Update Subtask Summary` is a specialization of *Edit Subtask*; *Assign Subtask*
includes an active-member check.

```plantuml
@startuml UC5_Subtask
left to right direction
actor "Project Member" as U

usecase "Manage Subtask"        as MS
usecase "Create Subtask"        as T1
usecase "Edit Subtask"          as T2
usecase "Update Subtask"        as T2a
usecase "Update Subtask Summary" as T2b
usecase "Assign Subtask"        as T3
usecase "Delete Subtask"        as T4
usecase "Delete Subtasks"       as T5
usecase "View Subtasks"         as T6
usecase "Validate Member Active" as VM

U --> MS
T1 --|> MS
T2 --|> MS
T3 --|> MS
T4 --|> MS
T5 --|> MS
T6 --|> MS
T2a --|> T2
T2b --|> T2
T3 ..> VM : <<include>>
@enduml
```

---

## Diagram 6 — Manage Ticket Type

*Create Ticket Type* additionally includes a check that the chosen workflow
belongs to the project.

```plantuml
@startuml UC6_TicketType
left to right direction
actor "Project Member" as U

usecase "Manage Ticket Type" as MTT
usecase "Create Ticket Type" as TT1
usecase "View Ticket Types"  as TT2
usecase "View Ticket Type"   as TT3
usecase "Validate Workflow Belongs To Project" as VWP

U --> MTT
TT1 --|> MTT
TT2 --|> MTT
TT3 --|> MTT
TT1 ..> VWP : <<include>>
@enduml
```

---

## Diagram 7 — Manage Project & Manage Member

```plantuml
@startuml UC7_ProjectMember
left to right direction
actor "Project Member" as U

usecase "Manage Project"        as MP
usecase "Create Project"        as P1
usecase "View Projects"         as P2
usecase "View Project Statuses" as P3

usecase "Manage Member" as MM
usecase "Add Member"    as M1
usecase "View Members"  as M2
usecase "View Users"    as M3
usecase "Validate User Exists"    as VU
usecase "Validate Project Exists" as VP

U --> MP
P1 --|> MP
P2 --|> MP
P3 --|> MP

U --> MM
M1 --|> MM
M2 --|> MM
M3 --|> MM
M1 ..> VU : <<include>>
M1 ..> VP : <<include>>
@enduml
```

---

## Full Traceability — every endpoint → use case → relationships

| # | Controller method | Use case | Parent (generalization) | «include» | «extend» |
|---|---|---|---|---|---|
| 1 | `loadBacklogData` | View Backlog Board | — | Load Sprints, Statuses, Ticket Types, Members, Epics, Backlog Tickets, Priority Options | — |
| 2 | `loadTicketBySearchTerm` | Search Tickets | — | Validate Entity Exists | *extends* View Backlog Board |
| 3 | `linkToTicket` | Link Ticket | Manage Ticket | Validate Entity Exists (×4), Load Link Types | — |
| 4 | `loadProjects` | View Projects | Manage Project | — | — |
| 5 | `getProjectStatuses` | View Project Statuses | Manage Project | Validate Entity Exists | — |
| 6 | `createProject` | Create Project | Manage Project | — | — |
| 7 | `getEpicsByProject` | View Epics | Manage Epic | Validate Entity Exists | — |
| 8 | `getEpicById` | View Epic | Manage Epic | Validate Entity Exists | — |
| 9 | `createEpic` | Create Epic | Manage Epic | Validate Entity Exists, Validate Epic | — |
| 10 | `updateEpic` | Update Epic | Manage Epic | Validate Entity Exists | — |
| 11 | `createSprint` | Create Sprint | Manage Sprint | Validate Entity Exists | — |
| 12 | `updateSprint` | Update Sprint | Manage Sprint | Validate Entity Exists | — |
| 13 | `completeSprint` | Complete Sprint | Manage Sprint | Validate Entity Exists, Recalculate Sprint Rollup | — |
| 14 | `deleteSprint` | Delete Sprint | Manage Sprint | Validate Entity Exists | — |
| 15 | `startSprint` | Start Sprint | Manage Sprint | Validate Entity Exists | — |
| 16 | `loadBacklogTickets` | Load Backlog Tickets (paged) | — | Validate Entity Exists | *extends* View Backlog Board |
| 17 | `loadTicketsBySprint` | Load Sprint Tickets (paged) | — | Validate Entity Exists | *extends* View Backlog Board |
| 18 | `loadTicketTypes` | View Ticket Types | Manage Ticket Type | Validate Entity Exists | — |
| 19 | `getTicketTypeById` | View Ticket Type | Manage Ticket Type | Validate Entity Exists | — |
| 20 | `createTicketType` | Create Ticket Type | Manage Ticket Type | Validate Entity Exists, Validate Workflow Belongs To Project | — |
| 21 | `createTicketFromBacklog` | Create Ticket in Backlog | Create Ticket → Manage Ticket | Validate Entity Exists | Set Epic / Assignee / Priority (optional) |
| 22 | `createTicketFromSprint` | Create Ticket in Sprint | Create Ticket → Manage Ticket | Validate Entity Exists, Recalculate Sprint Rollup | Set Epic / Assignee / Priority (optional) |
| 23 | `updateTicket` | Update Ticket Details | Edit Ticket → Manage Ticket | Validate Entity Exists | — |
| 24 | `updateTicketSummary` | Update Summary | Edit Ticket → Manage Ticket | Validate Entity Exists | — |
| 25 | `updateTicketDescription` | Update Description | Edit Ticket → Manage Ticket | Validate Entity Exists | — |
| 26 | `loadTicketLinkedToType` | Load Link Types | Manage Ticket | — | — |
| 27 | `loadTicketLinkedTo` | View Linked Tickets | Manage Ticket | Validate Entity Exists | — |
| 28 | `updateTicketPriority` | Update Priority | Edit Ticket → Manage Ticket | Validate Entity Exists | — |
| 29 | `assignTicket` | Assign Member | Edit Ticket → Manage Ticket | Validate Entity Exists, Validate Member Active | — |
| 30 | `changeTicketState` | Change Ticket State | Manage Ticket | Validate Entity Exists, Validate Workflow Transition | Handle End Status → Recalculate Sprint Rollup |
| 31 | `moveTicketToSprint` | Move to Sprint | Move Ticket → Manage Ticket | Validate Entity Exists, Recalculate Sprint Rollup | — |
| 32 | `moveTicketPosition` | Reorder Position | Move Ticket → Manage Ticket | Validate Entity Exists | — |
| 33 | `moveTicketToBacklog` | Move to Backlog | Move Ticket → Manage Ticket | Validate Entity Exists, Recalculate Sprint Rollup | — |
| 34 | `deleteTicket` | Delete Single Ticket | Delete Ticket → Manage Ticket | Validate Entity Exists, Recalculate Sprint Rollup | — |
| 35 | `deleteTickets` | Delete Multiple Tickets | Delete Ticket → Manage Ticket | Validate Entity Exists (bulk), Recalculate Sprint Rollup | — |
| 36 | `loadSubtasks` | View Subtasks | Manage Subtask | Validate Entity Exists | — |
| 37 | `loadTicketHistory` | View Ticket History | Manage Ticket | Validate Entity Exists | — |
| 38 | `loadTicketComments` | View Ticket Comments | Manage Ticket | Validate Entity Exists | — |
| 39 | `createTicketComment` | Add Comment | Manage Ticket | Validate Entity Exists | — |
| 40 | `createSubtask` | Create Subtask | Manage Subtask | Validate Entity Exists | — |
| 41 | `updateSubtaskSummary` | Update Subtask Summary | Edit Subtask → Manage Subtask | Validate Entity Exists | — |
| 42 | `updateSubtask` | Update Subtask | Edit Subtask → Manage Subtask | Validate Entity Exists | — |
| 43 | `assignSubtask` | Assign Subtask | Manage Subtask | Validate Entity Exists, Validate Member Active | — |
| 44 | `deleteSubtask` | Delete Subtask | Manage Subtask | Validate Entity Exists | — |
| 45 | `deleteSubtasks` | Delete Subtasks | Manage Subtask | Validate Entity Exists | — |
| 46 | `createMember` | Add Member | Manage Member | Validate User Exists, Validate Project Exists | — |
| 47 | `loadMembers` | View Members | Manage Member | Validate Entity Exists | — |
| 48 | `updateTicketEpic` | Update Epic (ticket) | Edit Ticket → Manage Ticket | Validate Entity Exists | — |
| 49 | `loadUsers` | View Users | Manage Member | — | — |

---

## Modeling notes / caveats

1. **Single actor, no roles.** The controller never branches on user role, so the
   model has one actor (*Project Member*). If the product distinguishes
   Scrum Master vs. Developer permissions, split the actor and re-associate the
   sprint-lifecycle use cases (Start/Complete/Delete Sprint) to the privileged role.
2. **`Validate Entity Exists` is pervasive.** Almost every write «include»s a
   `DomainCorrectness.require*` check. It is drawn once as a shared use case; the
   traceability table lists it per endpoint even where the per-domain diagram omits
   the arrow for readability.
3. **Sprint rollup as «include» vs «extend».** `Change Ticket State` recalculates the
   sprint **only** when the target status is an end status, so that is modeled as an
   «extend» (*Handle End Status*). Where a sprint change is unconditional
   (create-in-sprint, move, delete), it is «include».
4. **Search is drawn as «extend»** of *View Backlog Board* because it is an optional
   refinement of the same board view, not a separate actor goal.
5. **Page-access authorization is currently disabled** in the controller
   (`InputSecurityValidator.validatePageAccessManageBacklog` is commented out at
   `ManageBacklogController.cls:11`). If re-enabled it becomes a shared «include»
   (*Authorize Page Access*) on `Manage Backlog` / *View Backlog Board*.

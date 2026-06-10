# SDD — Function Specific: Manage Backlog Page (corrected)

**Document type:** Software Design Document (Function-Specific)
**Scope:** Manage Backlog page — Sprints container, Backlog container, Ticket container, Sub-task container, Epic flow, Ticket View peek panel.
**Platform:** Salesforce — LWC front end (`manageBacklog`, `aoCreateTicketModal`, `aoTicketItem`, `ticketView`, `chooseProject`) + Apex `@AuraEnabled` controller **`ManageBacklogController`**.

> **Why "corrected":** this version was reconciled against the actual
> `manageBacklog` component (`manageBacklog.html`, `manageBacklog.js`,
> `backlogSprintValidator.js`, `backlogTicketValidator.js`,
> `backlogSprintUtils.js`, `backlogTicketUtils.js`). Method names, signatures,
> fields and UI behaviour that did not exist in the code have been removed or
> fixed. Differences from the original draft are listed in §7.

---

## 1. Conventions used in this document

### 1.1 Request / response envelope
Every Apex method returns the standard envelope:

```jsonc
{
  "success": <boolean>,
  "message": <string>,
  "data":    <object | array | null>
}
```

> **Project id note:** the project id is **read from `localStorage` (`projectId`)**
> in `connectedCallback`. If absent, the page renders `c-choose-project` and the
> chosen id is taken from its `projectchosen` event. It is never re-selected
> elsewhere on this page.

### 1.2 Shared UI/UX state model

| State | Description |
|-------|-------------|
| **G-LOCK** | The component-level `isLoading` flag raises a full-panel `lightning-spinner` overlay on the **Sprints** panel and disables submit handlers (create handlers early-return while `isLoading`). It is set during every mutating call and the data load. |
| **BACKLOG-SPINNER** | `backlogIsLoading` raises a localized spinner in the Backlog list during backlog pagination. |
| **SPRINT-SPINNER** | A sprint's `isLoadingTickets` raises a localized spinner in that sprint body during expand / sprint pagination. |
| **MODAL** | A modal overlay (`modal-backdrop` + `section.modal`) with its own form + footer buttons. Used for: sprint create/edit (in `manageBacklog`), ticket create (child `c-ao-create-ticket-modal`), epic create and subtask create (child `c-ao-ticket-item` / `c-ticket-view`). |
| **EDIT-2BTN** | Inline edit mode inside `c-ao-ticket-item` / `c-ticket-view`: an `X` (cancel) and a `✓` (confirm) button beside an editable input. |
| **CONFIRM** | The shared confirmation dialog in `manageBacklog` (`showConfirmDialog`, `confirmMessage`, `_pendingAction`) with **Cancel** / **Confirm** buttons. |
| **BULK-BAR** | A bar shown when `hasSelectedTickets` is true, with the selected count, **Delete Selected** and **Cancel** buttons. Tickets only. |
| **POPOVER** | A floating panel inside the child components (assignee picker, epic parent picker). |
| **PEEK** | The right-side `ticketView` panel (`peek-panel` + `peek-backdrop`) opened by `ticketviewopen`. |
| **TOAST-OK / TOAST-ERR** | `ShowToastEvent` success / error, via `_showSuccess` / `_showError`. |

### 1.3 Modal contract (as implemented)
1. On submit → **G-LOCK** (`isLoading = true`); create handlers early-return if already loading.
2. On **failure** → **TOAST-ERR**; the modal **stays open** with values preserved.
3. On **success** → **TOAST-OK**, the modal closes, the affected list re-renders from the returned record.
4. On **Cancel / Close** → the modal closes, no request sent.

> Note: the spinner shown during a submit is the **panel-level** `isLoading`
> overlay, not an in-modal spinner.

### 1.4 Load contract
The initial load and every mutation set `isLoading`. Backlog pagination uses the
localized `backlogIsLoading`; sprint expand / pagination uses the per-sprint
`isLoadingTickets`. Pagination is driven by `‹` / `›` (`PAGE_SIZE` from
`backlogSprintUtils`).

---

## 2. Page-load & data-retrieval functions

### 2.1 `loadBacklogData` — Initial page load
**Trigger:** `connectedCallback` (project id resolved) or `handleProjectChosen`.

**API call**
- Apex: `ManageBacklogController.loadBacklogData(String projectId)` — **`projectId` only** (no offset/pageSize on the initial load).
- Response `data`:
```jsonc
{
  "sprints":         [ <Sprint__c ...> ],
  "status":          [ { "Id","Name" }, ... ],
  "members":         [ { "Id","Name" }, ... ],
  "epics":           [ { "Id","Name" }, ... ],
  "ticketTypes":     [ { "Id","Name" }, ... ],
  "backlogTickets":  [ <Ticket__c ...> ],
  "priorityOptions": [ ... ]
}
```

**UI/UX**
- State: **G-LOCK**.
- The JS maps the payload into `sprints` (`formatSprint`), `statusOptions`,
  `memberOptions`, `ticketTypeOptions`, `epics`, `priorityOptions`, and
  `backlogTickets` (`enrichTickets`). `backlogHasMore` is set from
  `backlogTickets.length === PAGE_SIZE`.
- Sprints render collapsed; each header shows `Name`, `StartDate__c → endDate`,
  the `RecordStatus__c` badge and the buttons **Start** (hidden when complete),
  **Complete**, **Edit**, **Delete**, **+ Ticket**.

> **Members are loaded here, once.** There is **no** `getProjectMembers` call.
> `memberOptions` is passed to every `c-ao-ticket-item` as `member-options`; the
> assignee picker reads from that preloaded list.

### 2.2 `loadBacklogTickets` — Backlog pagination
**Trigger:** `handleBacklogPrevPage` / `handleBacklogNextPage` (`‹` / `›`).

**API call**
- `ManageBacklogController.loadBacklogTickets(String projectId, Integer offset, Integer pageSize)`.
- Response `data`: an **array** of backlog tickets. `backlogHasMore` is derived
  from `length === PAGE_SIZE`.

**UI/UX**
- State: **BACKLOG-SPINNER**. `backlogOffsetLabel` shows `Showing X–Y` (or
  `No tickets`).

### 2.3 `loadTicketsBySprint` — Expand a sprint / sprint pagination
**Trigger:** `handleToggle` (first expand) or `handleSprintPrevPage` / `handleSprintNextPage`.

**API call**
- `ManageBacklogController.loadTicketsBySprint(String sprintId, Integer offset, Integer pageSize)`.
- Response `data`: an **array** of the sprint's tickets. `hasMore` is derived
  from `length === PAGE_SIZE`.

**UI/UX**
- State: **SPRINT-SPINNER** (`isLoadingTickets`).
- The expanded body shows the sprint **goal** (`Goal__c`, when present), a
  **Story Points** progress bar (`TotalEndedStoryPoint__c / TotalStoryPoint__c`,
  `storyPointsPercent`%), the ticket rows, and a `Page n` footer with `‹` / `›`.
  Story-point totals come from the **sprint record fields**, not from this call's
  payload.

### 2.4 `loadSubtasks` — Expand a ticket (wired)
**Trigger:** `subtasksexpand` event → `handleTicketViewSubtasksExpand` sets
`_subtasksTargetTicketId`, which feeds the wired `loadSubtasks`.

**API call**
- `@wire ManageBacklogController.loadSubtasks({ ticketId })`.
- Response `data`: an array of subtasks, patched onto the ticket via
  `_patchTicketEverywhere(ticketId, { subtasks })`.

**UI/UX**
- State: **G-LOCK** while the wire resolves (`isLoading` cleared in the wire).

---

## 3. Ticket container functions

> The same `c-ao-ticket-item` renders in both the Backlog and each sprint, wired
> to the same parent handlers. Its display variant is `row` on wide screens and
> `full-ticket-card` on small screens (`ticketVariant`, driven by a
> `matchMedia('(max-width: 767px)')` listener).

### 3.1 `createTicketFromBacklog` — Create ticket (Backlog)
**Trigger:** **+ Ticket** in the Backlog header → `c-ao-create-ticket-modal` →
`ticketcreate` → `handleBacklogTicketCreate`.

**API call**
- `ManageBacklogController.createTicketFromBacklog(<modal payload>)` (passes the
  child event `detail` straight through).
- On success the returned ticket is run through `formatTicket` and appended via
  `_enrichBacklogWithTicket`.

### 3.2 `createTicketFromSprint` — Create ticket (Sprint)
**Trigger:** **+ Ticket** on a sprint header → `handleSprintAddTicket` (sets
`_activeSprintId`) → modal → `handleSprintTicketCreate`.

**API call**
- `ManageBacklogController.createTicketFromSprint(<modal payload incl. sprintId>)`.
- Response `data`: `{ createdTicket, updatedSprint }`. The new ticket is added
  to the sprint via `_enrichSprintWithAddedTicket`, recalculating the SP bar.

### 3.3 `changeTicketState` — Update current state
**Trigger:** state combo change on a ticket row → `ticketstatechange` →
`handleTicketStateChange` (also reachable from `ticketView` via
`handleTicketViewStatusChange`).

**API call**
- `ManageBacklogController.changeTicketState({ ticketId, fromStatusId, toStatusId })`.
- Response `data`: `{ isEndStatus, updatedSprint }`.

**UI/UX**
- State: **G-LOCK**.
- On success the row's `CurrentState__c` updates everywhere. If `isEndStatus`,
  the sprint SP bar is recalculated from `updatedSprint` and a "Final Status
  Reached" success toast is shown; otherwise a "State updated" toast.
- On failure the ticket is re-keyed (`_reKeyTicket`, to reset the child combo)
  and **TOAST-ERR** shown.

### 3.4 `updateTicketPriority` — Update priority
**Trigger:** `ticketpriorityupdate` → `handleTicketPriorityUpdate`.
**Client validation (in `manageBacklog`):** `validatePriorityForUpdate(priority)`
from `backlogTicketValidator` (required; must be Critical/High/Medium/Low).

**API call**
- `ManageBacklogController.updateTicketPriority({ ticketId, priority })`.

**UI/UX**
- State: **EDIT-2BTN** (in child) + **G-LOCK** while saving; **TOAST-OK** /
  **TOAST-ERR**.

### 3.5 `updateTicketSummary` — Update summary
**Trigger:** `ticketsummaryupdate` → `handleTicketSummaryUpdate` (also from
`ticketView` via `handleTicketViewSummaryUpdate`).

**API call**
- `ManageBacklogController.updateTicketSummary({ ticketId, summary })`.

**UI/UX**
- State: **EDIT-2BTN** (in child) + **G-LOCK**; **TOAST-OK** / **TOAST-ERR**.

### 3.6 `updateTicketDescription` — Update description (Ticket View)
**Trigger:** `ticketdescriptionupdate` (from `ticketView`) →
`handleTicketViewDescriptionUpdate`.

**API call**
- `ManageBacklogController.updateTicketDescription({ ticketId, description })`.

**UI/UX**
- State: **G-LOCK**; **TOAST-OK** / **TOAST-ERR**. *(This function was absent
  from the original draft.)*

### 3.7 `assignTicket` — Assign ticket to member
**Trigger:** assignee picker on a ticket row → `ticketassigneechange` →
`handleTicketAssigneeChange`.

**API call**
- `ManageBacklogController.assignTicket({ ticketId, memberId })`.
- The assignee label is resolved client-side from the preloaded `memberOptions`.

**UI/UX**
- State: **POPOVER** (in child) + **G-LOCK**; **TOAST-OK** / **TOAST-ERR**.

### 3.8 `updateTicketEpic` — Assign / change the Epic parent
**Trigger:** the epic indicator on a ticket row → `ticketepicupdate` →
`handleTicketEpicUpdate`.

**API call**
- `ManageBacklogController.updateTicketEpic({ ticketId, epicId })`.
- The epic name is resolved from the preloaded `epics` list.

**UI/UX**
- State: **POPOVER** (Update Epic Parent panel, in child) + **G-LOCK**;
  **TOAST-OK** / **TOAST-ERR**.

> This is the real epic-assignment path — **not** `linkToTicket` (see §3.13).

### 3.9 `createEpic` — Create a new epic, then link it
**Trigger:** **Create a new epic** in the epic popover → `epiccreateforticket` →
`handleEpicCreateForTicket`.

**API call (two-step chain)**
1. `ManageBacklogController.createEpic({ name, summary, projectId, description, startDate, endDate })`.
2. On success → `ManageBacklogController.updateTicketEpic({ ticketId, epicId: createdEpic.Id })`.

**UI/UX**
- State: **MODAL** (Create Epic) + **G-LOCK**. On success the epic is appended to
  `epics` and assigned to the ticket; **TOAST-OK**. *(Method is `createEpic` —
  there is no `createEpicForTicket`/`EpicCreateDTO`; the body field is `name`,
  not `epic_name`.)*

### 3.10 `moveTicketToSprint` — Move a backlog ticket into a sprint
**Trigger:** drop a backlog ticket on a sprint container → `handleDropOnSprint` →
`_executeMoveTicketToSprint`.

**API call**
- `ManageBacklogController.moveTicketToSprint({ ticketId, sprintId })`.
- Response `data`: `{ updatedSprint }`. The ticket leaves the backlog; if the
  target sprint is expanded it is inserted there and the SP bar recalculates.

### 3.11 `moveTicketToBacklog` — Move a ticket out of a sprint
**Trigger:** drop a sprint ticket on the Backlog container → `handleDropOnBacklog`
→ `_executeMoveTicketToBacklog`.

**API call**
- `ManageBacklogController.moveTicketToBacklog({ ticketId })`.
- Response `data`: `{ updatedSprint }`. The ticket is removed from its sprint
  (SP bar recalculated) and appended to the backlog.

### 3.12 `moveTicketPosition` — Reorder within the same container
**Trigger:** same-container drag/drop onto another ticket or the top drop zone →
`handleDropOnTicket` / `handleDropOnTopZone` → `_executeMoveTicketPosition`.

**API call**
- `ManageBacklogController.moveTicketPosition({ movedTicketId, beforeTicketId })`
  (`beforeTicketId` is `null` for the top zone).
- Response `data`: `{ movedTicket }` (carries the new `Score__c`). The list is
  re-ordered in place by `_reorderTicketInContainer`.

> Reorder is a **distinct** method; it is not folded into `moveTicketToSprint`.

### 3.13 `linkToTicket` — Ticket-to-ticket link (Ticket View)
**Trigger:** in the `ticketView` peek panel → `ticketlinkcreate` →
`handleTicketLinkCreate`.

**API call**
- `ManageBacklogController.linkToTicket({ fromTicketId, toTicketId, linkType })`.
- Response `data`: `{ ticketLink }` (shaped as a link DTO), appended to the
  source ticket's `linkedTo`.

> This links **two tickets** (e.g. Blocks / is-blocked-by). It is **not** the
> epic-parent flow (that is §3.8).

### 3.14 `deleteTicket` — Delete a single ticket
**Trigger:** `ticketdelete` → `handleTicketDelete`.

**API call**
- `ManageBacklogController.deleteTicket({ ticketId })` (soft delete).
- Response `data`: `{ updatedSprint }`. The ticket is removed from the backlog
  and from sprints; the affected sprint's SP bar recalculates.

**UI/UX**
- State: **G-LOCK**; **TOAST-OK** / **TOAST-ERR**. The parent issues the delete
  directly — any confirmation step lives in the child `c-ao-ticket-item`.

### 3.15 `deleteTickets` — Bulk delete
**Trigger:** select ticket checkboxes → **BULK-BAR** → **Delete Selected** →
`handleBulkDelete` → **CONFIRM** → `_executeBulkDelete`.

**API call**
- `ManageBacklogController.deleteTickets({ ticketIds: [...] })` (soft delete each).
- Response `data`: `{ updatedSprints }`. Selected tickets are removed from the
  backlog and sprints; affected SP bars recalculate; the selection set clears.

**UI/UX**
- State: **BULK-BAR** + **CONFIRM** + **G-LOCK**; **TOAST-OK** / **TOAST-ERR**.

---

## 4. Sub-task container functions

> Subtask rows live inside an expanded `c-ao-ticket-item`. The parent exposes the
> handlers below; bulk subtask selection is handled inside the child and surfaces
> as a single `subtasksbulkdelete` event.

### 4.1 `createSubtask` — Create sub-task
**Trigger:** `subtaskcreate` → `handleSubtaskCreate` (or, from `ticketView`,
`handleTicketViewSubtaskCreate`).

**API call**
- `ManageBacklogController.createSubtask({ summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate })`
  (`startDate` is `null` from the `c-ao-ticket-item` path).
- On success the created subtask is appended via `_patchTicketEverywhere`.

### 4.2 `updateSubtaskSummary` — Update sub-task summary
**Trigger:** `subtasksummaryupdate` → `handleSubtaskSummaryUpdate`.

**API call**
- `ManageBacklogController.updateSubtaskSummary({ subtaskId, summary })`.
- Patched via `_patchSubtask` (re-keys the row).

### 4.3 `assignSubtask` — Assign sub-task to member
**Trigger:** `subtaskassigneechange` → `handleSubtaskAssigneeChange`.

**API call**
- `ManageBacklogController.assignSubtask({ subtaskId, memberId })`.
- Patches `Assignee__c` + resolved `assigneeName` from `memberOptions`.

### 4.4 `deleteSubtask` / `deleteSubtasks` — Delete sub-task(s)
**Trigger:** `subtaskdelete` → `handleSubtaskDelete`; `subtasksbulkdelete` →
`handleSubtasksBulkDelete`.

**API call**
- Single: `ManageBacklogController.deleteSubtask({ subtaskId })`.
- Bulk: `ManageBacklogController.deleteSubtasks({ subtaskIds: [...] })`.
- Both remove rows via `_removeSubtasks`.

---

## 5. Sprint functions

### 5.1 `createSprint` — Create sprint
**Trigger:** **+ Sprint** → `handleOpenCreateSprint` → sprint modal →
`handleSprintSubmit` → `_executeCreateSprint`.
**Client validation:** `validateSprintForm({ duration, goal })` — **only
`duration` and `goal` are required**; `startDate` is optional.

**API call**
- `ManageBacklogController.createSprint({ duration, startDate, goal, projectId })`.

**UI/UX**
- State: **MODAL** + **G-LOCK**. Modal fields are **Duration (days)**, **Start
  Date**, **Goal** only — there is **no Name and no End Date field** (the name is
  generated server-side; `endDate` is computed client-side via `calcEndDate`).
- On success the formatted sprint is appended to `sprints`; **TOAST-OK**.

### 5.2 `updateSprint` — Edit sprint
**Trigger:** **Edit** → `handleSprintEdit` (prefills duration, startDate, goal) →
`handleSprintSubmit` → `_executeUpdateSprint`.

**API call**
- `ManageBacklogController.updateSprint({ sprintId, duration, startDate, goal })`.

**UI/UX**
- State: **MODAL** + **G-LOCK**. The row re-renders in place (`endDate`
  recomputed via `calcEndDate`); **TOAST-OK**.

### 5.3 `startSprint` — Start sprint
**Trigger:** **Start** → `handleSprintStart` → **CONFIRM** → `startSprint`.

**API call**
- `ManageBacklogController.startSprint({ sprintId })`.

**UI/UX**
- State: **CONFIRM** + **G-LOCK**.
- On success: **TOAST-OK** ("Sprint started"). **The sprint stays on the page —
  it is not removed** (no client mutation beyond the toast).

### 5.4 `completeSprint` — Complete sprint
**Trigger:** **Complete** → `handleSprintComplete` → **CONFIRM** → `completeSprint`.

**API call**
- `ManageBacklogController.completeSprint({ sprintId })`.

**UI/UX**
- State: **CONFIRM** + **G-LOCK**. On success the sprint is **filtered out** of
  `sprints`; **TOAST-OK** / **TOAST-ERR**.

### 5.5 `deleteSprint` — Delete sprint
**Trigger:** **Delete** → `handleSprintDelete` → **CONFIRM**
("Delete this sprint? Tickets will be moved to backlog.") → `deleteSprint`.

**API call**
- `ManageBacklogController.deleteSprint({ sprintId })` (soft delete).

**UI/UX**
- State: **CONFIRM** + **G-LOCK**. On success the sprint's loaded tickets are
  moved into the backlog (`_moveSprintTicketsToBacklog`) and the sprint is
  removed from `sprints`; **TOAST-OK** / **TOAST-ERR**.

---

## 6. State coverage matrix (as implemented)

> Every mutation sets `isLoading` (G-LOCK) and shows **both** a success and an
> error toast unless noted.

| Function | G-LOCK | Localized spinner | Modal | 2-btn edit | Confirm | Bulk bar | Popover | Toast |
|----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| loadBacklogData | ✔ | | | | | | | err |
| loadBacklogTickets | | backlog | | | | | | err |
| loadTicketsBySprint | | sprint | | | | | | err |
| loadSubtasks (wire) | ✔ | | | | | | | — |
| createTicketFromBacklog | ✔ | | ✔ | | | | | ✔/✔ |
| createTicketFromSprint | ✔ | | ✔ | | | | | ✔/✔ |
| changeTicketState | ✔ | | | | | | | ✔/✔ |
| updateTicketPriority | ✔ | | | ✔ | | | | ✔/✔ |
| updateTicketSummary | ✔ | | | ✔ | | | | ✔/✔ |
| updateTicketDescription | ✔ | | | ✔ | | | | ✔/✔ |
| assignTicket | ✔ | | | | | | ✔ | ✔/✔ |
| updateTicketEpic | ✔ | | | | | | ✔ | ✔/✔ |
| createEpic (+link) | ✔ | | ✔ | | | | | ✔/✔ |
| moveTicketToSprint | ✔ | | | | | | | ✔/✔ |
| moveTicketToBacklog | ✔ | | | | | | | ✔/✔ |
| moveTicketPosition | ✔ | | | | | | | ✔/✔ |
| linkToTicket | ✔ | | | | | | | ✔/✔ |
| deleteTicket | ✔ | | | | (child) | | | ✔/✔ |
| deleteTickets | ✔ | | | | ✔ | ✔ | | ✔/✔ |
| createSubtask | ✔ | | ✔ | | | | | ✔/✔ |
| updateSubtaskSummary | ✔ | | | ✔ | | | | ✔/✔ |
| assignSubtask | ✔ | | | | | | ✔ | ✔/✔ |
| deleteSubtask | ✔ | | | | (child) | | | ✔/✔ |
| deleteSubtasks | ✔ | | | | | (child) | | ✔/✔ |
| createSprint | ✔ | | ✔ | | | | | ✔/✔ |
| updateSprint | ✔ | | ✔ | | | | | ✔/✔ |
| startSprint | ✔ | | | | ✔ | | | ✔/✔ |
| completeSprint | ✔ | | | | ✔ | | | ✔/✔ |
| deleteSprint | ✔ | | | | ✔ | | | ✔/✔ |

---

## 7. Changes from the original draft (eliminated / corrected)

1. **Controller renamed** `BacklogController` → **`ManageBacklogController`** throughout.
2. **`getProjectMembers` removed** — no such method. Members are loaded once in
   `loadBacklogData` and reused as `memberOptions`.
3. **`loadBacklogData` signature** corrected to `(projectId)` only; response keys
   corrected (`status`, `members`, `epics`, `ticketTypes`, `backlogTickets`,
   `priorityOptions`).
4. **`loadBacklogTickets` / `loadTicketsBySprint`** return plain **arrays**, not
   `{ tickets, total, ... }`; story-point totals come from the sprint record.
5. **Epic flow split correctly:** `updateTicketEpic` (assign/change epic) and
   `createEpic` (+chained `updateTicketEpic`). Removed the bogus
   `linkToTicket({ticket_id, epic_id})` and `createEpicForTicket`.
6. **`linkToTicket` re-scoped** to its real role: ticket-to-ticket linking in
   `ticketView` (`{ fromTicketId, toTicketId, linkType }`).
7. **`changeTicketState`** signature corrected to `{ ticketId, fromStatusId, toStatusId }`
   with `{ isEndStatus, updatedSprint }` response.
8. **`moveTicketPosition`** added (reorder within a container).
9. **`updateTicketDescription`** added (Ticket View).
10. **`createSprint`** corrected: body `{ duration, startDate, goal, projectId }`;
    only duration + goal required; **no Name / End Date** fields (name is
    server-generated, end date computed client-side).
11. **`startSprint`** corrected: the sprint is **not** removed from the page on success.
12. **`deleteSprint`** corrected: it also moves the sprint's tickets to the backlog.
13. **Toast column** corrected — nearly all mutations show a success toast, not error only.
14. **Bulk ticket delete** goes through a **CONFIRM** dialog before deleting.

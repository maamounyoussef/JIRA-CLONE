# SRS — Function Specific: Manage Backlog Page (corrected)

**Document type:** Software Requirements Specification (Function-Specific)
**Scope:** Manage Backlog page — Sprints container, Backlog container, Ticket container, Sub-task container, Epic flow, Ticket View peek panel.
**Platform:** Salesforce (LWC `manageBacklog` + Apex `ManageBacklogController`).

> **Why "corrected":** reconciled against the actual `manageBacklog` component.
> Requirements describing methods, fields, or behaviour not present in the code
> have been removed or fixed. See §5 for the change list.

---

## 1. Page-level pre-conditions (apply to all use cases)
- **PRE-G1:** A project must be selected. The id is read from `localStorage`
  (`projectId`); if missing, the page shows `c-choose-project` to obtain it.
- **PRE-G2:** Every request that needs a project id reads it from that resolved value.
- **PRE-G3:** The user is authenticated.

**Primary actor:** Authenticated project user (member of the selected project).
**Supporting actor:** Salesforce Apex backend (`ManageBacklogController`).

---

## 2. Use cases

### UC-00 — Bulk delete tickets
- **Pre-condition:** One or more ticket checkboxes selected (the **Bulk Bar** is shown).
- **Main flow:**
  1. The bulk bar shows the selected count, **Delete Selected** and **Cancel**.
  2. User clicks **Delete Selected**.
  3. System shows a **confirmation dialog**; user confirms.
  4. System sends `deleteTickets({ ticketIds })`, soft-deletes each, removes the
     rows from backlog and sprints, recalculates affected sprint SP bars, and
     clears the selection.
- **Alternatives:**
  - A1 (cancel selection): **Cancel** / deselect all → bar closes, no request.
  - A2 (cancel confirm): close the confirmation → no delete.
  - A3 (failure): error toast; nothing deleted.

### UC-01 — Delete a ticket
- **Main flow:** ticket delete action → `deleteTicket({ ticketId })` (soft
  delete) → row removed from backlog/sprints, affected sprint SP bar recalculated.
- **Alternatives:** A1 (failure) → error toast, row stays.
- **Note:** the parent deletes directly; any confirm prompt is in `c-ao-ticket-item`.

### UC-02 — Delete a sub-task
- **Pre-condition:** Parent ticket expanded (active sub-tasks loaded).
- **Main flow:** `deleteSubtask({ subtaskId })` (single) or
  `deleteSubtasks({ subtaskIds })` (bulk, from the child) → row(s) removed.
- **Alternatives:** A1 (failure) → error toast, sub-task stays.

### UC-03 — Update ticket priority
- **Main flow:** click priority → **X / ✓** → `✓` validates
  (`validatePriorityForUpdate`) then sends `updateTicketPriority({ ticketId, priority })`.
- **Alternatives:** A1 (cancel/blur) → no change; A2 (failure) → error toast.

### UC-05 — Update ticket summary
- **Main flow:** pencil → **X / ✓** → `✓` sends
  `updateTicketSummary({ ticketId, summary })`.
- **Alternatives:** A1 (cancel/blur) → no change; A2 (failure) → error toast.

### UC-06 — Update sub-task summary
- **Pre-condition:** Parent ticket expanded.
- **Main flow:** as UC-05 → `updateSubtaskSummary({ subtaskId, summary })`.
- **Alternatives:** A1 cancel/blur → no change; A2 failure → error toast.

### UC-07 — Assign ticket to a project member
- **Main flow:**
  1. User opens the assignee picker.
  2. System shows the **preloaded** project members (from `loadBacklogData`
     → `memberOptions`; **no `getProjectMembers` round-trip**).
  3. User selects a member → `assignTicket({ ticketId, memberId })`.
- **Alternatives:** A1 (blur) → close, no change; A2 (failure) → error toast.

### UC-08 — Assign sub-task to a member
- **Pre-condition:** Parent ticket expanded.
- **Main flow:** as UC-07 → `assignSubtask({ subtaskId, memberId })` (uses the
  same preloaded member list).
- **Alternatives:** A1 blur → close, no change; A2 failure → error toast.

### UC-09 — Update ticket current state
- **Main flow:** select a new state in the combo → `changeTicketState({ ticketId,
  fromStatusId, toStatusId })`. If the response reports `isEndStatus`, the sprint
  SP bar recalculates and a "Final Status Reached" toast is shown.
- **Alternatives:** A1 (failure) → error toast; the ticket row is re-keyed so the
  combo reverts.

### UC-10 — Update ticket description (Ticket View)
- **Pre-condition:** The Ticket View peek panel is open.
- **Main flow:** edit description → `updateTicketDescription({ ticketId, description })`.
- **Alternatives:** A1 (failure) → error toast. *(New — was absent from the draft.)*

### UC-11 — Create ticket (Backlog and Sprint)
- **Pre-condition:** User is a member of the current project.
- **Main flow:** **+ Ticket** (backlog or sprint header) → ticket modal → fill
  fields → **Create** → `createTicketFromBacklog(...)` or
  `createTicketFromSprint(...)` (the latter returns `{ createdTicket, updatedSprint }`
  and recalculates the sprint SP bar).
- **Alternatives:** A1 (cancel) → modal closes; A2 (failure) → error toast, modal
  stays open with values preserved.

### UC-12 — Create sub-task
- **Pre-condition:** Parent ticket expanded.
- **Main flow:** create-subtask (+) → modal (summary*, description, assignee,
  state, story point) → **Create** → `createSubtask({ summary, ticketId,
  description, assigneeId, currentStateId, storyPoint, startDate })`.
- **Alternatives:** A1 (cancel) → no save; A2 (failure) → error toast.

### UC-13 — Create sprint
- **Main flow:**
  1. User clicks **+ Sprint**.
  2. System shows the sprint modal with **Duration (days)**, **Start Date**,
     **Goal** (no Name, no End Date field).
  3. Validation requires **duration and goal** only (`validateSprintForm`);
     start date is optional.
  4. **Create** → `createSprint({ duration, startDate, goal, projectId })`; the
     name is generated server-side and the end date is derived from duration.
- **Alternatives:** A1 (cancel) → no save; A2 (failure) → error toast, modal stays open.

### UC-14 — Complete sprint
- **Main flow:** **Complete** → confirmation → confirm →
  `completeSprint({ sprintId })`; on success the sprint is removed from the page.
- **Alternatives:** A1 (cancel) → no change; A2 (failure) → error toast, sprint stays.

### UC-15 — Update sprint
- **Main flow:** **Edit** → modal prefilled with duration, start date, goal →
  **Update** → `updateSprint({ sprintId, duration, startDate, goal })`; the row
  re-renders with a recomputed end date.
- **Alternatives:** A1 (cancel) → no change; A2 (failure) → error toast.

### UC-16 — Delete sprint
- **Main flow:** **Delete** → confirmation ("Tickets will be moved to backlog")
  → confirm → `deleteSprint({ sprintId })`; the sprint's loaded tickets are moved
  to the backlog and the sprint is removed.
- **Alternatives:** A1 (cancel) → no change; A2 (failure) → error toast.

### UC-17 — Start sprint
- **Main flow:** **Start** → confirmation → confirm → `startSprint({ sprintId })`;
  on success a success toast is shown.
- **Alternatives:** A1 (cancel) → no change; A2 (failure) → error toast.
- **Note:** the sprint **remains visible** on the page after starting (it is not removed).

### UC-18 — Assign / change Epic parent, and create-new-epic
- **Main flow (assign existing):** click the epic indicator → epic popover →
  select an epic → `updateTicketEpic({ ticketId, epicId })`; the row shows the
  epic name.
- **Alternative (create new):** **Create a new epic** → Create Epic modal (name*,
  summary*, description, start date, end date) → **Create** →
  `createEpic({ name, summary, projectId, description, startDate, endDate })`,
  then `updateTicketEpic` to link it.
- **Alternatives:** A2 (cancel) → close, no change; A3 (failure) → error toast.
- **Note:** epic assignment uses `updateTicketEpic` — **not** `linkToTicket`.

### UC-19 — Move ticket (to sprint / within container / to backlog)
- **Main flow (drag & drop):**
  1. Drop a backlog ticket on a sprint → `moveTicketToSprint({ ticketId, sprintId })`.
  2. Reorder within the same container (drop on a ticket or the top zone) →
     `moveTicketPosition({ movedTicketId, beforeTicketId })`.
  3. Drop a sprint ticket on the backlog → `moveTicketToBacklog({ ticketId })`.
  Sprint moves recalculate the sprint SP bar.
- **Alternatives:** A1 (failure) → error toast.

### UC-20 — Link two tickets (Ticket View)
- **Pre-condition:** The Ticket View peek panel is open.
- **Main flow:** choose a link type and a target ticket (target search via
  `loadTicketBySearchTerm`; link types via `loadTicketLinkedToType`) → confirm →
  `linkToTicket({ fromTicketId, toTicketId, linkType })`; the new link is added to
  the source ticket's `linkedTo`. Existing links load via `loadTicketLinkedTo`.
- **Alternatives:** A1 (failure) → error toast. *(New — distinct from the epic flow.)*

### UC-21 — Load & paginate
- **Main flow:** on mount, `loadBacklogData({ projectId })` loads sprints,
  statuses, members, epics, ticket types, backlog tickets and priority options,
  routing each ticket to its sprint or the backlog. `‹`/`›` paginate the backlog
  (`loadBacklogTickets`) and each expanded sprint (`loadTicketsBySprint`).
  Expanding a ticket loads its active sub-tasks (`loadSubtasks`, wired).
- **Alternatives:** A1 (failure) → error toast; the affected list stays unchanged.

---

## 3. Business rules / constraints

### 3.1 Server-side rules (enforced in Apex)
- Soft delete only: tickets, sub-tasks and sprints set `RecordStatus__c` to a
  deleted value — never physically removed.
- Load functions return active records only; completed sprints are not displayed.
- Existence of ticket / sub-task / sprint / epic / project is validated before mutation.
- On ticket create: ticket type must exist; an assignee, if provided, must belong
  to the project; the current user must be a project member.
- On epic link / change: the epic and ticket must belong to the same project.
- On state change: the transition must be allowed; the response reports whether
  the target is an end status.

### 3.2 Client-side validation (in `manageBacklog`)
- `validateSprintForm({ duration, goal })` — **duration and goal required**;
  duration is a whole number 1–999; start date optional.
- `validatePriorityForUpdate(priority)` — required; one of Critical/High/Medium/Low.

> Other field validations (ticket name, summary, type, current state, story
> point, subtask summary) live in the child components
> (`aoCreateTicketModal`, `aoTicketItem`, `ticketView`) and surface to the parent
> as the events handled above.

### 3.3 General constraints
- Project id always comes from `localStorage` (or the choose-project splash);
  never re-entered on this page.
- Each mutation raises `isLoading` (panel spinner) and blocks re-entry of create
  handlers while in flight.
- Sprint name is generated server-side; sprint end date is derived from
  start date + duration (client `calcEndDate`).

---

## 4. Non-functional requirements (bulk get/set)

Bulk reads/writes must respect Apex governor limits. These apply to the bulk
operations: **`loadBacklogData`, `loadBacklogTickets`, `loadTicketsBySprint`**
(bulk get) and **`deleteTickets`, `deleteSubtasks`** (bulk set).

- **NFR-1 (CPU/SOQL):** Queries must be bulkified (no SOQL in loops) so query
  count and CPU time stay within the synchronous limit.
- **NFR-2 (Heap):** Assembling the bulk get response or processing a bulk delete
  must not exceed the heap limit; results are paginated by `PAGE_SIZE`.
- **NFR-3 (Pagination safeguards):** Page windows are clamped so a single page
  cannot breach NFR-1 / NFR-2.

| Function | Type | NFR-1 | NFR-2 |
|----------|------|:---:|:---:|
| loadBacklogData | bulk get | ✔ | ✔ |
| loadBacklogTickets | bulk get | ✔ | ✔ |
| loadTicketsBySprint | bulk get | ✔ | ✔ |
| deleteTickets | bulk set | ✔ | ✔ |
| deleteSubtasks | bulk set | ✔ | ✔ |

---

## 5. Changes from the original draft (eliminated / corrected)

1. Controller renamed to **`ManageBacklogController`** throughout.
2. **Removed `getProjectMembers`** (UC-07/08) — members are preloaded by
   `loadBacklogData`.
3. **Epic flow corrected** — assignment is `updateTicketEpic`; create-new is
   `createEpic` (+`updateTicketEpic`). Removed the `linkToTicket`-as-epic
   description and `createEpicForTicket`.
4. **Added UC-20 (ticket-to-ticket linking)** as the real `linkToTicket` use case.
5. **Added UC-10 (update description)** and **UC-21** load/paginate corrected to
   the real `loadBacklogData({ projectId })` payload.
6. **`changeTicketState`** signature corrected (`fromStatusId`/`toStatusId`,
   `isEndStatus`).
7. **UC-13 (create sprint)** corrected: fields = Duration / Start Date / Goal
   only; only duration + goal required; name server-generated; end date derived.
8. **UC-17 (start sprint)** corrected: the sprint stays visible after starting.
9. **UC-16 (delete sprint)** corrected: tickets are moved to the backlog.
10. **UC-19 (move)** corrected: reorder uses the distinct `moveTicketPosition`.
11. **UC-00 (bulk delete)** corrected: a confirmation dialog precedes the delete.
12. **NFR list** extended with `deleteSubtasks` (also a bulk set).

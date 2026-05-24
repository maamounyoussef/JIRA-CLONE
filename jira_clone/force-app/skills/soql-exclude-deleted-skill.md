---
name: soql-exclude-deleted
description: >
  Every SOQL query that retrieves records from a custom object with a
  `RecordStatus__c` field MUST exclude soft‑deleted rows by adding
  `RecordStatus__c != 'delete'` (or the equivalent positive filter, e.g.
  `RecordStatus__c = 'active'`) to the `WHERE` clause. This applies to
  single‑record finders, list loaders, and any subquery — without being asked.

  TRIGGER (apply silently) when writing or editing Apex that contains a
  `[SELECT ... FROM <Object>__c ...]` clause where `<Object>__c` is a custom
  object that has a `RecordStatus__c` field (Ticket__c, Subtask__c, Sprint__c,
  Epic__c, TicketLink__c, TicketType__c, ProjectMember__c, EpicLink__c,
  ValidationRule__c, WorkflowTransition__c, etc.). Applies to `findX`,
  `loadX`, `getX`, `requireXExists`, relationship subqueries, and aggregate
  queries.

  SKIP only when the caller's intent is explicitly to read deleted rows
  (audit/restore flows, admin recovery tooling) — in that case leave a one‑line
  comment in the code stating that intent.
---

# SOQL: Exclude Soft‑Deleted Records

Custom objects in this project use a soft‑delete pattern: deletion sets
`RecordStatus__c = 'delete'` rather than removing the row (see
[TicketService.cls:104-121](force-app/main/default/classes/domain/TicketService.cls#L104-L121)
and [SprintService.cls:49-57](force-app/main/default/classes/domain/SprintService.cls#L49-L57)).
A query that omits the `RecordStatus__c != 'delete'` filter therefore returns
**stale, logically‑deleted records** to callers and silently corrupts every
downstream calculation (story‑point rollups, board counts, links, exports).

This skill is the guardrail that prevents that leak. Every retrieval must
filter out deleted rows at the SOQL layer — never in Apex after the fact.

---

## Instructions

### Step 1 — Detect a query that needs the filter

Before finalizing any Apex method that contains `[SELECT ... FROM ...]`, scan
it for these signals. If **any** match, the query must be rewritten in Step 2:

| # | Signal | Example |
|---|--------|---------|
| 1 | `[SELECT ... FROM <Object>__c WHERE Id = :id]` with no `RecordStatus__c` clause | `findTicketById`, `findSprintById` |
| 2 | `[SELECT ... FROM <Object>__c WHERE <FK>__c = :parentId]` with no `RecordStatus__c` clause | "load by sprint", "load by project" |
| 3 | Subquery in a parent SELECT: `(SELECT ... FROM Children__r)` with no filter | parent‑with‑children loaders |
| 4 | Aggregate (`COUNT()`, `SUM()`) over a custom object with no `RecordStatus__c` filter | rollups, dashboards |
| 5 | Filter is `RecordStatus__c = 'active'` only, but the object's lifecycle has more states (e.g. `completed`, `in_progress`) that callers expect | `loadActiveSprint`, `loadUncompleteSprintsByProject` |

The third column lists real examples — both compliant and non‑compliant — to
calibrate detection.

---

### Step 2 — Rewrite the query to exclude deletes

Apply whichever variant fits the caller's intent:

**Variant A — exclude only deleted rows** (the default; preserves all other
lifecycle states):

```apex
WHERE Id = :ticketId AND RecordStatus__c != 'delete'
```

**Variant B — restrict to a specific live status** (only when the caller
genuinely wants one state, e.g. backlog/board views):

```apex
WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
```

Pick the variant by asking: *"if a row had `RecordStatus__c = 'completed'`,
should this query return it?"* If yes → Variant A. If no → Variant B.

---

### Step 3 — Reference rewrites from this codebase

The two service classes below show the pattern correctly applied and a gap
that this skill exists to close.

#### ✅ Already compliant — use these as the template

```apex
// force-app/main/default/classes/domain/TicketService.cls:165
public static List<Ticket__c> loadBacklogTickets(Project__c project, Integer offset, Integer pageSize) {
    ...
    return [
        SELECT Id, Name, Summary__c, ...
        FROM Ticket__c
        WHERE Ticket_Type__c IN :typeIds
          AND RecordStatus__c = 'active'           // ← Variant B: only active
          AND Sprint__c = null
        ORDER BY Priority__c ASC, EndDate__c DESC
        LIMIT :currentPageSize OFFSET :currentOffset
    ];
}
```

```apex
// force-app/main/default/classes/domain/TicketService.cls:379
public static List<Subtask__c> getSubtasksByTicket(Ticket__c ticket) {
    return [
        SELECT Id, Name, Summary__c, ...
        FROM Subtask__c
        WHERE Ticket__c = :ticket.Id
          AND RecordStatus__c != 'delete'          // ← Variant A: exclude deleted
        ORDER BY CreatedDate DESC
    ];
}
```

```apex
// force-app/main/default/classes/domain/TicketService.cls:442
public static List<TicketType__c> loadTicketTypes(Project__c project) {
    return [
        SELECT Id, Name, ...
        FROM TicketType__c
        WHERE Project__c = :project.Id
          AND RecordStatus__c != 'delete'          // ← Variant A
        ORDER BY Name ASC
    ];
}
```

#### ❌ Non‑compliant — must be rewritten

```apex
// force-app/main/default/classes/domain/TicketService.cls:12
// BEFORE — returns deleted tickets to the caller
public static Ticket__c findTicketById(String ticketId) {
    List<Ticket__c> res = [
        SELECT Id, Name, Summary__c, ..., RecordStatus__c
        FROM Ticket__c
        WHERE Id = :ticketId
        LIMIT 1
    ];
    return res.isEmpty() ? null : res[0];
}

// AFTER — Variant A applied
public static Ticket__c findTicketById(String ticketId) {
    List<Ticket__c> res = [
        SELECT Id, Name, Summary__c, ..., RecordStatus__c
        FROM Ticket__c
        WHERE Id = :ticketId AND RecordStatus__c != 'delete'
        LIMIT 1
    ];
    return res.isEmpty() ? null : res[0];
}
```

```apex
// force-app/main/default/classes/domain/SprintService.cls:7
// BEFORE — a deleted sprint can still be loaded by id
public static Sprint__c findSprintById(String sprintId) {
    return [
        SELECT Id, Name, ..., RecordStatus__c
        FROM Sprint__c
        WHERE Id = :sprintId
        LIMIT 1
    ];
}

// AFTER — Variant A applied
public static Sprint__c findSprintById(String sprintId) {
    return [
        SELECT Id, Name, ..., RecordStatus__c
        FROM Sprint__c
        WHERE Id = :sprintId AND RecordStatus__c != 'delete'
        LIMIT 1
    ];
}
```

```apex
// force-app/main/default/classes/domain/TicketService.cls:267
// BEFORE — clears sprint pointer on deleted tickets too (wasted DML)
List<Ticket__c> tickets = [
    SELECT Id, Sprint__c
    FROM Ticket__c
    WHERE Sprint__c = :sprintId
];

// AFTER — Variant A applied
List<Ticket__c> tickets = [
    SELECT Id, Sprint__c
    FROM Ticket__c
    WHERE Sprint__c = :sprintId AND RecordStatus__c != 'delete'
];
```

---

### Step 4 — Verify with the checklist

Before presenting the rewritten code, walk this checklist. If any row fails,
go back to Step 2:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | Every `[SELECT ... FROM <Object>__c]` (where the object has `RecordStatus__c`) has either `RecordStatus__c != 'delete'` or `RecordStatus__c = '<live state>'` in its `WHERE` clause | Add the appropriate filter (Variant A or B). |
| 2 | Every relationship subquery (`(SELECT ... FROM Children__r)`) has the same filter | Add `WHERE RecordStatus__c != 'delete'` to the inner SELECT. |
| 3 | Every aggregate/`COUNT()` query carries the filter | Same as #1. |
| 4 | Variant B (`= 'active'`) is only used where the caller truly wants one state, not as a shortcut | Switch to Variant A (`!= 'delete'`) when other live states (`completed`, `in_progress`, etc.) should be included. |
| 5 | If the query intentionally reads deleted rows (audit/restore), a single‑line comment justifies it | Add `// intentional: includes RecordStatus__c='delete' for <reason>`. |
| 6 | Functional behaviour preserved — caller's null/empty handling still works after the filter | Re‑test the empty‑result branch. |

---

## Resources

### Objects with `RecordStatus__c` in this project

From `OBJECT_VALIDATION_LWC_APEX.md`: Ticket__c, Subtask__c, Sprint__c,
Epic__c (via store contract), TicketLink__c, TicketType__c, ProjectMember__c,
EpicLink__c (via IsActive), ValidationRule__c, WorkflowTransition__c.

If a new custom object is added with a `RecordStatus__c` field, this skill
applies to it automatically — no edit needed.

### Lifecycle values seen in this codebase

| Value | Set by | Example |
|---|---|---|
| `active` | default on insert | `prepareTicketForInsert` sets `ticket.RecordStatus__c = 'active'` |
| `delete` | soft‑delete operations | `deleteTicket`, `deleteSubtask`, `deleteSprint` |
| `in_progress` | sprint start | `startSprint` in `SprintService` |
| `completed` | sprint complete | `completeSprint` in `SprintService` |

Variant A (`!= 'delete'`) is the safe default because it admits every live
state — present and future — without code changes. Reach for Variant B only
when the view truly wants one state.

---

## Optional Logic

### Pair with `apex-bulk-soql`

When bulkifying a method via the `apex-bulk-soql` skill, apply this filter to
the single bulk query — not to the per‑record query you're removing. The
bulk‑safe example in that skill already shows the pattern:

```apex
Map<Id, X__c> recordMap = new Map<Id, X__c>([
    SELECT Id, /* fields */
    FROM X__c
    WHERE Id IN :ids AND RecordStatus__c != 'delete'   // ← this skill
]);
```

### When the filter is legitimately omitted

A query may omit `RecordStatus__c != 'delete'` only when:

- The intent is to read deleted rows (audit log, restore UI, admin tooling).
- The object has no `RecordStatus__c` field (e.g. `Project__c` per the
  validation reference).
- The filter is already enforced by a stricter clause that implies live state
  (e.g. `WHERE Id IN :liveIds` where `liveIds` was produced by a prior
  filtered query — but even here, a defence‑in‑depth filter is cheap and
  preferred).

In the audit/restore case, add a one‑line comment so future readers don't
"fix" the query and reintroduce the leak.

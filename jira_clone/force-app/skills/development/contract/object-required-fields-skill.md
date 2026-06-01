---
name: object-required-fields
description: >
  Before writing or editing ANY code that retrieves or updates a
  custom Salesforce object in this project, READ `OBJECT_VALIDATION_LWC_APEX.md`
  first and apply the required‑field contract that matches your layer (LWC
  front‑end vs. Apex/store back‑end). The file has separate columns "for lwc"
  and "for apex and store" — they are NOT the same; missing this distinction
  is the single most common cause of `FIELD_CUSTOM_VALIDATION_EXCEPTION` and
  `REQUIRED_FIELD_MISSING` errors in this codebase.

  TRIGGER (apply silently, before generating code) when writing or editing:
  (1) Apex that issues `[SELECT ...]`, `insert`, `update`, or `upsert` against
  a custom object (`*__c`); (2) Apex test data builders / `@TestSetup`;
  (3) LWC JS that calls `createRecord`, `updateRecord`, or an `@AuraEnabled`
  controller that writes a record; (4) LWC HTML forms (`lightning-record-form`,
  `lightning-input-field`) that bind to a custom object; (5) any DTO/store
  contract for sending a record to the server.

  SKIP only when the change is purely cosmetic (CSS, label rename, comment
  edit) and touches no record fields.
---

# Object Required Fields — LWC & Apex Contract

`OBJECT_VALIDATION_LWC_APEX.md` is the **source of truth** for which fields
are required on every custom object in this project. Reading it before you
touch object code is faster than debugging a failed `insert` afterwards.

This skill is the guardrail that forces that read — and forces you to pick
the correct column for your layer.

---

## Instructions

### Step 1 — Identify the layer you're working in

Before generating any code that retrieves or writes a custom object, decide
which column of `OBJECT_VALIDATION_LWC_APEX.md` applies:

| You are editing | Use the column | Why |
|---|---|---|
| Apex controller / service / trigger | **for apex and store** | Server enforces these; missing them throws `FIELD_CUSTOM_VALIDATION_EXCEPTION` or `REQUIRED_FIELD_MISSING_EXCEPTION` |
| Apex test setup / `@TestSetup` / test data factory | **for apex and store** | Tests run against the real schema |
| LWC JS calling `createRecord` / `updateRecord` / wire‑update | **for lwc** | UI‑side required check; subset of apex‑and‑store |
| LWC HTML form (`lightning-record-form`, `lightning-input-field`) | **for lwc** | Drives client‑side `required` attribute |
| DTO / store contract (the JS object posted to `@AuraEnabled`) | **for apex and store** | Server reads this — must satisfy server contract |

When in doubt: **server‑side code uses the "for apex and store" column.** The
"for lwc" column is a *subset* — the back‑end will still reject a record that
the front‑end allowed through.

---

### Step 2 — Read the relevant section

Open `OBJECT_VALIDATION_LWC_APEX.md` and locate the section for the object
you're touching. Read **both** the per‑object table and the
"Quick Reference — Required Fields Only" summary at the bottom.

For each required field flagged `YES`/`yes` in your layer's column, plan how
the value will be supplied. The common sources in this codebase are:

| Source | When to use | Example |
|---|---|---|
| Caller argument | Field is user input or comes from upstream context | `Summary__c`, `Description__c`, `Project__c` |
| `UserInfo.getUserId()` → `ProjectMember__c` lookup | Field is `Creator__c` or `Assignee__c` | See `prepareTicketForInsert` in `TicketService.cls:62-67` |
| Static default | Field has a known default and the caller did not provide one | `Priority__c = 'Medium'`, `RecordStatus__c = 'active'` |
| Domain helper | Field is derived (e.g. start status from workflow) | `StatusService.getStartStatus(projectId)` |

For retrieval (`SELECT`) the same file tells you which fields the caller will
expect to be populated — include every required field in your `SELECT` list
so downstream code doesn't get a null it cannot handle.

---

### Step 3 — Apply the contract before generating code

Generate the code only after Step 2. The output must satisfy:

1. **Every required field is set** before the DML, or every required field is
   in the `SELECT` list before the return.
2. **No required field is silently defaulted to `null`** — if the value
   genuinely is unknown, surface it as a `ServiceException` with a clear
   message rather than letting the platform throw `REQUIRED_FIELD_MISSING`.
3. **The same set of required fields is honoured in tests.** If you add or
   change a field requirement, update the matching `@TestSetup` and any
   factory helpers in the same change.

#### Reference patterns from this codebase

```apex
// force-app/main/default/classes/domain/TicketService.cls:59
// Sets every "for apex and store" required field on Ticket__c before insert:
//   Creator__c (resolved from UserInfo + ProjectMember lookup)
//   Priority__c (default 'Medium')
//   CurrentState__c (resolved via StatusService)
//   RecordStatus__c ('active')
// Description__c and Ticket_Type__c are set by the caller upstream.
private static Status__c prepareTicketForInsert(Ticket__c ticket, TicketType__c ticketType) {
    String projectId = ticketType.Project__c;

    if (String.isBlank(ticket.Creator__c)) {
        String userId = UserInfo.getUserId();
        ProjectMember__c creator = ProjectService.findActiveMemberByUserAndProject(userId, projectId);
        DomainCompleteValidator.requireCurrentUserMemberForProject(creator, userId);
        ticket.Creator__c = creator.Id;
    }
    if (String.isBlank(ticket.Priority__c)) ticket.Priority__c = 'Medium';

    Status__c status;
    if (String.isBlank(ticket.CurrentState__c)) {
        status = StatusService.getStartStatus(projectId);
    } else {
        status = StatusService.findStatus(ticket.CurrentState__c);
    }
    ticket.CurrentState__c = status.Id;
    ticket.RecordStatus__c = 'active';
    return status;
}
```

```apex
// force-app/main/default/classes/domain/TicketService.cls:425
// TicketType__c — "for apex and store" requires RecordStatus__c, Workflow__c,
// Description__c, IconUrl__c, Project__c. All are set before insert.
public static TicketType__c createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
    TicketType__c ticketType = new TicketType__c(
        Name            = name,
        Description__c  = description,
        IconUrl__c      = iconUrl,
        Workflow__c     = workflowId,
        Project__c      = projectId,
        RecordStatus__c = 'active'
    );
    insert ticketType;
    return ticketType;
}
```

```apex
// force-app/main/default/classes/domain/TicketService.cls:487
// TicketLink__c — "for apex and store" requires LinkedFromTicket__c,
// LinkedToTicket__c, RecordStatus__c, Type__c. All four set before insert.
TicketLink__c link = new TicketLink__c(
    LinkedFromTicket__c = fromTicketId,
    LinkedToTicket__c   = toTicketId,
    Type__c             = linkType,
    RecordStatus__c     = 'active'
);
insert link;
```

For LWC: `lightning-input-field` must be marked `required` for every field in
the "for lwc" column, and the JS submit handler must validate them before
calling the controller. The server still re‑validates against the
"for apex and store" column.

---

### Step 4 — Verify with the checklist

Before presenting the code, walk this checklist. If any row fails, return to
Step 2:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | I have just read the section of `OBJECT_VALIDATION_LWC_APEX.md` for every object touched by this change. | Read it now — don't skip on the assumption that "I remember it". |
| 2 | I chose the correct column ("for lwc" vs. "for apex and store") for the layer I'm editing. | Re‑pick the column using the Step 1 table. |
| 3 | Every `YES` field in that column is supplied before `insert`/`update` (or in `SELECT` for reads). | Add the missing field assignment — or surface a clear `ServiceException`. |
| 4 | No required field is implicitly `null`. | Replace `null` with a real value or a fail‑fast guard. |
| 5 | Test data builders / `@TestSetup` set the same required fields. | Update tests in the same change. |
| 6 | For LWC: every "for lwc" required field is marked `required` in the form, AND the JS validates it before submit. | Add `required` and a pre‑submit check. |
| 7 | For DTO/store contracts: every "for apex and store" field is present in the payload. | Add the missing key to the DTO. |

---

## Resources

### The reference file

`OBJECT_VALIDATION_LWC_APEX.md` (project root) — required fields per object,
split into "for lwc" and "for apex and store" columns. The "Quick Reference"
table at the bottom is a fast lookup.

### Picklist values defined in the reference

| Object.Field | Allowed values |
|---|---|
| `Ticket__c.Priority__c` | Critical · High · Medium · Low |
| `TicketLink__c.Type__c` | Blocks · Relates To · Duplicates · Depends On |
| `ValidationRule__c.Type__c` | Not Equals |

If the code introduces another value, update the reference file in the same
change — otherwise future readers will treat the new value as a bug.

### Lifecycle values seen in this codebase

`RecordStatus__c` is `Text(100)`, not a picklist, but the codebase uses a
fixed set: `active`, `delete`, `in_progress` (sprint only), `completed`
(sprint only). See the `soql-exclude-deleted` skill for the read‑side
guardrail that depends on these values.

---

## Optional Logic

### When `OBJECT_VALIDATION_LWC_APEX.md` and the schema disagree

If the actual object metadata (`force-app/main/default/objects/**`) says a
field is required but the reference doesn't — or vice versa — **trust the
metadata** and update the reference file in the same change. The reference
exists to mirror the schema; a drift is a bug in the reference, not the code.

### Pairing with other skills

- `apex-bulk-soql`: when you collect ids and run one bulk `SELECT`, include
  every required field from the reference so the consuming code doesn't have
  to re‑query.
- `soql-exclude-deleted`: independent guardrail on the same `SELECT`
  statements — apply both together.
- `lwc-architecture`: the LWC layer reads "for lwc"; the controller and
  service read "for apex and store". The reference file is what makes the
  two layers agree on the contract.

### When adding a new custom object

When introducing a new `*__c` object, add a section to
`OBJECT_VALIDATION_LWC_APEX.md` in the same change — both columns ("for lwc"
and "for apex and store") and the "Quick Reference" row. A skill cannot
enforce a contract that doesn't exist in the reference yet.

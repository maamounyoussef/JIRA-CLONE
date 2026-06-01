# Project Instructions — Jira Clone

## Apex bulkification (MANDATORY — three‑skill chain, applies automatically)

Whenever you write or edit Apex that retrieves or updates **more than one record**
(a method taking a `List`/`Set`/`Map`, a loop containing SOQL/DML, or a per‑record
guard like `requireXExists(id)` called over a collection), you MUST run the
following three skills **in order, without being asked**:

1. **Detect** — `apex-governor-limit-guard`
   (`force-app/skills/development/guard/apex-governor-limit-guard.md`).
   Scan the method against the six N+1 / heap signals. If any signal matches,
   the method will breach CPU / SOQL / DML / heap at scale and must be
   rewritten before you present it.
2. **Rewrite** — `apex-bulk-soql`
   (`force-app/skills/development/performance/apex-bulk-soql.md`).
   Apply the three non‑negotiable rules below, then walk the guard's Step 2
   execution checklist before presenting the code.
3. **Measure** — `apex-method-monitor`
   (`force-app/skills/development/performance/apex-method-monitor.md`).
   For any `@AuraEnabled` controller method in `classes/controller/**` that
   runs SOQL/SOSL/DML, ASK the user via the interactive `AskUserQuestion`
   tool (not plain text) whether to create a monitoring report. If yes,
   generate a governor‑limit test method, RUN it, and append the real
   CPU / Heap / SOQL / DML‑rows / DML‑statements to
   `docs/apex-method-report.md` (create the file if it doesn't exist).
   Never record estimated numbers — always run the test first.

Non‑negotiable bulk rules (rewrite step):
1. **No SOQL inside a loop** — query once with `WHERE Id IN :ids` into a `Map<Id, SObject>`.
2. **No DML inside a loop** — accumulate a `List` and `insert`/`update`/`delete` once.
3. **Validate/look up in memory** with `map.containsKey(id)` / `map.get(id)`.

Skip the whole chain only for genuinely single‑record operations (one id in,
one record out, no collection) or async Batch Apex that chunks by design.
See `docs/deleteTickets-SOQL-Optimization.docx` for a worked example
(SOQL 49 → 26, CPU ≈ −47%).

## SOQL: exclude soft‑deleted rows (MANDATORY — applies automatically)

Whenever you write or edit Apex that contains `[SELECT ... FROM <Object>__c]`
where the object has a `RecordStatus__c` field (Ticket__c, Subtask__c,
Sprint__c, Epic__c, TicketLink__c, TicketType__c, ProjectMember__c, etc.),
you MUST follow the **`soql-exclude-deleted`** skill
(`force-app/skills/development/contract/soql-exclude-deleted-skill.md`) **without being asked**.

Non‑negotiable rule: every such query's `WHERE` clause includes either
`RecordStatus__c != 'delete'` (default) or `RecordStatus__c = '<live state>'`
(when only one live state is wanted). Subqueries and aggregates count too.
Skip only with an inline comment explaining intentional inclusion of deleted
rows (audit/restore tooling).

## Object required fields (MANDATORY — read before any retrieve/update)

Before writing or editing any code that retrieves, creates, or updates a
custom object — Apex or LWC — you MUST follow the **`object-required-fields`**
skill (`force-app/skills/development/contract/object-required-fields-skill.md`) **without being
asked**: READ `OBJECT_VALIDATION_LWC_APEX.md` first and pick the correct
column for the layer ("for lwc" vs. "for apex and store"). Server‑side code
and DTO/store contracts use "for apex and store"; LWC forms and
`createRecord`/`updateRecord` calls use "for lwc".

## Architecture

For new LWC/Apex components, follow `force-app/skills/development/task-skill/lwc-architecture-skill.md`
(thin `@AuraEnabled` controller → `domain/<Name>Service` → `APIResponse` envelope).

## Object field validation

`OBJECT_VALIDATION_LWC_APEX.md` is the source of truth for required fields per object
(note the separate "for apex and store" column). Set all required fields in tests and
inserts accordingly.

# Project Instructions — Jira Clone

## Apex bulkification (MANDATORY — applies automatically)

Whenever you write or edit Apex that retrieves or updates **more than one record**
(a method taking a `List`/`Set`/`Map`, a loop containing SOQL/DML, or a per‑record
guard like `requireXExists(id)` called over a collection), you MUST follow the
**`apex-bulk-soql`** skill (`force-app/skills/apex-bulk-soql-skill.md`) **without
being asked**.

Non‑negotiable rules:
1. **No SOQL inside a loop** — query once with `WHERE Id IN :ids` into a `Map<Id, SObject>`.
2. **No DML inside a loop** — accumulate a `List` and `insert`/`update`/`delete` once.
3. **Validate/look up in memory** with `map.containsKey(id)` / `map.get(id)`.

Skip only for genuinely single‑record operations or async Batch Apex that chunks by
design. See `docs/deleteTickets-SOQL-Optimization.docx` for a worked example
(SOQL 49 → 26, CPU ≈ −47%).

## Apex method monitoring (offer after each SOQL/SOSL controller method)

After you create or edit any `@AuraEnabled` controller method in
`classes/controller/**` that runs SOQL or SOSL, follow the **`apex-method-monitor`**
skill (`force-app/skills/apex-method-monitor-skill.md`): ASK the user — via the
interactive `AskUserQuestion` tool, not a plain‑text question — whether to create a
monitoring report. If yes, generate a governor‑limit test method, RUN it,
and append the real CPU / Heap / SOQL / DML‑rows / DML‑statements to
`docs/apex-method-report.md` (create the file if it doesn't exist). Never record
estimated numbers — always run the test first.

## SOQL: exclude soft‑deleted rows (MANDATORY — applies automatically)

Whenever you write or edit Apex that contains `[SELECT ... FROM <Object>__c]`
where the object has a `RecordStatus__c` field (Ticket__c, Subtask__c,
Sprint__c, Epic__c, TicketLink__c, TicketType__c, ProjectMember__c, etc.),
you MUST follow the **`soql-exclude-deleted`** skill
(`force-app/skills/soql-exclude-deleted-skill.md`) **without being asked**.

Non‑negotiable rule: every such query's `WHERE` clause includes either
`RecordStatus__c != 'delete'` (default) or `RecordStatus__c = '<live state>'`
(when only one live state is wanted). Subqueries and aggregates count too.
Skip only with an inline comment explaining intentional inclusion of deleted
rows (audit/restore tooling).

## Object required fields (MANDATORY — read before any retrieve/update)

Before writing or editing any code that retrieves, creates, or updates a
custom object — Apex or LWC — you MUST follow the **`object-required-fields`**
skill (`force-app/skills/object-required-fields-skill.md`) **without being
asked**: READ `OBJECT_VALIDATION_LWC_APEX.md` first and pick the correct
column for the layer ("for lwc" vs. "for apex and store"). Server‑side code
and DTO/store contracts use "for apex and store"; LWC forms and
`createRecord`/`updateRecord` calls use "for lwc".

## Architecture

For new LWC/Apex components, follow `force-app/skills/lwc-architecture-skill.md`
(thin `@AuraEnabled` controller → `domain/<Name>Service` → `APIResponse` envelope).

## Object field validation

`OBJECT_VALIDATION_LWC_APEX.md` is the source of truth for required fields per object
(note the separate "for apex and store" column). Set all required fields in tests and
inserts accordingly.

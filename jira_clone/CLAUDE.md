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

## Architecture

For new LWC/Apex components, follow `force-app/skills/lwc-architecture-skill.md`
(thin `@AuraEnabled` controller → `domain/<Name>Service` → `APIResponse` envelope).

## Object field validation

`OBJECT_VALIDATION_LWC_APEX.md` is the source of truth for required fields per object
(note the separate "for apex and store" column). Set all required fields in tests and
inserts accordingly.

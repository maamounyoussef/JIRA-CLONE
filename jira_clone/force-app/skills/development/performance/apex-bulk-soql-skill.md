---
name: apex-bulk-soql
description: >
  Optimize ANY Apex that performs a bulk retrieve or bulk update into a single
  synchronous SOQL query and a single bulk DML per object — automatically, without
  the user asking. This is a guardrail skill: it runs whenever YOU (the AI) write
  or edit Apex that touches more than one record.

  TRIGGER (apply silently) when writing or editing Apex and ANY of these is true:
  a method accepts a `List<...>`, `Set<...>`, or `Map<...>` of ids/records; there
  is a `for`/`while` loop whose body contains a SOQL `[SELECT ...]`, a query
  method (`findX`, `requireXExists`, `getX`), or a DML statement
  (`insert`/`update`/`delete`/`upsert`); the work is described as bulk / batch /
  "delete tickets", "update statuses", "load by ids", "for each ... query/save";
  you call a per-record guard (e.g. `DomainCorrectness.requireXExists(id)`) once
  per element of a collection.

  SKIP when the operation is genuinely single-record (one id in, one record out
  and no collection), or the code is asynchronous Batch Apex already chunking by
  design.
---

# Apex Bulk SOQL

Turns an N+1 pattern (one query/DML per record) into O(1) queries and DML —
independent of how many records the request carries. Numbers always come from
real bulk-safe rewrites, not estimates. Salesforce enforces, per **synchronous**
transaction, 100 SOQL queries, 150 DML statements, and 10,000 ms CPU; an N+1
pattern silently passes a 5-record test then aborts the first real batch with a
`LimitException` that cannot be caught.

---

## Instructions

### Step 1 — Detect the N+1 pattern

Before finalizing any Apex method that reads or writes more than one record,
scan it for any of these signals. If **any** match, the method is N+1 and must
be rewritten in Step 2:

| # | Signal | Example |
|---|--------|---------|
| 1 | `[SELECT ...]` inside a `for`/`while` loop | `for (Id id : ids) { [SELECT ... WHERE Id = :id]; }` |
| 2 | `insert`/`update`/`delete`/`upsert` inside a loop | `for (X__c r : recs) { update r; }` |
| 3 | Per-record guard called per element | `for (Id id : ids) { DomainCorrectness.requireXExists(id); }` |
| 4 | Helper method (`findX`, `getX`, `requireXExists`) called per element | `for (X__c r : recs) { StatusService.findStatus(r.CurrentState__c); }` |
| 5 | Related/parent records fetched per row | `for (X__c r : recs) { [SELECT ... FROM Parent__c WHERE Id = :r.Parent__c]; }` |

If none match (e.g. one id in, one record out), skip — the method is already
single-record safe.

---

### Step 2 — Rewrite into the bulk-safe form

Apply the **three rules** in order. Every bulk method must satisfy all three:

1. **One query per object type, not per record.** Collect ids into a `Set<Id>`,
   query once with `WHERE Id IN :ids` (or the relevant lookup field), and load
   the result into a `Map<Id, SObject>`. Select **every field** the consuming
   code reads, so no follow-up query is needed.
2. **Validate and look up in memory.** Loop over the *input collection* and use
   `map.containsKey(id)` for existence and `map.get(id)` for lookups. This is
   CPU only — zero extra SOQL. It preserves per-record error messages
   (e.g. `throw new ServiceException('Ticket not found: ' + id)`).
3. **One DML per object type.** Build a `List<SObject>` of everything to write,
   then `update`/`insert`/`delete` the whole list once — never inside a loop.

Anti-pattern to detect:

```apex
// ❌ N+1: one SOQL per element, and/or one DML per element
for (String id : ids) {
    records.add(DomainCorrectness.requireXExists(id)); // SOQL in loop
}
for (X__c r : records) {
    Status__c s = StatusService.findStatus(r.CurrentState__c); // SOQL in loop
    update r;                                                  // DML in loop
}
```

Bulk-safe form to write instead:

```apex
// ✅ 1 query to load, in-memory validation, 1 DML to write
Map<Id, X__c> recordMap = new Map<Id, X__c>([
    SELECT Id, /* every field the downstream logic reads */
    FROM X__c
    WHERE Id IN :ids AND RecordStatus__c != 'delete'
]);

for (Id id : ids) {                       // validate in memory, no SOQL
    if (!recordMap.containsKey(id)) {
        throw new ServiceException('X not found: ' + id);
    }
}

// resolve related records in bulk too — collect parent ids, query once:
Set<Id> stateIds = new Set<Id>();
for (X__c r : recordMap.values()) stateIds.add(r.CurrentState__c);
Map<Id, Status__c> statusMap = new Map<Id, Status__c>([
    SELECT Id, /* ... */ FROM Status__c WHERE Id IN :stateIds
]);

List<X__c> toUpdate = new List<X__c>();
for (X__c r : recordMap.values()) {
    Status__c s = statusMap.get(r.CurrentState__c); // in-memory lookup
    // ... business logic ...
    toUpdate.add(r);
}
update toUpdate;                          // single bulk DML
```

---

### Step 3 — Place the bulk work in the right layer

Layering still applies (see `lwc-architecture`):

- The **controller** (`classes/controller/**`) stays thin and may do the one
  guard query (e.g. validate input ids exist).
- The heavy bulk SOQL/DML belongs in the **domain service**
  (`classes/domain/<Name>Service`).
- Bulkify whichever layer holds the loop — never move a loop to a different
  layer to "hide" it.

---

### Step 4 — Verify with the execution checklist

Before presenting the rewritten code, walk the checklist. If any row fails, go
back to Step 2:

| # | Check | Fix if it fails |
|---|-------|-----------------|
| 1 | Any `[SELECT]`, `findX`, or `requireXExists` inside a loop? | Move to one `IN :ids` query → `Map<Id,SObject>`. |
| 2 | Any `insert`/`update`/`delete`/`upsert` inside a loop? | Accumulate into a `List` and DML once after the loop. |
| 3 | Per-record guard called in a loop? | Replace with a single bulk query + `containsKey` validation. |
| 4 | Related/parent records fetched per row? | Collect parent ids, query once into a map, look up in memory. |
| 5 | Does the SELECT list cover every field used downstream? | Add missing fields so no follow-up query is needed. |
| 6 | Same functional behaviour & error messages preserved? | Keep per-id `containsKey` validation for "not found" errors. |

---

## Resources

### Reference rewrite

`docs/deleteTickets-SOQL-Optimization.docx` — worked example of this skill
applied to `ManageBacklogController.deleteTickets`: SOQL **49 → 26**, CPU
**≈ −47%**, identical behaviour. Use as the canonical "before/after" for any
new bulkification.

### Reference governor test

`classes/controller/.../ManageBacklogControllerGovernorTest.cls` — template for
measuring `Limits.getQueries()`, `getDmlStatements()`, `getDmlRows()`,
`getCpuTime()`, `getHeapSize()` before and after the bulk call. Use as the
template when proving a bulkification win (see Optional Logic below).

### Salesforce synchronous limits (the limits this skill protects)

| Limit | Sync cap | N+1 failure mode |
|---|---:|---|
| SOQL queries | 100 | `Too many SOQL queries: 101` |
| DML statements | 150 | `Too many DML statements` |
| CPU time | 10,000 ms | `Apex CPU time limit exceeded` |

These `LimitException`s cannot be caught reliably and abort the whole
transaction. A loop that "works for 5 records" silently fails the day a real
batch (or a trigger firing in bulk) sends 100+.

---

## Optional Logic

### Prove the win with a governor test

When optimizing an existing hot path, prove the win the same way `deleteTickets`
was measured: wrap the call in `Test.startTest()/stopTest()` and snapshot
`Limits.getQueries()`, `getDmlStatements()`, `getDmlRows()`, `getCpuTime()`,
`getHeapSize()` immediately before and after the call. Expect SOQL/DML counts to
become **flat (constant)** as the input size grows — that flatness is the proof
the rewrite is O(1) and not just "a bit better at N=5".

### Integration with `apex-method-monitor` skill

After bulkifying, run the `apex-method-monitor` skill on the rewritten method to
append a fresh row to `docs/apex-method-report.md`. Re-profiling appends a new
dated row rather than overwriting, so the report captures the before/after
trend over time.

### When to skip

Skip the rewrite (Step 2) only when:

- The operation is genuinely single-record (one id in, one record out, no
  collection input).
- The code is asynchronous Batch Apex (`Database.Batchable`) that already
  chunks by design — its governor limits reset per batch.

Do **not** skip on the basis that "current callers only pass 5 records" —
triggers and future bulk callers will not respect that assumption.

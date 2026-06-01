---
name: apex-bulk-soql
description: >
  Rewrites N+1 Apex (one SOQL or one DML per record) into the bulk-safe
  shape: one query per object loaded into a `Map<Id, SObject>`, in-memory
  validation via `containsKey`/`get` that preserves the per-id error
  messages, and one DML per object run after the loop. The result is a
  method whose SOQL and DML counts stay flat as the input grows — so it
  survives triggers and bulk callers instead of failing the first time it
  sees 100 records. The "should this method be bulkified?" decision lives
  in `apex-governor-limit-guard`; this skill is the rewrite recipe that
  picks up once that answer is yes, plus the measurement that proves the
  rewrite is actually O(1).

  Use this when `apex-governor-limit-guard` flags an N+1 pattern, or when
  you are editing an existing bulk method in `classes/domain/<Name>Service`
  or `classes/controller/**` and want to preserve or improve its O(1)
  SOQL/DML profile. Skip it for genuinely single-record operations and for
  async Batch Apex that already chunks by design. See
  `docs/deleteTickets-SOQL-Optimization.docx` for the canonical
  before/after on this codebase (SOQL 49 → 26, CPU ≈ −47%, identical
  behaviour).
---

# Apex Bulk SOQL

Turns an N+1 pattern (one query/DML per record) into O(1) queries and DML —
independent of how many records the request carries. Numbers always come
from real bulk-safe rewrites, not estimates.

The "should I bulkify this?" decision belongs to the
[[apex-governor-limit-guard]] skill. This skill picks up after that decision
is yes, and produces the rewrite + the measurement that proves it worked.

---

## Instructions

### Step 1 — Rewrite into the bulk-safe form

Apply the **three rules** in order. Every bulk method must satisfy all three:

1. **One query per object type, not per record.** Collect ids into a
   `Set<Id>`, query once with `WHERE Id IN :ids` (or the relevant lookup
   field), and load the result into a `Map<Id, SObject>`. Select **every
   field** the consuming code reads, so no follow-up query is needed — but
   nothing more, so heap stays bounded.
2. **Validate and look up in memory.** Loop over the *input collection* and
   use `map.containsKey(id)` for existence and `map.get(id)` for lookups.
   This is CPU only — zero extra SOQL. It preserves per-record error
   messages (e.g. `throw new ServiceException('Ticket not found: ' + id)`).
3. **One DML per object type.** Build a `List<SObject>` of everything to
   write, then `update`/`insert`/`delete` the whole list once — never inside
   a loop.

Anti-pattern to detect:

```apex
// N+1: one SOQL per element, and/or one DML per element
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
// 1 query to load, in-memory validation, 1 DML to write
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

### Step 2 — Place the bulk work in the right layer

Layering still applies (see [[lwc-architecture]]):

- The **controller** (`classes/controller/**`) stays thin and may do the one
  guard query (e.g. validate input ids exist).
- The heavy bulk SOQL/DML belongs in the **domain service**
  (`classes/domain/<Name>Service`).
- Bulkify whichever layer holds the loop — never move a loop to a different
  layer to "hide" it.

---

### Step 3 — Hand back to the guard for verification

Once the rewrite is in place, the [[apex-governor-limit-guard]] execution
checklist is the verification step. Run it before presenting the code; if
any row fails, return to Step 1.

---

## Resources

### Reference rewrite

`docs/deleteTickets-SOQL-Optimization.docx` — worked example of this skill
applied to `ManageBacklogController.deleteTickets`: SOQL **49 → 26**, CPU
**≈ −47%**, identical behaviour. Use as the canonical "before/after" for any
new bulkification.

### Reference governor test

`classes/controller/.../ManageBacklogControllerGovernorTest.cls` — template
for measuring `Limits.getQueries()`, `getDmlStatements()`, `getDmlRows()`,
`getCpuTime()`, `getHeapSize()` before and after the bulk call. Use as the
template when proving a bulkification win (see Optional Logic below).

---

## Optional Logic

### Prove the win with a governor test

When optimizing an existing hot path, prove the win the same way
`deleteTickets` was measured: wrap the call in
`Test.startTest()/stopTest()` and snapshot `Limits.getQueries()`,
`getDmlStatements()`, `getDmlRows()`, `getCpuTime()`, `getHeapSize()`
immediately before and after the call. Expect SOQL/DML counts to become
**flat (constant)** as the input size grows — that flatness is the proof
the rewrite is O(1) and not just "a bit better at N=5".

### Integration with `apex-method-monitor` skill

After bulkifying, run the [[apex-method-monitor]] skill on the rewritten
method to append a fresh row to `docs/apex-method-report.md`. Re-profiling
appends a new dated row rather than overwriting, so the report captures the
before/after trend over time — including CPU and heap, the two limits most
often blown by a regression.

### When to skip

Skip the rewrite only when:

- The operation is genuinely single-record (one id in, one record out, no
  collection input).
- The code is asynchronous Batch Apex (`Database.Batchable`) that already
  chunks by design — its governor limits reset per batch.

Do **not** skip on the basis that "current callers only pass 5 records" —
triggers and future bulk callers will not respect that assumption.

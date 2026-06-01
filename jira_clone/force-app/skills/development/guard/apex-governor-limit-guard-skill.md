---
name: apex-governor-limit-guard
description: >
  Guardrail that REFUSES to let synchronous Apex ship when it would hit a
  governor limit at scale — CPU time, SOQL queries, DML statements, or heap
  size. Whenever YOU (the AI) write or edit Apex that touches more than one
  record, run the detection signals and the execution checklist below —
  silently, without the user asking. If any signal matches, the method will
  N+1 under real load and must be rewritten via the [[apex-bulk-soql]] skill
  before you present the code.

  TRIGGER (apply silently) when writing or editing Apex and ANY of these is
  true: a method accepts a `List<...>`, `Set<...>`, or `Map<...>` of
  ids/records; there is a `for`/`while` loop whose body contains a SOQL
  `[SELECT ...]`, a query method (`findX`, `requireXExists`, `getX`), or a
  DML statement (`insert`/`update`/`delete`/`upsert`); the work is described
  as bulk / batch / "delete tickets", "update statuses", "load by ids", "for
  each ... query/save"; you call a per-record guard (e.g.
  `DomainCorrectness.requireXExists(id)`) once per element of a collection.

  SKIP when the operation is genuinely single-record (one id in, one record
  out and no collection), or the code is asynchronous Batch Apex
  (`Database.Batchable`) already chunking by design — its governor limits
  reset per batch.
---

# Apex Governor Limit Guard

A `LimitException` (CPU, SOQL, DML, or heap) cannot be caught reliably and
aborts the whole transaction. A loop that "works for 5 records" silently
fails the day a real batch — or a trigger firing in bulk — sends 100+. This
guard runs at **write time** because the runtime signal arrives too late: by
the time you see `Apex CPU time limit exceeded` in a debug log, the
transaction has already been rolled back in production.

This is the **detection half** of the bulk-Apex discipline. Its job is to
decide whether a method will breach a governor limit; the actual rewrite
recipe lives in [[apex-bulk-soql]].

---

## Instructions

### Step 1 — Detect the limit-breaking pattern

Before finalizing any Apex method that reads or writes more than one record,
scan it for the signals below. Each signal maps to the governor limit it
will eventually breach. If **any** match, the method must be rewritten via
the [[apex-bulk-soql]] skill:

| # | Signal | Limit it breaches first | Example |
|---|--------|---|---------|
| 1 | `[SELECT ...]` inside a `for`/`while` loop | SOQL queries (100) + CPU | `for (Id id : ids) { [SELECT ... WHERE Id = :id]; }` |
| 2 | `insert`/`update`/`delete`/`upsert` inside a loop | DML statements (150) + CPU | `for (X__c r : recs) { update r; }` |
| 3 | Per-record guard called per element | SOQL queries (100) + CPU | `for (Id id : ids) { DomainCorrectness.requireXExists(id); }` |
| 4 | Helper method (`findX`, `getX`, `requireXExists`) called per element | SOQL queries (100) + CPU | `for (X__c r : recs) { StatusService.findStatus(r.CurrentState__c); }` |
| 5 | Related/parent records fetched per row | SOQL queries (100) + CPU | `for (X__c r : recs) { [SELECT ... FROM Parent__c WHERE Id = :r.Parent__c]; }` |
| 6 | `SELECT` that loads wide rows × large collections without narrowing the field list | Heap size (6 MB) | `[SELECT FIELDS(ALL) FROM X__c WHERE ...]` over thousands of rows |

If none match (e.g. one id in, one record out, narrow field list), the
method is single-record safe — let it through.

---

### Step 2 — Verify with the execution checklist

After applying the rewrite from [[apex-bulk-soql]], walk this checklist
before presenting the code. If any row fails, send it back through the
rewrite:

| # | Check | Limit protected | Fix if it fails |
|---|-------|---|-----------------|
| 1 | Any `[SELECT]`, `findX`, or `requireXExists` inside a loop? | SOQL + CPU | Move to one `IN :ids` query → `Map<Id,SObject>`. |
| 2 | Any `insert`/`update`/`delete`/`upsert` inside a loop? | DML + CPU | Accumulate into a `List` and DML once after the loop. |
| 3 | Per-record guard called in a loop? | SOQL + CPU | Replace with a single bulk query + `containsKey` validation. |
| 4 | Related/parent records fetched per row? | SOQL + CPU | Collect parent ids, query once into a map, look up in memory. |
| 5 | Does the SELECT list cover every field used downstream — and nothing more? | SOQL + Heap | Add missing fields so no follow-up query is needed; drop fields that are not read so heap stays bounded. |
| 6 | Same functional behaviour & error messages preserved? | (correctness) | Keep per-id `containsKey` validation for "not found" errors. |

---

## Resources

### Salesforce synchronous limits (what this guard protects)

| Limit | Sync cap | Failure mode |
|---|---:|---|
| CPU time | 10,000 ms | `Apex CPU time limit exceeded` |
| SOQL queries | 100 | `Too many SOQL queries: 101` |
| DML statements | 150 | `Too many DML statements` |
| Heap size | 6 MB | `Apex heap size too large` |

CPU is the failure mode that bites first in practice: even when SOQL/DML
counts are technically legal, the per-iteration overhead of querying inside
a loop drives CPU past 10,000 ms on real batch sizes. Heap is the quieter
killer — it shows up when a bulk rewrite over-selects fields or holds the
whole result set in memory longer than it needs to.

---

## Optional Logic

### Do not skip on "current callers only pass 5 records"

Triggers and future bulk callers will not respect that assumption. The only
valid skips are the two listed in the SKIP clause above: genuinely
single-record operations, or asynchronous Batch Apex that already chunks by
design.

### After the rewrite

Once the method passes Step 2, the [[apex-bulk-soql]] skill covers the
measurement step (governor-limit test) and the optional
[[apex-method-monitor]] follow-up that appends a fresh row to
`docs/apex-method-report.md` — including the heap snapshot, so the heap
budget is tracked alongside CPU/SOQL/DML.

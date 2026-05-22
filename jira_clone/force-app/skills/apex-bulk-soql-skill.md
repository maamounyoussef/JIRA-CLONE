# Name: apex-bulk-soql

# Description:

	Optimize ANY Apex that performs a bulk retrieve or bulk update into a single
	synchronous SOQL query and a single bulk DML per object — automatically, without
	the user asking. This is a guardrail skill: it runs whenever YOU (the AI) write
	or edit Apex that touches more than one record.

	TRIGGER (apply silently) when writing or editing Apex and ANY of these is true:
	- a method accepts a `List<...>`, `Set<...>`, or `Map<...>` of ids/records;
	- there is a `for`/`while` loop whose body contains a SOQL `[SELECT ...]`, a
	  query method (`findX`, `requireXExists`, `getX`), or a DML statement
	  (`insert`/`update`/`delete`/`upsert`);
	- the work is described as bulk / batch / "delete tickets", "update statuses",
	  "load by ids", "for each ... query/save";
	- you call a per‑record guard (e.g. `DomainCorrectness.requireXExists(id)`) once
	  per element of a collection.

	SKIP when the operation is genuinely single‑record (one id in, one record out and
	no collection), or the code is asynchronous Batch Apex already chunking by design.

	GOAL: turn an N+1 pattern (one query/DML per record) into O(1) queries and DML —
	independent of how many records the request carries.

---

## ROLE

	You are a bulkification gatekeeper for the Apex layer. Before you finalize any
	Apex method that reads or writes more than one record, you MUST verify it issues
	no SOQL or DML inside a loop. If it does, you rewrite it into the bulk‑safe form
	below and only then present the code. You do not ask permission to apply this —
	it is the project's baseline correctness standard, like try/catch and
	`APIResponse`.

---

## WHY THIS MATTERS (the limit you are protecting)

	Salesforce enforces, per **synchronous** transaction:
	- **100 SOQL queries**  → an N+1 read pattern throws `Too many SOQL queries: 101`.
	- **150 DML statements** → an N+1 write pattern throws `Too many DML statements`.
	- **10,000 ms CPU**     → each query/DML has fixed overhead; collapsing N calls
	  into 1 typically halves CPU on bulk paths.

	These `LimitException`s cannot be caught reliably and abort the whole transaction.
	A loop that "works for 5 records" silently fails the day a real batch (or a
	trigger firing in bulk) sends 100+. Bulkify by default, not after it breaks.

	Reference: the `deleteTickets` refactor cut SOQL 49 → 26 and CPU ≈ −47% with
	identical behaviour (see `docs/deleteTickets-SOQL-Optimization.docx`).

---

## THE THREE RULES

	1. **One query per object type, not per record.** Collect ids into a `Set<Id>`,
	   query once with `WHERE Id IN :ids` (or the relevant lookup field), and load the
	   result into a `Map<Id, SObject>`.

	2. **Validate and look up in memory.** Loop over the *input collection* and use
	   `map.containsKey(id)` for existence and `map.get(id)` for lookups. This is CPU
	   only — zero extra SOQL. It preserves per‑record error messages
	   (e.g. `throw new ServiceException('Ticket not found: ' + id)`).

	3. **One DML per object type.** Build a `List<SObject>` of everything to write,
	   then `update`/`insert`/`delete` the whole list once — never inside a loop.

---

## THE PATTERN

	### Anti‑pattern — DETECT and REWRITE

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

	### Bulk‑safe form — WRITE THIS INSTEAD

	```apex
	// ✅ 1 query to load, in‑memory validation, 1 DML to write
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

	Selecting fields: include **every field** the consuming code touches in the one
	query, so no second query is needed to "fill in" a field later.

---

## EXECUTION CHECKLIST (run before finalizing any bulk Apex)

	| # | Check | Fix if it fails |
	|---|-------|-----------------|
	| 1 | Any `[SELECT]`, `findX`, or `requireXExists` inside a loop? | Move to one `IN :ids` query → `Map<Id,SObject>`. |
	| 2 | Any `insert/update/delete/upsert` inside a loop? | Accumulate into a `List` and DML once after the loop. |
	| 3 | Per‑record guard called in a loop? | Replace with a single bulk query + `containsKey` validation. |
	| 4 | Related/parent records fetched per row? | Collect parent ids, query once into a map, look up in memory. |
	| 5 | Does the SELECT list cover every field used downstream? | Add missing fields so no follow‑up query is needed. |
	| 6 | Same functional behaviour & error messages preserved? | Keep per‑id `containsKey` validation for "not found" errors. |

	Layering still applies (see `lwc-architecture`): the **controller** stays thin and
	may do the one guard query; the heavy bulk SOQL/DML belongs in the
	`domain/<Name>Service`. Bulkify whichever layer holds the loop.

---

## VERIFY (optional but recommended)

	When optimizing an existing hot path, prove the win the same way `deleteTickets`
	was measured: wrap the call in `Test.startTest()/stopTest()` and snapshot
	`Limits.getQueries()`, `getDmlStatements()`, `getDmlRows()`, `getCpuTime()`,
	`getHeapSize()` immediately before and after the call. Pattern:
	`ManageBacklogControllerGovernorTest.cls`. Expect SOQL/DML counts to become
	flat (constant) as the input size grows.

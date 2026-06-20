% Apex Bulk SOQL Optimization — `deleteTickets`
% Jira Clone — Performance Report
% Generated 2026-05-22

# 1. Summary

The `ManageBacklogController.deleteTickets` method was profiled for governor‑limit
consumption using a dedicated test class
(`ManageBacklogControllerGovernorTest`). Profiling revealed an **N+1 SOQL
anti‑pattern**: the method issued one SOQL query *per ticket* instead of a single
bulk query.

After refactoring the per‑ticket existence check into a **single bulk SOQL query**,
SOQL usage dropped from **49 to 26 queries** and CPU time fell by roughly **47%**,
with identical functional behaviour.

| Metric | Before | After | Change |
|---|---:|---:|---:|
| SOQL queries | 49 | 26 | **−23 (−47%)** |
| CPU time (ms) | 272 / 200 | 131 / 119 | **≈ −47%** |
| Heap (bytes) | 1,079 | 1,015 | −64 |
| DML rows processed | 25 | 25 | unchanged |
| DML statements | 2 | 2 | unchanged |

*(All measured for a single transaction deleting 24 tickets — the controller's
per‑call cap.)*

---

# 2. The Problem — N+1 SOQL inside a loop

The original controller validated each ticket individually inside a `for` loop.
Every iteration called `DomainCorrectness.requireTicketExists(ticketId)`, and that
guard runs its own `SELECT`:

```apex
// BEFORE — one SOQL query per ticket (N queries for N tickets)
List<Ticket__c> tickets = new List<Ticket__c>();
for (String ticketId : ticketIds) {
    tickets.add(DomainCorrectness.requireTicketExists(ticketId)); // SELECT ... LIMIT 1
}
List<Sprint__c> updatedSprints = TicketService.deleteTickets(tickets);
```

For 24 tickets this is **24 separate queries** just to load the records, before any
business logic runs. Combined with the downstream service‑layer queries, the
transaction consumed **49 of the 100 SOQL queries** allowed per synchronous
transaction.

### Why this is dangerous

* **Governor limits.** Salesforce allows only **100 SOQL queries per synchronous
  transaction**. An N+1 pattern scales linearly with input size — a larger batch (or
  a trigger firing in bulk) hits the ceiling and throws
  `System.LimitException: Too many SOQL queries: 101`, which cannot be caught
  reliably and aborts the whole transaction.
* **CPU & latency.** Each query has fixed overhead. Collapsing 24 round‑trips into 1
  removed roughly half the CPU time (272 ms → 131 ms).
* **Not bulk‑safe.** The same anti‑pattern in a trigger context would fail as soon as
  a data load touched more than ~100 records.

---

# 3. The Solution — a single bulk query + in‑memory validation

Replace the per‑ticket query with **one** query using `WHERE Id IN :ticketIds`, load
the results into a `Map<Id, Ticket__c>`, then validate every requested id against the
map **in memory** (CPU only — no extra SOQL):

```apex
// AFTER — one SOQL query for all tickets, validation done in memory
Map<Id, Ticket__c> ticketMap = new Map<Id, Ticket__c>([
    SELECT Id, Name, Summary__c, Description__c, Priority__c,
           CurrentState__c, AssignedTo__c, Creator__c, Ticket_Type__c,
           Epic__c, Sprint__c, RecordStatus__c, StoryPoint__c,
           StartDate__c, EndDate__c
    FROM Ticket__c
    WHERE Id IN :ticketIds AND RecordStatus__c != 'delete'
]);

for (String ticketId : ticketIds) {
    if (!ticketMap.containsKey(ticketId)) {
        throw new ServiceException('Ticket not found: ' + ticketId);
    }
}

List<Sprint__c> updatedSprints = TicketService.deleteTickets(ticketMap.values());
```

Key points:

1. **One query regardless of batch size.** `Id IN :ticketIds` fetches all rows in a
   single SELECT.
2. **`Map<Id, SObject>` constructor** is populated directly from the query, giving
   O(1) existence checks.
3. **Validation stays strict.** Looping over the *input ids* and checking
   `containsKey` reproduces the original "Ticket not found" behaviour without any
   per‑row SOQL.
4. **Same DML profile.** DML rows (25) and statements (2) are unchanged — only the
   read path was optimized.

---

# 4. Measured Results (raw debug logs)

**Before — 24 tickets:**

```
CPU time (ms)      : 272 / limit 10000   (2nd run: 200)
Heap (bytes)       : 1079 / limit 6000000
SOQL queries       : 49 / limit 100
DML rows processed : 25 / limit 10000
DML statements     : 2 / limit 150
```

**After — 24 tickets:**

```
CPU time (ms)      : 131 / limit 10000   (2nd run: 119)
Heap (bytes)       : 1015 / limit 6000000
SOQL queries       : 26 / limit 100
DML rows processed : 25 / limit 10000
DML statements     : 2 / limit 150
```

The measurement isolates the call alone: `Test.startTest()` opens a fresh governor
context (excluding all data setup), and before/after `Limits.*` snapshots capture
only what `deleteTickets` consumes.

---

# 5. Further Optimization Opportunity

26 SOQL queries still remain. The next N+1 lives **inside**
`TicketService.deleteTickets`, which calls `StatusService.findStatus(t.CurrentState__c)`
once per ticket (and `findSprintById` per sprint):

```apex
for (Ticket__c t : tickets) {
    ...
    Status__c status = StatusService.findStatus(t.CurrentState__c); // per-ticket SOQL
    ...
}
```

**Recommended fix:** collect all `CurrentState__c` and `Sprint__c` ids first, query
`Status__c` and `Sprint__c` once each into maps, then look them up in memory inside
the loop. That would bring the transaction close to a small constant number of
queries (≈ 3–4) regardless of how many tickets are deleted.

---

# 6. The Advantage — you can now raise the deletion cap

The deletion limit exists *because of* the old N+1 pattern. With the old code each
ticket cost ~2 SOQL queries (its own `requireTicketExists` plus the downstream
`findStatus`), so the 100‑query ceiling was reached at roughly **49 tickets** — the
`InputSecurityValidator.validateTicketDeletionLimit` cap of **24** was a deliberately
conservative safety margin against that.

Now that the controller's load is a **single constant query**, the per‑ticket cost
drops sharply, so the same governor budget covers far more tickets:

| Stage | SOQL per N tickets | Max tickets before 100‑query limit | Safe cap to set |
|---|---|---:|---:|
| Old (per‑ticket load + per‑ticket findStatus) | ≈ `2N + 1` | ≈ 49 | 24 (current) |
| **Now (bulk load, findStatus still per‑ticket)** | ≈ `N + 2` | ≈ 98 | **~75–90** |
| After §5 fix (everything bulk) | ≈ `3–4` constant | thousands* | limited only by DML rows / CPU |

\* Once SOQL is constant, the binding limit becomes **DML rows (10,000)** and **CPU
(10,000 ms)**, not query count.

**What this means in practice:**

* **Immediately** you can raise `validateTicketDeletionLimit` from 24 to roughly
  **75** (a safe margin under the ~98 ceiling) with no further code changes — the CPU
  also dropped ~47%, leaving headroom there too.
* **After completing the §5 fix**, SOQL stops scaling with batch size entirely, so the
  cap could be lifted to **hundreds or thousands**, bounded only by the 10,000 DML‑row
  and CPU limits rather than by query count.
* The deletion limit is therefore no longer dictated by an inefficiency — it becomes a
  deliberate product/UX choice, not a technical workaround.

> To raise it, change the threshold in `InputSecurityValidator.validateTicketDeletionLimit`
> (currently `> 24`). Re‑run `ManageBacklogControllerGovernorTest` with the new batch
> size to confirm SOQL/CPU stay within limits before shipping.

---

# 7. The General Rule (applies to all Apex)

> **Never put SOQL or DML inside a loop.** Query once with `IN :collection` into a
> `Map<Id, SObject>`, do all validation/lookups in memory, and perform one DML per
> object type on the whole list.

This is enforced going forward by the **`apex-bulk-soql`** skill, which automatically
reviews any Apex that performs a bulk retrieve or bulk update and rewrites it into a
single‑query / single‑DML form.

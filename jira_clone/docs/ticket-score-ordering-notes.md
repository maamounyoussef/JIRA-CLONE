# Ticket Ordering with `Score__c` — Notes

## 1. The Goal

We want users to **drag and drop tickets** in the backlog and inside each
sprint, and have the new order **stick** between sessions.

## 2. What we used to do

Before this change, ticket lists were ordered purely by the existing
`Priority__c` picklist, with `EndDate__c` as a tiebreaker:

```sql
ORDER BY Priority__c ASC, EndDate__c DESC
```

That gave us priority *bands* (Critical → High → Medium → Low) but **no way
for a user to put one ticket above another**. To influence position, a user
had to bump the ticket's priority, which corrupted reporting. There was no
per-ticket position field at all.

## 3. The Main Solution

Give every ticket a small **string score** (`Score__c`). When tickets are
sorted ASC by that string, they appear in the right order. To "move" a
ticket, we give it a new score that sits **between** the two strings it
should land between — no other ticket has to change.

## 4. Why a *string* score, not a *number* score? (design study)

A numeric score was the obvious alternative. Two variants, both rejected:

1. **Whole numbers (`1, 2, 3, ...`)** — inserting a ticket between positions
   1 and 2 forces the system to **shift every following ticket by one** so a
   slot opens up. **O(N) work per move**, **O(N) DML rows**, and it gets
   slower as the project grows.
2. **Decimals (take the midpoint)** — drop a ticket between two others and
   give it the average. Looks elegant: `(1 + 2) / 2 = 1.5`, then `1.25`,
   then `1.125`… but **64-bit float precision runs out fast**. The workbook
   `midpoint_sequence.xlsx` shows that starting from `a=1, b=2` the gap
   between successive midpoints collapses to zero in **51 steps** — after
   which the system is forced back into renumbering. ~50 drops in the same
   spot is well within a real backlog's lifetime.

**Strings have no such ceiling.** Between `"0"` and `"1"` we can always
insert `"01"`. Between `"0"` and `"01"` we can insert `"001"`. Lex order
has infinite room. The work is **O(1) per move** — one field update, one
row.

### The 3 advantages (text score vs the numeric alternative)

| # | Advantage | Numeric (renumber) | Text score *(chosen)* |
|---|---|---|---|
| 1 | **Query performance** | Saving a reorder updates **N rows**. | One read for the neighbour, one write for the moved ticket. |
| 2 | **Apex CPU time** | Build a list of every following ticket in memory, mutate each one, then `update`. The loop burns CPU before any DML runs. | One assignment (`movedTicket.Score__c = newScore`) then one `update`. Essentially free. |
| 3 | **Memory / heap in one transaction** | All N tickets must be in heap at once to be `update`d — heap grows with sprint size. | One `Ticket__c` in heap, no matter how big the sprint is. |

CPU and heap savings matter even **without looking at the database**, because
Salesforce governor limits cap both. The string design makes the operation
governor-proof: a sprint with 5 tickets costs the same as a sprint with
5,000.

## 5. The Simple Flow

There are only three moments where the score matters:

**a) When we *create* a ticket** → it goes to the bottom of its list.

   - Look up the **biggest** score currently in the same sprint (or, for a
     backlog ticket, the same project's backlog).
   - If the list is empty → new score = `"0"`.
   - Otherwise → new score = the biggest score with its **last character
     bumped up by one** (e.g. `"4"` → `"5"`, `"01"` → `"02"`).

**b) When we *list* tickets** → just order by score ASC.

   ```sql
   ORDER BY Score__c ASC NULLS LAST
   ```

**c) When we *move* a ticket** → caller tells us "put this ticket right after
this *beforeTicket*".

   - **beforeTicket is given** → find the ticket that currently sits right
     after beforeTicket (the "successor"), and set the moved ticket's score
     to `beforeTicket.score + successor.score` (concatenate the two strings).
     If there is no successor (beforeTicket is the last one), fall back to
     "bump the last character", same trick as creation.
   - **beforeTicket is `null`** → user dropped the ticket on top of the list.
     Take the first ticket's score and use the **previous ASCII character** of
     its first letter (e.g. `"0"` → `"/"`, because `'/'` is ASCII 47 and `'0'`
     is ASCII 48). That new string sorts before everything else.

## 6. A Tiny Example

Sprint with three tickets created one after the other:

| Ticket | Score |
|---|---|
| ticket 1 | `"0"` |
| ticket 2 | `"1"` |
| ticket 3 | `"2"` |

**Move ticket 3 right after ticket 1** (`beforeTicket = ticket1`).

1. Successor of ticket 1 is ticket 2 (score `"1"`).
2. New score for ticket 3 = `"0"` + `"1"` = **`"01"`**.

Sorted ASC, the list is now:

| Position | Ticket | Score |
|---|---|---|
| 1 | ticket 1 | `"0"` |
| 2 | **ticket 3** | `"01"` |
| 3 | ticket 2 | `"1"` |

Why does this work? `"0"` < `"01"` (because `"0"` is a prefix of `"01"`), and
`"01"` < `"1"` (because at the first character `'0' < '1'`). Ticket 3 lands
exactly between ticket 1 and ticket 2 — and **no other ticket was updated.**

**Move ticket 3 to the top** (`beforeTicket = null`).

1. The first ticket's score is `"0"`.
2. Previous ASCII character of `'0'` is `'/'`.
3. New score for ticket 3 = **`"/"`**.

Now ticket 3 is first because `'/'` (ASCII 47) sorts before `'0'` (ASCII 48).

## 7. Indexes that Make This Fast

Three indexes work together on `Ticket__c`:

| Index | What it speeds up | Why it exists |
|---|---|---|
| **`Id`** (built‑in primary key) | `requireTicketExists(ticketId)` — the very first thing every controller does. | The caller (LWC) can send *any* ticket id, but we **cannot trust the sprint id** it sends along. Sprint membership might be stale on the client. So we never accept `sprintId` as a parameter for these flows — we look up the ticket by id, and read the sprint **off the freshly‑loaded record**. The id index keeps that lookup O(log N). |
| **`Sprint__c`** (single‑field, custom) | Every "give me everything in this sprint" query: the successor lookup, the "first ticket" lookup, the max‑score lookup. | Once we have the ticket in hand from the id lookup, `ticket.Sprint__c` is **guaranteed consistent**. We can use it in `WHERE Sprint__c = :ticket.Sprint__c` and get an index seek instead of a full‑table scan. |
| **`Sprint__c + Score__c`** (composite, custom) | Paged listing in the UI: `WHERE Sprint__c = :id ORDER BY Score__c ASC LIMIT n OFFSET m`. | The composite lets the DB walk straight down the score order *within one sprint*, so paging never has to sort all tickets in memory. |

### Why this "look up by id, then trust the loaded record" pattern matters

It is repeated all over [DomainCorrectness.cls](../force-app/main/default/classes/domain/DomainCorrectness.cls):

```apex
public static Ticket__c requireTicketExists(String ticketId) {
    List<Ticket__c> rows = [
        SELECT Id, ..., Sprint__c, ..., Score__c
        FROM Ticket__c
        WHERE Id = :ticketId AND RecordStatus__c != 'delete'
        LIMIT 1
    ];
    ...
}
```

The function takes only the ticket id — never the sprint id — even when the
caller "knows" both. After this returns, downstream code uses `ticket.Sprint__c`
freely, knowing it matches the actual database state. That is what lets
`moveTicketPosition` then do its sprint‑scoped queries against an indexed
column without re‑validating anything.

## 8. Where it Lives in our Code

| Part | File / method | One‑line role |
|---|---|---|
| The field | [`Score__c.field-meta.xml`](../force-app/main/default/objects/Ticket__c/fields/Score__c.field-meta.xml) | Required `Text(255)` column on `Ticket__c`. |
| Score on insert | `prepareTicketForInsert` + `nextScoreForInsert` in [TicketService.cls](../force-app/main/default/classes/domain/TicketService.cls) | Looks up the biggest existing score in the same sprint/backlog and bumps it. |
| Sorting | `loadBacklogTickets`, `getActiveTicketsBySprintOrderByPriorityAsc`, `loadActiveTicketsBySprint` in [TicketService.cls](../force-app/main/default/classes/domain/TicketService.cls) | All end with `ORDER BY Score__c ASC NULLS LAST`. |
| Reordering | `moveTicketPosition(movedTicket, beforeTicket)` in [TicketService.cls](../force-app/main/default/classes/domain/TicketService.cls) | The function described in flow (c) above. |
| Helpers | `incrementLastChar`, `previousAsciiChar`, `findSuccessor`, `findFirst`, `projectTicketTypeIds` (`private` in `TicketService`) | Tiny utilities the two main methods use. |
| Exposed to LWC | `moveTicketPosition(movedTicketId, beforeTicketId)` in [ManageBacklogController.cls](../force-app/main/default/classes/controller/managebacklog/ManageBacklogController.cls) | The `@AuraEnabled` endpoint a drag‑and‑drop component calls. |
| Tests | `testMoveTicketPositionWithBeforeTicket`, `testMoveTicketPositionWithNullBeforeTicket` in [TicketServiceTest.cls](../force-app/main/default/classes/domain/TicketServiceTest.cls) | Verify the two flows from section 5. |

## 9. Things to Remember

- The score is **scoped per sprint** (or per project for the backlog). Moving a
  ticket *across* sprints is a different operation (`moveTicketToSprint`).
- "beforeTicket" means **the ticket that will appear *before* the moved one in
  the new order** — the moved ticket lands *after* it.
- `Score__c` is required. Brand‑new orgs are fine; orgs with pre‑existing
  ticket data need a one‑time backfill before any update hits those rows.
- The `before + successor` concat trick is simple on purpose. In rare edge
  cases (when the successor string starts with the before string and then
  continues with a character smaller than the before string's first character)
  the ordering can break — if you ever see it, swap to a midpoint algorithm.

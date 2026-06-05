# Pather — Add Functionality FAQ (shared question iteration)

The ordered questions for adding a new interactive, data-persisting
functionality to a parent LWC. This file is **questions only** — the calling
pather skill decides whether to enter, supplies the mandatory guides, and does
all the analysis (coverage check, layering, checklist, code emission, CSS)
after these answers are collected.

## Step prefix (avoid number conflicts)

This FAQ does **not** own a fixed step number. It is invoked from inside a
calling pather skill that already has its own `Step 1 / 2 / 3 …`, so a literal
`Step 2.1` here would collide with the caller's `Step 2`. The caller passes the
step number it reached when it calls this FAQ — call it `<prefix>` — and every
question below is read as `<prefix>.1 … <prefix>.8`.

Example: if a pather skill calls this FAQ at its **Step 2**, then `<prefix>` is
`2` and the questions run as `Step 2.1 … Step 2.8`.

Ask one question per message, in order. Print the tracker line at the top of
every question so the loop state is always visible:

```
[Component: <parentName> | Functionality: <name> | Step <prefix>.<n>]
```

---

**`.1` — Parent LWC.** Ask which parent LWC (name or path) this functionality is
for. Do **not** ask or assume whether it already exists — only capture the name
so the work is scoped and the tracker line can be filled.

**`.2` — Sub-components.** Ask the user which sub-components this new
functionality applies to. The user names them; do not infer from the template.

**`.3` — User stories.** Ask the user for the user stories that apply to this
new functionality. Each operation (Load / Update / Create / Delete — or any
combination) must have its **own** user story. The user writes the stories —
never invent them.

**`.4` — Behavior prompt.** Ask:

> *"Give me the functionality behavior prompt. It must cover every user
> story."*

Record the answer and continue. (The calling skill verifies coverage.)

**`.5` — Validation rules.** Run the shared step defined in
[ask-user-for-lwc-validation.md](./ask-user-for-lwc-validation.md). Do not
inline the branches here — load that file and follow it verbatim.

**`.6` — Data state.** Ask which state provides the data for this
functionality. The user supplies the source **object** and **field name** on
that object.

**`.7` — Reusable base component.** Ask whether an existing base LWC component
(`c-ao-input`, `c-ao-btn`, `c-ao-combobox`, any `lightning-*`) should be used
instead of writing the UI from scratch. The user provides the name. If they say
"none", record that and continue.

**`.8` — Apex method resolution.** Run the shared question sub-step defined in
[apex-method-resolution.md](./apex-method-resolution.md). Keep the `<prefix>.8`
tracker line (with sub-questions `<prefix>.8.1` / `.8.2` / `.8.3`) and follow its
branches and Creation Sub-Loop verbatim. This gathers the method and — when a
method is created — **whether it is cacheable**. It only records that answer; it
does **not** decide `@wire` vs imperative (that is the pather's job).

---

## Return to the calling pather skill

When `.1` through `.8` are all answered, **hand these FAQ answers back to the
calling pather skill**. This FAQ asks questions only — it does not decide
`@wire` vs imperative and it never references a `guide/` file. The pather skill
resumes at its own next step and does all of that from these answers: the
call-style decision (via its own `guide/` reference), the behavior-coverage
check, the layering map, the execution checklist, code emission, and the
optional CSS.

---

## Reading a combined prompt

A user may answer several of these questions up front in one prompt. When that
happens:

1. Walk the prompt top-to-bottom and assign each block to its matching question.
2. For every question already **present**, record the answer and move on — do
   not re-ask it.
3. For every question that is **missing**, ask that one question (and only that
   one) using the tracker line, then continue.
4. Do not invent answers for missing questions, and do not skip them — control
   only returns to the caller once all questions are resolved.

Worked example of such a combined prompt:

```
─── [Parent LWC] ──────────────────────────────────────────────────────────
add interactive-with data persistance in pather
lwc pather : @force-app/main/default/lwc/manageBacklog/

─── [Sub-components] ───────────────────────────────────────────────────────
sub components : [ Backlog in that start in line 192 in manageBacklog.html ,
                   WORK (Sprints) in line 63 in manageBacklog.html ].

─── [User stories: one per operation] ─────────────────────────────────────
user stories :
As a user I need to move a ticket below another ticket in backlog so it
  should be shown before it.
As a user I need to move a ticket below another ticket in the same sprint
  so it should be shown before it.

─── [Behavior prompt: must cover every user story above] ──────────────────
Behaviors (apply to both Backlog and Sprint containers):
1. Drag & Drop — Move After Another Ticket
   - A user can drag any ticket and drop it onto another ticket in the same
     container.
   - On drop, the dragged ticket is repositioned immediately below the
     target ticket.
2. Drag & Drop — Move to First Position
   - A user can drag a ticket and drop it at the top of the container.
   - The ticket becomes the first item in the list.

Before:             After (drag 4 → drop on 1):
ticket 1            ticket 1
ticket 2            ticket 4   ← landed below ticket 1
ticket 3            ticket 2
ticket 4            ticket 3

Visual Feedback During Drag:
- Ghost/preview element follows the cursor.
- A highlighted drop indicator line appears below the hovered ticket
  showing where the ticket will land.
- Top drop zone becomes visually active when dragging near the top of the
  container.

Acceptance Criteria:
| # | Scenario                                  | Expected Result            |
|---|-------------------------------------------|----------------------------|
| 1 | Drag ticket 4, drop on ticket 1 (sprint)  | Order becomes: 1, 4, 2, 3  |
| 2 | Drag ticket A to top drop zone (sprint)   | A becomes first in sprint  |
| 3 | Drag ticket 4, drop on ticket 1 (backlog) | Order becomes: 1, 4, 2, 3  |
| 4 | Drag ticket A to top drop zone (backlog)  | A becomes first in backlog |

─── [Validation rules: derived from Constraints & Notes] ──────────────────
Constraints & Notes:
- Reordering is within the same container only.
- Order changes must persist (reflect in backend/store, not just UI state).

─── [Data state: NOT in prompt → still ASK] ───────────────────────────────
(the prompt does not name the state object + field that backs ordering;
 ask the user before continuing)

─── [Reusable base component: NOT in prompt → still ASK] ──────────────────
(the prompt does not name a base component to reuse for the drop wrapper /
 indicator / top zone; ask the user before continuing)

─── [Apex method resolution: Branch A (class + method given)] ─────────────
Apex method to call :
ManageBacklogController.moveTicketPosition for both
```


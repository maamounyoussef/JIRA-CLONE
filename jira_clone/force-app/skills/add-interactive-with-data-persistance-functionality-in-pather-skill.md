---
name: add-interactive-with-data-persistance-functionality-in-pather
description: >
  Add an interactive-with-data-persistence functionality to an EXISTING parent
  LWC component. Drives a six-question interview that captures the
  sub-components involved, the user stories (one per operation), the full
  behavior prompt (verified to cover every story by semantic comparison), the
  validation rules (placed in a sibling `<name>Validator.js` file, never
  inline), the backing data state (source object + field), and any reusable
  base component — all BEFORE any code is emitted.

  TRIGGER (apply silently) when the user asks to add a NEW functionality to an
  EXISTING parent LWC component AND that component already uses Apex — either
  it imports at least one `@salesforce/apex/<Class>.<method>` symbol, OR it
  declares a `@wire` adapter. Treat the presence of ANY one such import or
  wire as sufficient evidence; stop checking once one is found.

  SKIP when the target component has no Apex import AND no `@wire` (this skill
  assumes data persistence is in scope), when the change is purely cosmetic
  (CSS / label text / template-only), or when the work is creating a
  brand-new component rather than extending an existing one.
---

# Add Interactive-with-Data-Persistence Functionality in Parent

Turns a free-form "add this new functionality to my existing parent" request
into a disciplined interview that captures the sub-components, user stories,
behavior, validations, data source, and reusable building blocks **before**
any code is written. Skipping the interview produces handlers that don't
match the user's stories, mix validation into the parent (instead of a
sibling validator), duplicate UI primitives that already exist as base
components, or load data from the wrong state — all of which surface as
rework once the user reviews the implementation.

---

## Instructions

### Step 1 — Detect the interview entry point

Before any questions, confirm BOTH conditions are true:

1. The target is an **existing** parent LWC component (not a brand-new one).
2. That component **already uses Apex** — it imports at least one
   `@salesforce/apex/<Class>.<method>` symbol, OR declares a `@wire` adapter.
   One occurrence is enough; stop searching after the first match.

If either check fails, this is not the right skill — exit silently. Otherwise
begin the per-functionality interview in Step 2.

Interview discipline (non-negotiable):

```
[Component: <parentName> | Functionality: <name> | Step 2.<N>]
```

- Print the tracker line above at the top of **every** question. If you
  cannot fill it in, you have lost state — reconstruct it before doing
  anything else.
- ONE question per message. Never present two steps together. Never
  pre-answer a later step.
- Do not skip steps. Walk 2.1 → 2.6 in order.
- No code emitted until every step is answered.
- **Never invent a user story or a behavior detail.** The user writes those.

---

### Step 2 — Run the interview

**Step 2.1 — Sub-components.** Ask the user which sub-components this new
functionality applies to. The user names them; do not infer from the
template.

**Step 2.2 — User stories.** Ask the user for the user stories that apply to
this new functionality. Each operation (Load / Update / Create / Delete — or
any combination) must have its **own** user story. The user writes the
stories — never invent them.

**Step 2.3 — Behavior prompt.** Ask:

> *"Give me the functionality behavior prompt. It must cover every user
> story."*

Verify coverage by **semantic comparison**, not keyword matching:

- If every user story from Step 2.2 is covered → proceed to Step 2.4.
- If a story is **not** covered, reply with this exact template:
  > *"The following user story is not covered: `<quote the story verbatim>`.
  > Please provide the behavior prompt again, including this part."*
- Never suggest the missing behavior. Repeat until full coverage is reached.

**Step 2.4 — Validation rules.** Ask the user which validations must run
**before any Apex call**. The user provides them. Validations live in a
sibling `<parentName>Validator.js` file alongside the parent — never inline
inside a handler.

**Step 2.5 — Data state.** Ask which state provides the data for this
functionality. The user supplies the source **object** and **field name** on
that object.

**Step 2.6 — Reusable base component.** Ask whether an existing base LWC
component (`c-ao-input`, `c-ao-btn`, `c-ao-combobox`, any `lightning-*`)
should be used instead of writing the UI from scratch. The user provides the
name. If they say "none", record that and continue.

**Step 2.7 — Apex method resolution.** *"Which Apex method should handle this?
(A) class + method + line, (B) point to a folder/class and AI finds it, (C)
method doesn't exist — create it."*
- *Branch A:* user supplied the line — record `<ApexClass>.<method>` and skip
  verification entirely. **→ Final Output.**
- *Branch B:* search the named location, identify the method, confirm. **→
  Final Output.**
- *Branch C:* run the **Creation Sub-Loop** below.
> *Creation Sub-Loop (Branch C).* Ask **Step 2.7.1** (*"What should the
> controller do?"*) — then parse the answer for any other class/method it
> references. For each referenced symbol that doesn't exist, recurse: *"You
> mentioned `<Class>.<method>`, which doesn't exist. What should it do?"*
> Continue until no description references an unresolved class/method. Track
> depth in the tracker line (`[... | Step 2.7.1 | depth 2: FooSvc.bar]`). Then
> ask **Step 2.7.2** (*"Where should the controller live?"*) for every method
> created during the recursion.

---

### Step 3 — Place the new code in the right layer

After the interview, the resulting code must split across layers as follows:

| Concern | File |
|---|---|
| Functionality handler (event handler, Apex call, state update) | The existing parent `.js` |
| Validations (Step 2.4) | Sibling `<parentName>Validator.js` — create the file if it does not yet exist |
| UI primitives | The base component chosen in Step 2.6; do not re-implement |
| Sub-component wiring (Step 2.1) | The existing parent `.html` template |
| Apex method | Existing controller method if it fits; otherwise a new method in the existing controller |

---

### Step 4 — Verify with the execution checklist

Before emitting any code, walk the checklist. If any row fails, fix it first.

| # | Check | Fix if it fails |
|---|---|---|
| 1 | Does every user story from Step 2.2 have at least one handler or path in the generated code? | Add the missing handler / path. |
| 2 | Is every validation from Step 2.4 in `<parentName>Validator.js`, not inline in the parent? | Move it to the sibling validator file. |
| 3 | Is the data loaded from the exact `<object>.<field>` named in Step 2.5? | Re-point the read to that field. |
| 4 | If a base component was named in Step 2.6, is it the one used in the template? | Replace any hand-rolled markup with that base component. |
| 5 | Is every Apex call gated by the validator (no validator pass → no Apex call)? | Add `if (!Validator.<rule>(...)) return;` (or equivalent) before the call. |
| 6 | Is parent state updated from the Apex **response data**, never optimistically? | Move the state mutation inside `.then()` / the wired-function body. |
| 7 | Is the every sub-component from Step 2.1 wired into the template? | Add the missing `<c-...>` tag with its props/handlers. |

---

## Resources

### Prompt template example


```
─── [Step 1 — Entry point: existing parent LWC] ───────────────────────────
add interactive-with data persistance in pather
lwc pather : @force-app/main/default/lwc/manageBacklog/

─── [Step 2.1 — Sub-components] ───────────────────────────────────────────
sub components : [ Backlog in that start in line 192 in manageBacklog.html ,
                   WORK (Sprints) in line 63 in manageBacklog.html ].

─── [Step 2.2 — User stories: one per operation] ──────────────────────────
user stories :
As a user I need to move a ticket below another ticket in backlog so it
  should be shown before it.
As a user I need to move a ticket below another ticket in the same sprint
  so it should be shown before it.

─── [Step 2.3 — Behavior prompt: must cover every user story above] ───────
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

─── [Step 2.4 — Validation rules: derived from Constraints & Notes] ───────
Constraints & Notes:
- Reordering is within the same container only.
- Order changes must persist (reflect in backend/store, not just UI state).

─── [Step 2.5 — Data state: NOT in prompt → still ASK] ────────────────────
(the prompt does not name the state object + field that backs ordering;
 ask the user before continuing)

─── [Step 2.6 — Reusable base component: NOT in prompt → still ASK] ───────
(the prompt does not name a base component to reuse for the drop wrapper /
 indicator / top zone; ask the user before continuing)

─── [Step 2.7 — Apex method resolution: Branch A (class + method given)] ──
Apex method to call :
ManageBacklogController.moveTicketPosition for both
```

How to parse a prompt like this:

1. Walk the prompt top-to-bottom and assign each block to its interview step.
2. For every step that is **present**, record the answer and move on — do
   not re-ask.
3. For every step that is **missing**, ask that one question (and only that
   one) using the tracker line, then continue.
4. Do not invent answers for missing steps, and do not skip them — code may
   only be emitted once all six steps (2.1 → 2.6) plus 2.7 are resolved.

### Interview tracker template

```
[Component: manageBacklog | Functionality: <name> | Step 2.<N>]
```

Drop this at the top of every interview question so the loop state is always
visible to both the user and to any agent that resumes the conversation.

### Validator file shape

The sibling `<parentName>Validator.js` should export pure functions, one per
validation rule from Step 2.4. The parent imports them by name and calls them
before any Apex invocation — no Apex import or state mutation lives in the
validator.

```javascript
// <parentName>Validator.js
export function isSummaryValid(summary) { ... }
export function isAssigneeAllowed(assigneeId, projectMembers) { ... }
```

```javascript
// <parentName>.js
import { isSummaryValid } from './<parentName>Validator';

handleCreateTicket(event) {
    if (!isSummaryValid(event.detail.summary)) {
        this.dispatchEvent(new ShowToastEvent({ ... }));
        return;
    }
    createTicket({ ... }).then(res => { /* update state from res */ });
}
```

### When to skip

Skip the interview when:

- The target component has **no Apex import and no `@wire`** — this skill
  assumes data persistence is in scope.
- The change is **template-only** (CSS, layout, label text).
- The work is **creating a brand-new component** — use the component-creation
  skill instead.

Do **not** skip on the basis that "we'll just add the handler and validate
inside it" — inline validation in the parent is the exact failure mode this
skill exists to prevent.

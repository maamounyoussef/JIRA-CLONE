---
name: add-interactive-with-data-persistance-functionality-in-pather
description: >
  Contains the six-step interview (sub-components, user stories, behavior
  prompt, validation rules, backing data state, reusable base component) plus
  the Apex method resolution sub-step used when adding an interactive
  data-persisting functionality to an existing parent LWC. Also contains the
  layering map (handler → parent `.js`, validations → sibling
  `<name>Validator.js`, UI primitives → chosen base component, wiring →
  parent `.html`, Apex method → existing controller) and the optional
  `lwc-css-design` handoff.
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

### Step 0 — Run `lwc-architecture` first (MANDATORY)

Before any interview question in this skill, you MUST follow the
**`lwc-architecture`** skill
(`force-app/skills/development/architecture/lwc-architecture.md`) end-to-end.
That umbrella skill settles the architectural decisions BEFORE any UI
behavior is implemented or extended:

- Page vs. child (or inline section) — Q1
- Principal state shape — Q2
- `localStorage` entry keys + load call — Q3
- Apex methods: exist or to-create (+ Service + guards + test) — Q4
- Event names + payloads (children) — Q5
- Sidecar `<feature>Utils.js` / `<feature>Validator.js` needs — Step 2
- `meta.xml` exposure + targets — Step 2

Only after the `lwc-architecture` handoff checklist (its Step 4) is green do
you proceed to Step 1 of this skill. Never start the per-functionality
interview without those decisions settled — Steps 1–4 here assume them.

---

### Step 0b — Mandatory LWC guards for this parent (apply without being asked)

This is a **pather (parent)** component, so BOTH guards below are mandatory on
every functionality that emits JS/HTML/CSS. They run silently — never gated on
a user question:

- **`lwc-apex-loading`** (`force-app/skills/development/guard/lwc-apex-loading.md`)
  — every user-initiated imperative Apex call (`apexMethod(...).then(...).catch(...)`)
  or `@wire`-with-function-handler is wired to the component's `isLoading`
  flag, with a `.loading-overlay` spinner stacked above modals/peek-panels in
  the HTML and CSS. Reuse the existing loading flag; never add a per-handler
  boolean.
- **`lwc-error-handling`** (`force-app/skills/development/guard/lwc-error-handling-skill.md`)
  — every failure path (Apex `.catch`, `@wire` error / `success === false`,
  synchronous validation failure) surfaces through `ShowToastEvent`
  (`variant: 'error'`), never a tracked inline `errorMessage` banner. Applies
  to new error paths added to this existing component too.

Each guard's own SKIP conditions still hold; when you skip one, state the
reason in the iteration message. Confirm both guards' completion checklists
pass before reporting the functionality done.

---

### Step 1 — Detect the interview entry point

Before any questions, confirm BOTH conditions are true:

1. The target is an **existing** parent LWC component (not a brand-new one).
2. That component **already uses Apex** — it imports at least one
   `@salesforce/apex/<Class>.<method>` symbol, OR declares a `@wire` adapter.
   One occurrence is enough; stop searching after the first match.

If either check fails, this is not the right skill — exit silently. Otherwise
begin the per-functionality interview in Step 2.

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

**Step 2.4 — Validation rules.** Run the shared step defined in
[shared/ask-user-for-lwc-validation.md](shared/ask-user-for-lwc-validation.md).
Do not inline the branches here — load that file and follow it verbatim.
Validations live in a sibling `<parentName>Validator.js` file alongside the
parent — never inline inside a handler.

**Step 2.5 — Data state.** Ask which state provides the data for this
functionality. The user supplies the source **object** and **field name** on
that object.

**Step 2.6 — Reusable base component.** Ask whether an existing base LWC
component (`c-ao-input`, `c-ao-btn`, `c-ao-combobox`, any `lightning-*`)
should be used instead of writing the UI from scratch. The user provides the
name. If they say "none", record that and continue.

**Step 2.7 — Apex method resolution.** Run the shared step defined in
[shared/apex-method-resolution.md](shared/apex-method-resolution.md). Do not
inline the branches here — load that file and follow it verbatim.

**Step 2.8 — Wire implementation.** Run the shared step defined in
[shared/how-to-handle-apex-call-implementation.md](shared/how-to-handle-apex-call-implementation.md).
Keep this skill's tracker line (substitute `Step 2.8`) and follow the
answer-to-action mapping in that file verbatim — the visibility-urgency
branch, the `connectedCallback` auto-wire question, and the
separate-`wired<State>` rule. Do not inline the branches here or invent a
fourth option.

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

Then also walk the shared state-management checklist (Rules 0–7) in
[shared/pather_lwc_state_management_checklist.md](shared/pather_lwc_state_management_checklist.md).
Fix any failing row there before emitting code.

---

### Step 5 — Optionally apply `lwc-css-design`

After the code is emitted and accepted, ASK the user via the interactive
`AskUserQuestion` tool (NOT plain text) whether to also apply the
**`lwc-css-design`** skill
(`force-app/skills/development/architecture/lwc-css-design.md`) to style the
new functionality. Frame it as a single yes/no choice (e.g. "Apply the
project's CSS design system to the new functionality now?" with options
"Yes, apply lwc-css-design" / "No, skip styling").

- Yes → follow `lwc-css-design` end-to-end: produce/update the parent
  `.css` file using the project's Atlassian/Jira palette, type scale,
  spacing, BEM naming, interactive-state recipes, and shared patterns
  (modal, peek panel, error banner, empty state, bulk bar, drag-and-drop).
- No → exit this skill.

Never invent CSS without invoking `lwc-css-design` — it codifies the
project's visual language so a new functionality blends with the rest of
`manageBacklog` / `ticketView` without any visual tuning.

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
   only be emitted once all six steps (2.1 → 2.6) plus 2.7 and 2.8 are
   resolved.

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

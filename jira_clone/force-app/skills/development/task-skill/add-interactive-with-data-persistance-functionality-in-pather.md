---
name: add-interactive-with-data-persistance-functionality-in-pather
description: >
  Entry point + analysis for adding an interactive, data-persisting
  functionality to an **existing** parent LWC. Owns the entry gate (existing
  parent that already uses Apex) and then runs the shared question iteration in
  shared/pather-add-functionality-faq.md; it does not contain the interview
  questions itself. From the returned answers it produces the implementation:
  the behavior-coverage check, the `@wire`-vs-imperative call-style decision
  (via lwc-apex-call-implementation-guide), the layering map (handler → parent
  `.js`, validations → sibling `<name>Validator.js`, UI primitives → chosen base
  component, wiring → parent `.html`, Apex method → existing controller), the
  execution checklist, and the optional `lwc-css-design-guide` handoff.
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

### Step 0 — Mandatory guides

This is a **pather (parent)** component. Apply each guide below per its own
`activation:` contract — see CLAUDE.md → "Mandatory‑guides step" for how
required / optional guides are read. Settle every matching guide before the
first interview question.

- **`lwc-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/lwc-path-architecture-guide.md`)
- **`lwc-apex-call-implementation-guide`** (`force-app/skills/development/task-skill/guide/lwc-apex-call-implementation-guide.md`)
- **`lwc-error-handling-guide`** (`force-app/skills/development/task-skill/guide/lwc-error-handling-guide.md`)
- **`pather_lwc_state_management_checklist-guide`** (`force-app/skills/development/task-skill/guide/pather_lwc_state_management_checklist-guide.md`)
- **`apex-path-architecture-guide`** (`force-app/skills/development/task-skill/guide/apex-path-architecture-guide.md`)

The project-wide soft-delete filter (`soql-exclude-deleted`) is **not** listed
here: it fires automatically from CLAUDE.md whenever a new or edited `SELECT`
touches a `RecordStatus__c` object, so no per-skill question gates it.

---

### Step 1 — Detect the interview entry point

Before any questions, confirm BOTH conditions are true:

1. The target is an **existing** parent LWC component (not a brand-new one).
2. That component **already uses Apex** — it imports at least one
   `@salesforce/apex/<Class>.<method>` symbol, OR declares a `@wire` adapter.
   One occurrence is enough; stop searching after the first match.

If either check fails, this is not the right skill — exit . Otherwise
begin the per-functionality interview in Step 2.

### Step 2 — Run the interview FAQ

Run the shared question iteration in
[shared/pather-add-functionality-faq.md](shared/pather-add-functionality-faq.md),
passing this step's number as the FAQ's prefix. That file owns its own
questions and order — do not inline, reorder, or reference its internal steps
here. Ask one question per message and follow it verbatim. When it hands the
collected answers back, continue to Step 3.

The FAQ returns these answers (by name): the **parent LWC**, the
**sub-components**, the **user stories**, the **behavior prompt**, the
**validation rules**, the **data state** (object + field), the **reusable
base component**, and the resolved **Apex method** with its **cacheability**.

**Behavior coverage check.** Verify by **semantic comparison**, not keyword
matching, that the behavior prompt covers every user story returned by the FAQ:

- If every user story is covered → proceed to Step 3.
- If a story is **not** covered, reply with this exact template:
  > *"The following user story is not covered: `<quote the story verbatim>`.
  > Please provide the behavior prompt again, including this part."*
- Never suggest the missing behavior. Repeat until full coverage is reached.

---

### Step 3 — Wire implementation

Run the shared step defined in
[guide/lwc-apex-call-implementation-guide.md](guide/lwc-apex-call-implementation-guide.md),
keeping this step's number in the tracker line. The Apex method and its
cacheability are already known (from the FAQ): that guide's Step 0 gate uses it
— **not cacheable → imperative call, skip the visibility-urgency question and
the `@wire` branches entirely; cacheable → `@wire` is available**, proceed to
the branch. Follow the answer-to-action mapping in that file verbatim — the
visibility-urgency branch, the `connectedCallback` auto-wire question, and the
separate-`wired<State>` rule. Do not invent a fourth option.

---

### Step 4 — Place the new code in the right layer

After the interview, the resulting code must split across layers as follows:

| Concern | File |
|---|---|
| Functionality handler (event handler, Apex call, state update) | The existing parent `.js` |
| The validation rules | Sibling `<parentName>Validator.js` — create the file if it does not yet exist |
| UI primitives | The chosen reusable base component; do not re-implement |
| Sub-component wiring | The existing parent `.html` template |
| Apex method | Existing controller method if it fits; otherwise a new method in the existing controller |

---

### Step 5 — Verify with the execution checklist

Before emitting any code, walk the checklist. If any row fails, fix it first.

| # | Check | Fix if it fails |
|---|---|---|
| 1 | Does every user story returned by the FAQ have at least one handler or path in the generated code? | Add the missing handler / path. |
| 2 | Is every validation rule in `<parentName>Validator.js`, not inline in the parent? | Move it to the sibling validator file. |
| 3 | Is the data loaded from the exact `<object>.<field>` named in the data-state answer? | Re-point the read to that field. |
| 4 | If a reusable base component was named, is it the one used in the template? | Replace any hand-rolled markup with that base component. |
| 5 | Is every Apex call gated by the validator (no validator pass → no Apex call)? | Add `if (!Validator.<rule>(...)) return;` (or equivalent) before the call. |
| 6 | Is parent state updated from the Apex **response data**, never optimistically? | Move the state mutation inside `.then()` / the wired-function body. |
| 7 | Is every sub-component wired into the template? | Add the missing `<c-...>` tag with its props/handlers. |

Then also walk the shared state-management checklist (Rules 0–7) in
[guide/pather_lwc_state_management_checklist-guide.md](guide/pather_lwc_state_management_checklist-guide.md).
Fix any failing row there before emitting code.

---

### Step 6 — Optionally apply `lwc-css-design-guide`

After the code is emitted and accepted, ASK the user via the interactive
`AskUserQuestion` tool (NOT plain text) whether to also apply the
**`lwc-css-design-guide`** skill
(`force-app/skills/development/task-skill/guide/lwc-css-design-guide.md`) to style the
new functionality. Frame it as a single yes/no choice (e.g. "Apply the
project's CSS design system to the new functionality now?" with options
"Yes, apply lwc-css-design-guide" / "No, skip styling").

- Yes → follow `lwc-css-design-guide` end-to-end: produce/update the parent
  `.css` file using the project's Atlassian/Jira palette, type scale,
  spacing, BEM naming, interactive-state recipes, and shared patterns
  (modal, peek panel, error banner, empty state, bulk bar, drag-and-drop).
- No → exit this skill.

Never invent CSS without invoking `lwc-css-design-guide` — it codifies the
project's visual language so a new functionality blends with the rest of
`manageBacklog` / `ticketView` without any visual tuning.

---

## Resources

The interview mechanics — the worked combined-prompt example, the rule for
skipping questions already answered in a prompt, and the interview tracker —
live with the FAQ that owns them:
[shared/pather-add-functionality-faq.md](shared/pather-add-functionality-faq.md).
This skill stays out of the FAQ's step structure.

### Validator file shape

The sibling `<parentName>Validator.js` should export pure functions, one per
validation rule the FAQ returned. The parent imports them by name and calls them
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

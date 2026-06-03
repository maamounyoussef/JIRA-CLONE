---
name: create-new-parent-lwc-component
description: >
  Contains the brand-new-parent ("pather") scaffold steps (component name,
  path, initial `.js` / `.html` / `.js-meta.xml`, lazy
  `<name>Validator.js`) and the outer iteration loop that, on each pass, asks
  the user to pick one of three paths — (A) add a new functionality, delegated
  to `add-interactive-with-data-persistance-functionality-in-pather` (with its
  "parent must already use Apex" entry check suppressed), (B) handle a
  child-dispatched event, delegated to `lwc-parent-event-handler-generator`,
  or (C) stop and run the final verification checklist. Also contains the
  optional `lwc-css-design` handoff at exit.
---

# Create New Parent LWC Component

Turns a free-form "I want a new parent LWC" request into an iteration loop
that, on each pass, asks the user to pick ONE of three paths — add a new
functionality, handle a child-dispatched event, or stop — and delegates to
the corresponding sub-skill. Doing this in a loop (instead of trying to
gather everything up front) keeps every functionality and every child event
walked through its full disciplined interview, with no skipped steps and no
mixed concerns.

This skill is the orchestration layer. It owns:

- The brand-new component scaffolding (name, path, initial files).
- The outer loop and its tracker line.
- The decision: which sub-skill handles this iteration.
- The "stop" exit.

It does **not** own the per-iteration interview questions — those live in
the sub-skills.

---

## Instructions

### Step 0 — Run `lwc-architecture` first (MANDATORY)

Before any question, scaffold step, or iteration in this skill, you MUST
follow the **`lwc-architecture`** skill
(`force-app/skills/development/architecture/lwc-architecture.md`) end-to-end.
That umbrella skill settles the architectural decisions BEFORE any UI
behavior is implemented:

- Page vs. child (or inline section) — Q1
- Principal state shape — Q2
- `localStorage` entry keys + load call — Q3
- Apex methods: exist or to-create (+ Service + guards + test) — Q4
- Event names + payloads (children) — Q5
- Sidecar `<feature>Utils.js` / `<feature>Validator.js` needs — Step 2
- `meta.xml` exposure + targets — Step 2

Only after the `lwc-architecture` handoff checklist (its Step 4) is green do
you proceed to Step 1 of this skill. Never start scaffolding or the outer
iteration loop without those decisions settled — Steps 1–3 here assume them.

---

### Step 0b — Mandatory LWC guards for this parent (apply without being asked)

This is a **pather (parent)** component, so BOTH guards below are mandatory on
every iteration that emits JS/HTML/CSS. They run silently — never gated on a
user question:

- **`lwc-apex-loading`** (`force-app/skills/development/guard/lwc-apex-loading.md`)
  — every user-initiated imperative Apex call (`apexMethod(...).then(...).catch(...)`)
  or `@wire`-with-function-handler is wired to the component's `isLoading`
  flag, with a `.loading-overlay` spinner stacked above modals/peek-panels in
  the HTML and CSS. Reuse the existing loading flag; never add a per-handler
  boolean.
- **`lwc-error-handling`** (`force-app/skills/development/guard/lwc-error-handling-skill.md`)
  — every failure path (Apex `.catch`, `@wire` error / `success === false`,
  synchronous validation failure) surfaces through `ShowToastEvent`
  (`variant: 'error'`), never a tracked inline `errorMessage` banner.

Each guard's own SKIP conditions still hold; when you skip one, state the
reason in the iteration message. Confirm both guards' completion checklists
pass before reporting the iteration done.

---

### Step 1 — Confirm the entry point and scaffold the new parent

Before the loop starts, confirm BOTH conditions are true:

1. The target is a **brand-new** parent LWC component (does **not** yet exist
   under `force-app/main/default/lwc/<name>/`).
2. The user wants to build it as a **parent** (it will contain sub-components
   and/or react to events from children), not as a leaf/child component.

If either check fails, this is not the right skill:

- Existing parent → use
  [add-interactive-with-data-persistance-functionality-in-pather](./add-interactive-with-data-persistance-functionality-in-pather.md).
- Child-only work → use the `lwc-child` skill.
- Template-only change → no skill needed.

Then ask the user (one question per message):

1. *"What is the new parent component's name (camelCase)?"*
2. *"Where should it live? (default: `force-app/main/default/lwc/<name>/`)"*

Scaffold the empty parent: `<name>.js`, `<name>.html`, `<name>.js-meta.xml`,
and a placeholder sibling `<name>Validator.js` (created lazily — only the
first time path A actually produces a validation rule).

> **Apex-presence override.** The sub-skill
> `add-interactive-with-data-persistance-functionality-in-pather` normally
> requires the parent to already import `@salesforce/apex/...` or declare a
> `@wire`. This skill **suppresses that check** because the parent is
> brand-new and the very first functionality is what introduces Apex. Treat
> the sub-skill's Step 1 as satisfied for the first iteration.

---

### Step 2 — Run the iteration loop

Each iteration begins with the **path-selection question**. Print the tracker
line at the top of every message in the loop so state is always visible:

```
[Parent: <componentName> | Iteration: <N> | Path: <pending|A|B|C>]
```



#### The path-selection question

Ask:

> *"For the next iteration on `<componentName>`, which path?
> (A) Add a new functionality — captures sub-components, user stories,
>     behavior, validations, data state, base component, and Apex.
> (B) Handle a child-dispatched event — picks `@wire` vs imperative,
>     gating field, and the state-update path.
> (C) Stop — finalise the parent and exit."*

Use the `AskUserQuestion` tool so the three paths are presented as discrete
choices.

#### Path A — Add a new functionality

Delegate to
[add-interactive-with-data-persistance-functionality-in-pather](./add-interactive-with-data-persistance-functionality-in-pather.md).

Apply its **Step 2.1 → Step 2.7** interview verbatim, then its layering
(Step 3) and checklist (Step 4). Use the sub-skill's tracker line format:

```
[Component: <componentName> | Functionality: <name> | Step 2.<N>]
```

Differences from the standalone sub-skill (because the parent is brand-new):

| Sub-skill behavior | Override in this orchestrator |
|---|---|
| Step 1 requires existing Apex import / `@wire` | **Suppressed** — proceed straight to Step 2.1. |
| Validator file must exist or be created | Create `<componentName>Validator.js` the first time path A produces a validation rule. |
| "Existing parent `.js` / `.html`" target files | Use the brand-new scaffold from Step 1 of this skill. |

When the sub-skill finishes (code emitted, checklist green), return to the
top of the loop with `Iteration: <N+1>`.

#### Path B — Handle a child-dispatched event

Delegate to
[lwc-parent-event-handler-generator](./lwc-parent-event-handler-generator.md).

Apply its **Step 0 → Step 10** interview for the chosen event, then its
layering (Step 3) and checklist (Step 4). Use the sub-skill's tracker line
format:

```
[Child: <name> | Event: <eventName> | Step <N>]
```

Notes for the brand-new-parent context:

- The sub-skill's Step 1 ("name the child component") still applies. The
  child must already exist (or be a known incoming dependency); if it does
  not, stop and direct the user to the `lwc-child` skill first.
- If the user pastes multiple events at once, queue them and walk each
  through the full Step 0 → Step 10 flow one at a time, returning to the
  top of *this* loop only after every queued event has been handled.

When the sub-skill finishes (code emitted, checklist green), return to the
top of the loop with `Iteration: <N+1>`.

#### Path C — Stop

End the loop. Before exiting, run the **Final Verification** in Step 3 of
this skill. If anything fails, fix it and re-confirm with the user, then
exit.

---

### Step 3 — Final verification before exit

When the user picks path C, walk this checklist over the full set of
iterations. If any row fails, fix it before exiting.

| # | Check | Fix if it fails |
|---|---|---|
| 1 | Does the parent exist at the scaffolded path with `.js`, `.html`, and `.js-meta.xml`? | Create the missing file. |
| 2 | If any path A iteration produced validation rules, does `<componentName>Validator.js` exist as a sibling and export pure functions? | Create the sibling file; move inline validations into it. |
| 3 | Is every dispatched child event from every path B iteration wired in the template via `on<event>={handler}`? | Add the missing attribute(s). |
| 4 | Is every Apex call (from path A or path B) gated by either a validator (path A) or the chosen `@wire` / imperative pattern (path B), with state updated from the **response data**, never optimistically? | Move state mutation inside `.then()` / the wired-function body. |
| 5 | Are derived child props exposed as getters (never duplicated into a new `@track` data state)? | Replace the `@track` with `get childProp() { return ...; }`. |
| 6 | Does every Apex method referenced by any iteration actually exist (Branch A/B) or get created via the Creation Sub-Loop (Branch C)? Branches A/B/C are defined once in [shared/apex-method-resolution.md](./shared/apex-method-resolution.md) and reused by path A's Step 2.7 and path B's Step 10. | Run the shared Creation Sub-Loop ([shared/apex-method-resolution.md](./shared/apex-method-resolution.md)) for any unresolved method. |
| 7 | Are project-wide instructions satisfied? — bulkified Apex (`apex-bulk-soql`), soft-delete filter on `RecordStatus__c`-bearing objects (`soql-exclude-deleted`), required-fields per `OBJECT_VALIDATION_LWC_APEX.md` (`object-required-fields`), and the thin controller → Service → `APIResponse` layering (`lwc-architecture`). | Apply the named skill on the offending code path. |

---

### Step 4 — Optionally apply `lwc-css-design`

After the final verification passes (the user picked path C and Step 3 is
green), ASK the user via the interactive `AskUserQuestion` tool (NOT plain
text) whether to also apply the **`lwc-css-design`** skill
(`force-app/skills/development/architecture/lwc-css-design.md`) to style the
new parent. Frame it as a single yes/no choice (e.g. "Apply the project's
CSS design system to the new parent component now?" with options "Yes,
apply lwc-css-design" / "No, skip styling").

- Yes → follow `lwc-css-design` end-to-end: produce the `<componentName>.css`
  file using the project's Atlassian/Jira palette, type scale, spacing, BEM
  naming, interactive-state recipes, and shared patterns (modal, peek panel,
  error banner, empty state, bulk bar, drag-and-drop).
- No → exit this skill.

Never invent CSS without invoking `lwc-css-design` — it codifies the
project's visual language so a new parent drops in next to `manageBacklog` /
`manageWorkflow` without any visual tuning.

---

## Resources

### Loop tracker template

```
[Parent: <componentName> | Iteration: <N> | Path: <pending|A|B|C>]
```

Drop this at the top of every path-selection question. Once the user has
picked a path, switch to the sub-skill's tracker line for the duration of
that iteration, then switch back when returning to the loop.

### Path → sub-skill map

| Path | User intent | Sub-skill | Tracker line during the iteration |
|---|---|---|---|
| A | Add new functionality (sub-components, stories, behavior, validations, data state, base component, Apex) | [add-interactive-with-data-persistance-functionality-in-pather](./add-interactive-with-data-persistance-functionality-in-pather.md) | `[Component: <name> \| Functionality: <fname> \| Step 2.<N>]` |
| B | Handle a `CustomEvent` from a child (choose `@wire` / imperative, gate, update state from response) | [lwc-parent-event-handler-generator](./lwc-parent-event-handler-generator.md) | `[Child: <name> \| Event: <eventName> \| Step <N>]` |
| C | Stop and finalise | — | `[Parent: <componentName> \| Iteration: <N> \| Path: C]` |

### Why an outer loop (instead of one mega-interview)

- Each iteration is **self-contained**: one functionality OR one event,
  walked through its full disciplined interview, emitting code at the end.
- The user can interleave functionalities and event handlers in any order
  — most real parents grow by alternating (add a functionality, wire a
  child event, add another functionality, wire another event).
- The "stop" exit is explicit, so the parent is never left in a
  half-interviewed state where the AI silently inferred the rest.

### When to skip

Skip this skill (and use a different one) when:

- The parent **already exists** — use
  `add-interactive-with-data-persistance-functionality-in-pather` (path A)
  or `lwc-parent-event-handler-generator` (path B) **directly**, without
  the outer loop.
- The work is in the **child** — use `lwc-child`.
- The work is **template-only** (CSS, layout, label text) and touches no
  Apex, no state, and no child-event wiring.

Do **not** skip on the basis that "I'll just scaffold the parent and add
everything ad-hoc later" — the failure modes the two sub-skills exist to
prevent (optimistic state, inline validation, wrong gating field,
duplicated child state, missing user-story coverage) all surface in the
ad-hoc path and produce rework once the user reviews the implementation.

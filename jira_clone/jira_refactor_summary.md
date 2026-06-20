# Jira-Style LWC Refactor — Summary

## 1. Original Prompt

> please eliminate the unecessary element tag that put just for design in all lwc component just igonore the `@force-app/main/default/classes/controller/manageTicketTracking/`, `@force-app/main/default/classes/controller/manageWorkflow/`, `@force-app/main/default/lwc/manageWorkflowForm/`, `@force-app/main/default/lwc/projectMember/`, `@force-app/main/default/lwc/projectSelector/`, `@force-app/main/default/lwc/workflowVisualizer/`.
>
> use a modern style that looks like jira:
>
> **Jira-Like Frontend Design Plan**
>
> **Visual Identity & Design System**
>
> **Color Palette**
> - Background: `#1D2125` (dark nav), `#FFFFFF` (main content), `#F4F5F7` (sidebar/panel bg)
> - Primary Blue: `#0052CC` (buttons, links, active states)
> - Accent: `#0065FF` (hover states)
> - Text: `#172B4D` (primary), `#6B778C` (secondary/muted)
> - Borders: `#DFE1E6`
> - Status chips: green `#00875A`, orange `#FF991F`, red `#DE350B`, purple `#6554C0`
>
> **Typography**
> - Font: `-apple-system, BlinkMacSystemFont, "Segoe UI"` — Jira uses system fonts for speed and neutrality
> - Base size: 14px, line-height 1.4
> - Headings: 20–24px, weight 600
>
> **Layout Structure**
> ```
> ┌──────────────────────────────────────────────────────┐
> │  TOP NAV (56px)  — Logo | Projects | Boards | Search │
> ├──────┬───────────────────────────────────────────────┤
> │      │  BREADCRUMB BAR                               │
> │ SIDE │───────────────────────────────────────────────┤
> │ BAR  │                                               │
> │(64px │         MAIN CONTENT AREA                     │
> │ col- │         (Board / Backlog / Issue Detail)       │
> │ laps)│                                               │
> │      │                                               │
> └──────┴───────────────────────────────────────────────┘
> ```
>
> **Core Components to Build**
>
> 1. **Top Navigation Bar** — Logo + product switcher icon, breadcrumb (`Projects > My Project > Board`), global search (`/` shortcut trigger), Create button (blue, pill shape), Avatar + notifications icon (right side).
> 2. **Left Sidebar** — Icon-based collapsed nav (64px wide), expandable to 240px with labels. Sections: Board, Backlog, Reports, Project Settings. Active state: blue left border + blue icon.
> 3. **Kanban Board** — Horizontal scrollable columns; column header: name + issue count badge; cards with issue key (`PROJ-123`), title, assignee avatar, priority icon, story points; drag-and-drop between columns (use a library like dnd-kit); column footer: "+ Create issue" link.
> 4. **Issue Card** — Priority icon (↑ high, = medium, ↓ low), issue type icon (bug 🐛, story 📖, task ✓), truncated title, bottom row: issue key (muted), assignee avatar (right-aligned). Hover: slight elevation shadow.
> 5. **Issue Detail Panel / Modal** — Slide-in right panel (50% width) OR full modal. Left: title (editable inline), description (rich text), comments. Right sidebar: status dropdown, assignee, reporter, priority, sprint, story points, labels. Status: pill dropdown with color-coded options.
> 6. **Backlog View** — Grouped list by sprint (collapsible sections). Each row: drag handle, issue type icon, key, title, assignee, story points, priority. Sprint header: name, dates, start/complete sprint button.
> 7. **Status Dropdown (pill-style)** — Rounded badge buttons: TO DO (gray), IN PROGRESS (blue), DONE (green). Click to cycle or open mini-dropdown.
>
> **Component States to Handle**
>
> | Component       | States                                               |
> | --------------- | ---------------------------------------------------- |
> | Buttons         | Default, Hover, Active, Disabled, Loading            |
> | Cards           | Default, Hover, Dragging, Selected                   |
> | Inputs          | Default, Focus, Error, Disabled                      |
> | Sidebar items   | Default, Hover, Active                               |
> | Dropdowns       | Closed, Open, Selected                               |
>
> **Recommended Tech Stack**
>
> | Layer         | Choice                                              |
> | ------------- | --------------------------------------------------- |
> | Framework     | React (JSX)                                         |
> | Styling       | Tailwind CSS utility classes OR CSS Modules         |
> | Icons         | `lucide-react` or Atlassian's icon set              |
> | Drag & Drop   | `@dnd-kit/core`                                     |
> | Rich Text     | `@tiptap/react` (for descriptions)                  |
> | State         | `useState` + `useReducer` (or Zustand for scale)    |
> | Routing       | React Router (Board / Backlog / Settings routes)    |
>
> so all the update related to html unecessary div and css

---

## 2. Task Breakdown

The work was tracked as a 15-item todo list (later collapsed to 13 component-level items after the read pass):

1. Read all targeted LWC HTML/CSS files
2. Establish shared Jira-like CSS variables and tokens
3. Refactor `aoBtn` HTML/CSS for Jira look
4. Refactor `aoCheckbox` HTML/CSS for Jira look
5. Refactor `aoCombobox` HTML/CSS for Jira look
6. Refactor `aoInput` HTML/CSS for Jira look
7. Refactor `aoCreateTicketModal` HTML/CSS
8. Refactor `aoTicketItem` HTML/CSS
9. Refactor `manageBacklog` HTML/CSS
10. Refactor `manageTicketTracking` HTML/CSS
11. Refactor `manageWorkflow` HTML/CSS
12. Refactor `manageWorkflowContainer` HTML
13. Refactor `project` HTML
14. Refactor `ticketBoardColumn` HTML/CSS
15. Refactor `ticketLinkedTo` HTML/CSS

**Ignored per the prompt:**
- `force-app/main/default/classes/controller/manageTicketTracking/`
- `force-app/main/default/classes/controller/manageWorkflow/`
- `force-app/main/default/lwc/manageWorkflowForm/`
- `force-app/main/default/lwc/projectMember/`
- `force-app/main/default/lwc/projectSelector/`
- `force-app/main/default/lwc/workflowVisualizer/`

**Method per component:**
1. Read the existing HTML and CSS.
2. Cross-check JS files for any class names referenced dynamically (`dropTargetClass`, `backlogDropClass`, `columnClass`, `cardWrapperClass`, `wrapperClass`, `fieldClass`, `computedClass`, etc.) so refactoring doesn't break bindings.
3. Identify wrapper `<div>`s that exist purely for cosmetic grouping vs. those carrying drag/drop handlers, dynamic classes, or layout semantics.
4. Remove the cosmetic-only wrappers; keep structural ones.
5. Replace SLDS modal scaffolding (`slds-modal`, `slds-modal__container`, `slds-modal__content`, `slds-modal__footer`, `slds-backdrop`) with a single flat `modal-backdrop` + `modal/header/content/footer` pattern.
6. Rewrite each component's CSS using the Jira design tokens (no shared file because LWC shadow DOM scopes styles per component — tokens applied consistently in each).

---

## 3. Final Summary

All 13 LWC components updated. Here's what changed:

### HTML — removed unnecessary wrappers:
- **`aoTicketItem`** — dropped `.icon-wrapper` div and the redundant `.epic-selection` wrapper; replaced 4 SLDS modals (`<section class="slds-modal">…<div class="slds-modal__container">…<div class="slds-modal__content">…<div class="slds-backdrop">`) with a single flat `modal-backdrop` + `modal/header/content/footer` pattern.
- **`aoCreateTicketModal`** — replaced SLDS modal scaffolding with the same flat modal pattern.
- **`manageBacklog`** — collapsed SLDS modal markup, switched panels to semantic `<section>`.
- **`manageTicketTracking`** — removed `.loading-spinner` and `.no-sprint-banner` div wrappers.
- **`manageWorkflow`** — removed several `<div class="slds-m-around_medium">` margin-only wrappers around alerts and inner items.
- **`manageWorkflowContainer`** — removed two wrapper divs around the back button and spinner.
- **`project`** — replaced SLDS form-element / form-element__control / notify scaffolding with a flat `form > label/input/actions` structure.
- **`ticketLinkedTo`** — removed `.form-field` / `.field-type` / `.field-ticket` wrapper divs, removed dead `<!-- Loading state -->` block.

### CSS — full Jira theme rewrite for all components:
- **Font:** `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto`
- **Colors:** `#0052CC` primary / `#0065FF` hover, `#172B4D` text / `#6B778C` muted, `#DFE1E6` borders, `#F4F5F7` panel bg, `#FAFBFC` subtle bg, status chips `#00875A` / `#FF991F` / `#DE350B` / `#6554C0`
- Replaced Neobrutalism hard borders + offset shadows with rounded 3–6px corners and soft elevation (`0 1px 2px` / `0 8px 24px rgba(9,30,66,…)`).
- **Inputs:** light gray fill (`#F4F5F7`) with blue focus ring (`box-shadow: 0 0 0 1px #4C9AFF`).
- **Modals:** dark backdrop (`rgba(9,30,66,0.54)`), white card with shadow, border-top footer.

### Preserved JS-bound dynamic classes:
`dropTargetClass`, `backlogDropClass`, `columnClass`, `cardWrapperClass`, `wrapperClass`, `fieldClass`, `computedClass` and the `sprint-container` / `backlog-container` / `valid-target` / `drag-over` / `transition-box--active|pending` selectors all still match.

### Skipped per instructions:
`manageWorkflowForm`, `projectMember`, `projectSelector`, `workflowVisualizer`, and the two Apex controller folders.

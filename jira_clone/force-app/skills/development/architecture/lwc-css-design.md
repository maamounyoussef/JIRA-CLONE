---
name: lwc-css-design
description: >
  Authoritative CSS design system for every Lightning Web Component in this
  project. Defines the color palette, typography, spacing, border-radius,
  shadow, transition, BEM naming, modal/overlay, empty-state, error-banner,
  and interactive-state conventions used by aoBtn, aoInput, aoCombobox,
  aoCheckbox, aoTicketItem, ticketView, manageBacklog, ticketBoardColumn,
  chooseProject, etc. Codifies an Atlassian/Jira-inspired look so every new
  component matches the existing visual language without re-deriving it.

  TRIGGER when creating a new LWC's `.css` file, restyling an existing LWC,
  adding a modal / overlay / empty-state / error banner / badge / pill,
  picking colors or font-sizes, or asking "what color should this be?",
  "how do I style this?", "what's the design system?".

  SKIP for SLDS-only styling that uses no custom CSS, or when the user
  explicitly asks for a different visual language (e.g. dark mode, a new
  brand). Do not apply to `.html` template structure decisions — this skill
  is purely visual.
---

# LWC CSS Design System

This project follows an **Atlassian/Jira-inspired** visual language. Every
custom-styled LWC reuses the same palette, type scale, spacing, radii,
transitions, and component patterns documented below. The goal: a new
component should drop into [manageBacklog](../main/default/lwc/manageBacklog/),
[ticketView](../main/default/lwc/ticketView/), or a kanban column and feel
native without any visual tuning.

---

## 1. The non‑negotiable opening of every CSS file

Every component CSS file MUST start with a `:host` block that sets the font
family and (when relevant) the display and color. Layout-defining hosts also
set `display`.

```css
:host {
    display: block;                                /* or inline-flex, etc. */
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #172B4D;                                /* only on top-level pages */
}
```

- Pages / panels: `display: block`
- Inline controls (buttons, checkboxes): `display: inline-flex`
- Wrapping containers that need their own breakpoints: add
  `container-type: inline-size; container-name: <name>;` and use
  `@container <name> (max-width: ...)` (see [aoTicketItem.css:1-13](../main/default/lwc/aoTicketItem/aoTicketItem.css#L1-L13)).

NEVER let the browser default font ("Times" / serif) leak in — always set
the stack above on `:host`.

---

## 2. Color palette (use these hex values, do NOT invent new ones)

Pick from the table; never introduce an off-palette color without explicit
user approval.

| Role | Hex | Used for |
|---|---|---|
| **Brand primary** | `#0052CC` | Primary buttons, focused link text, active accents |
| Brand primary hover | `#0065FF` | Primary button hover, link hover |
| Brand primary active | `#0747A6` | Primary button :active, dark-tone link text |
| Focus ring | `#4C9AFF` | `outline`, `border-color` on focus, drop indicators |
| Subtle blue tint | `#DEEBFF` | Drop-target highlight, info badge bg, focus-bg cells |
| Stronger blue tint | `#B3D4FF` | Active drag-over column |
| **Ink (text primary)** | `#172B4D` | Body text, headings, labels-bold |
| Ink subdued | `#42526E` | Secondary text, secondary button text |
| Ink muted | `#6B778C` | Field labels, meta, placeholders, "section caps" |
| Ink placeholder | `#97A0AF` | `::placeholder`, disabled text |
| Border default | `#DFE1E6` | Card/panel/row borders, checkbox border |
| Border hover | `#C1C7D0` / `#B3BAC5` | Stronger hover border |
| Surface page | `#F4F5F7` | Page background, kanban column background |
| Surface card | `#FFFFFF` | Cards, panels, modals, rows |
| Surface subtle | `#FAFBFC` | Headers within a card, empty-state bg, footer bg |
| Surface hover | `#EBECF0` | Hover state on bare/ghost interactives |
| **Danger** | `#DE350B` | Error border-left, required-asterisk, error text |
| Danger deep | `#BF2600` | Error message text on light bg |
| Danger tint | `#FFEBE6` | Error-banner background |
| **Warning** | `#FF991F` | "Missing" badges, low-priority warnings |
| **Success** | `#00875A` | End-status left border on a card |
| Accent (epic) | `#6554C0` | Epic badge background |
| Overlay scrim | `rgba(9, 30, 66, 0.54)` | Modal backdrop |
| Overlay scrim light | `rgba(9, 30, 66, 0.30)` | Peek/loading overlay |
| Shadow color | `rgba(9, 30, 66, 0.25)` | Modal / hover-card shadows |

> Source of truth examples: [aoBtn.css](../main/default/lwc/aoBtn/aoBtn.css),
> [aoInput.css](../main/default/lwc/aoInput/aoInput.css),
> [manageBacklog.css](../main/default/lwc/manageBacklog/manageBacklog.css).

---

## 3. Typography scale

Use `rem` for page-level text and `em` for component-internal text that
must scale with container font-size (e.g. [aoTicketItem.css:9-13](../main/default/lwc/aoTicketItem/aoTicketItem.css#L9-L13)
sets `font-size: 14px` on `:host` then everything inside is `em`).

| Token | Size | Use |
|---|---|---|
| Page title | `1.5rem` / 600 | Splash titles, ticket summary in [ticketView.css:75-84](../main/default/lwc/ticketView/ticketView.css#L75-L84) |
| Panel title | `1.25rem` / 600 | `.panel__title`, `.modal__title` |
| Body emphasis | `0.9375rem` / 500–600 | Sprint name, item-button name |
| Body | `0.875rem` / 400 | Default control text, list rows |
| Small | `0.8125rem` / 400–500 | Sub-labels, dates, page indicator |
| Label / caps | `0.75rem` / 600, `text-transform: uppercase`, `letter-spacing: 0.04em`, color `#6B778C` | Field labels, kanban column header, section caps |
| Micro / badge | `0.6875rem` / 600, uppercase, `letter-spacing: 0.04em` | Status badges, sprint-status-badge |

Line-height: headings `1.25–1.3`, body / messages `1.4–1.5`, controls `1`.

---

## 4. Spacing, radii, borders

- **Page padding**: `24px`. Page gap between sections: `gap: 24px` on a
  vertical flex (see [manageBacklog.css:6-14](../main/default/lwc/manageBacklog/manageBacklog.css#L6-L14)).
- **Card / panel padding**: `20px 24px`.
- **Row padding**: `8px 10px` to `10px 14px`.
- **Control padding**: input `0.45em 0.6em`, button `0.45em 0.85em`
  (medium). Use `em` so it scales with the control's font-size.
- **Gap inside a control**: `0.4em`–`0.5em`.
- **Border**: always `1px solid #DFE1E6` on cards/panels/rows. Hover
  border bumps to `#C1C7D0` or `#B3BAC5`.
- **Border-radius scale**:
  - `3px` — buttons, inputs, small badges, drop-indicators
  - `4px` — link/row tiles, dashed-form wrapper, item buttons
  - `6px` — panels, modals, sprint container, kanban column, splash card
  - `12px` — pill counts (`ticket-count`)
- Never use `border-radius: 0` or values above `8px` (except the `12px`
  pill exception).

---

## 5. Shadows

Only used to lift surfaces above the page; never decorative.

| Use | Shadow |
|---|---|
| Card hover lift | `0 4px 8px rgba(9, 30, 66, 0.25)` |
| Card resting | `0 1px 2px rgba(9, 30, 66, 0.25)` |
| Modal / floating dialog | `0 8px 24px rgba(9, 30, 66, 0.25)` |
| Peek panel (dock right) | `-8px 0 24px rgba(9, 30, 66, 0.25)` |
| Splash card (subtle) | `0 4px 16px rgba(9, 30, 66, 0.08)` |
| Floating bulk bar (dark) | `0 4px 8px rgba(9, 30, 66, 0.25)` |
| Focus ring | `box-shadow: 0 0 0 1px #4C9AFF` (paired with `border-color: #4C9AFF`) |

---

## 6. Transitions

Two speeds only:

- **`0.1s ease`** — interactive feedback (hover, focus, active on buttons,
  inputs, ticket rows, drop indicators).
- **`0.15s ease`** — larger container state changes (panel border, kanban
  column drop-target, sprint container).

Properties to animate (chain them, do not use `all`):
`background-color, border-color, color, box-shadow`.

Never animate `transform` or `opacity` for hover. Use `transform` only for
**enter animations** (e.g. [manageBacklog.css:152-155](../main/default/lwc/manageBacklog/manageBacklog.css#L152-L155)
`peek-slide-in`).

---

## 7. BEM-style naming (mandatory)

Every component picks one short **block** prefix and uses BEM throughout.
Examples in the codebase:

| Component | Block prefix |
|---|---|
| aoBtn | `.ao-btn`, `.ao-btn--primary`, `.ao-btn__icon` |
| aoInput | `.ao-field`, `.ao-field__label`, `.ao-field--bare` |
| aoCombobox | `.ao-select`, `.ao-select__native`, `.ao-select__chevron` |
| aoCheckbox | `.ao-check`, `.ao-check__box`, `.ao-check__native` |
| ticketView | `.tv-` (e.g. `.tv-header`, `.tv-section__label`, `.tv-summary__input`) |
| chooseProject | `.splash`, `.splash__card`, `.splash__item-btn` |
| manageBacklog | `.panel`, `.modal`, `.sprint-…`, `.bulk-bar` (page-level, uses semantic names) |

Rules:
1. **Block**: `kebab-case`, 2–4 chars when shared across the app
   (`.ao-btn`), or semantic for page-level (`.sprint-container`,
   `.modal`).
2. **Element**: `block__element`.
3. **Modifier**: `block--modifier` or `block__element--state`.
4. Interactive **state** classes from JS use plain names without `--`:
   `.drag-over`, `.drop-target-active`, `.valid-target`, `.end-status`.
   That matches how the templates toggle them.
5. NEVER style by tag inside the component (`button { … }`) — always
   class-scoped. Exception: utility resets like
   `.tv-linked__toggle { background: none; border: none; }`.

---

## 8. Interactive states — required for every control

For ANY clickable / focusable / typeable element, define all four states.
Copy the recipes below; do not invent new ones.

### Button (see [aoBtn.css:6-43](../main/default/lwc/aoBtn/aoBtn.css#L6-L43))

```css
.x-btn {
    display: inline-flex; align-items: center; justify-content: center;
    gap: 0.4em;
    border-radius: 3px; cursor: pointer;
    transition: background-color 0.1s ease, color 0.1s ease,
                border-color 0.1s ease, box-shadow 0.1s ease;
}
.x-btn:hover:not(:disabled)  { background-color: #0065FF; }
.x-btn:active:not(:disabled) { background-color: #0747A6; }
.x-btn:focus-visible         { outline: 2px solid #4C9AFF; outline-offset: 2px; }
.x-btn:disabled              { opacity: 0.5; cursor: not-allowed; pointer-events: none; }
```

### Input / Select (see [aoInput.css:29-67](../main/default/lwc/aoInput/aoInput.css#L29-L67))

```css
.x-input {
    background-color: #F4F5F7;
    border: 1px solid transparent;       /* RESERVE space so focus doesn't jitter */
    border-radius: 3px;
    transition: background-color 0.1s ease, border-color 0.1s ease, box-shadow 0.1s ease;
}
.x-input:hover:not(:disabled):not(:focus) { background-color: #EBECF0; }
.x-input:focus    { background-color: #FFFFFF; border-color: #4C9AFF;
                    box-shadow: 0 0 0 1px #4C9AFF; outline: none; }
.x-input:disabled { background-color: #F4F5F7; color: #97A0AF;
                    cursor: not-allowed; opacity: 0.7; }
.x-input::placeholder { color: #97A0AF; font-weight: 400; }
```

> Atlassian pattern: idle inputs are **filled grey** with **transparent**
> border. Hover darkens the fill; focus inverts to white fill + blue
> ring. Do not give resting inputs a visible border.

### Bare / ghost / icon button

Transparent background; on hover go to `#EBECF0` background and `#172B4D`
text. See `.ao-btn--ghost` and `.toggle-btn` in
[manageBacklog.css:219-235](../main/default/lwc/manageBacklog/manageBacklog.css#L219-L235).

---

## 9. The seven shared patterns

Every page-level LWC reuses these. Copy the recipe verbatim; do not
freestyle.

### 9.1 Page wrapper

```css
.page-wrapper {
    display: flex; flex-direction: column; gap: 24px;
    padding: 24px;
    background-color: #F4F5F7;
    min-height: 100vh; box-sizing: border-box;
}
```

### 9.2 Panel / card

```css
.panel {
    background-color: #FFFFFF;
    border: 1px solid #DFE1E6;
    border-radius: 6px;
    padding: 20px 24px;
    transition: border-color 0.15s ease, background-color 0.15s ease;
}
.panel__title { font-size: 1.25rem; font-weight: 600; color: #172B4D;
                margin: 0 0 16px 0; line-height: 1.3; }
```

### 9.3 Error banner (red, left border)

```css
.error-box {
    display: flex; align-items: center; gap: 8px;
    padding: 12px 16px;
    background-color: #FFEBE6;
    border-left: 4px solid #DE350B;
    border-radius: 3px;
    color: #BF2600;
    font-size: 0.875rem;
    margin-bottom: 16px;
}
```

For inline field errors use `color: #DE350B; font-size: 0.75rem; margin: 0;`
(see [ticketView.css:68-72](../main/default/lwc/ticketView/ticketView.css#L68-L72)).

### 9.4 Empty state

```css
.empty-msg {
    padding: 16px; text-align: center;
    color: #6B778C; font-size: 0.875rem;
    background-color: #FAFBFC;
    border-radius: 3px;
    margin: 8px 0 0 0;
}
```

For dashed-bordered empty cell inside a list:
`border: 1px dashed #DFE1E6; background-color: #FFFFFF;`
(see [ticketView.css:214-223](../main/default/lwc/ticketView/ticketView.css#L214-L223)).

### 9.5 Modal (centered)

```css
.modal-backdrop {
    position: fixed; inset: 0;
    background-color: rgba(9, 30, 66, 0.54);
    z-index: 9000;
}
.modal {
    position: fixed; top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    z-index: 9001;
    width: min(560px, calc(100vw - 32px));
    max-height: calc(100vh - 64px);
    background-color: #FFFFFF;
    border-radius: 6px;
    box-shadow: 0 8px 24px rgba(9, 30, 66, 0.25);
    display: flex; flex-direction: column; overflow: hidden;
}
.modal--sm { width: min(420px, calc(100vw - 32px)); }
.modal__header  { padding: 20px 24px 8px; }
.modal__title   { font-size: 1.25rem; font-weight: 600; color: #172B4D; margin: 0; }
.modal__content { padding: 8px 24px 16px; overflow-y: auto;
                  display: flex; flex-direction: column; gap: 16px; }
.modal__footer  { padding: 16px 24px 20px;
                  display: flex; justify-content: flex-end; gap: 8px;
                  border-top: 1px solid #DFE1E6;
                  background-color: #FAFBFC; }
```

z-index layering: backdrop `9000`, dialog `9001`, loading overlay above
everything at `9999`.

### 9.6 Peek panel (right-docked sidebar)

```css
.peek-backdrop { position: fixed; inset: 0;
                 background-color: rgba(9, 30, 66, 0.30); z-index: 9000; }
.peek-panel {
    position: fixed; top: 0; right: 0; height: 100vh;
    width: 50%; min-width: 380px; max-width: 50vw;
    z-index: 9001;
    background-color: #FFFFFF;
    box-shadow: -8px 0 24px rgba(9, 30, 66, 0.25);
    display: flex; flex-direction: column; overflow: hidden;
    animation: peek-slide-in 0.18s ease-out;
}
@keyframes peek-slide-in { from { transform: translateX(100%); }
                           to   { transform: translateX(0); } }
```

### 9.7 Floating bulk-action bar (dark)

```css
.bulk-bar {
    display: flex; align-items: center; gap: 12px;
    padding: 10px 16px;
    background-color: #172B4D;             /* dark ink */
    border-radius: 6px;
    box-shadow: 0 4px 8px rgba(9, 30, 66, 0.25);
    position: fixed;
    width: min(560px, 80%);
    bottom: 24px; left: 50%; transform: translateX(-50%);
    z-index: 1000;
}
.bulk-bar span { font-size: 0.875rem; font-weight: 500; color: #FFFFFF; flex: 1; }
```

---

## 10. Badges & pills

| Variant | Background | Text | Notes |
|---|---|---|---|
| **Neutral / count pill** | `#DFE1E6` | `#42526E` | `border-radius: 12px; padding: 2px 8px;` — kanban column count, sprint-status |
| **Info / type** | `#DEEBFF` | `#0747A6` | `border-radius: 3px; uppercase; letter-spacing: 0.04em;` |
| **Epic** | `#6554C0` | `#FFFFFF` | Same shape, accent purple |
| **State chip (subtask)** | `#6B778C` | `#FFFFFF` | Compact uppercase pill |
| **Missing / warning** | transparent | `#FF991F` | Just text + icon, no fill |

Common badge mixin:
```css
.badge {
    border-radius: 3px;
    padding: 0.2em 0.5em;
    font-size: 0.6875rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    white-space: nowrap;
}
```

---

## 11. Drag-and-drop styling

Adopt these exact classes — `manageBacklog` and `ticketBoardColumn`
already toggle them from JS:

```css
.container.drop-target-active { border-color: #4C9AFF; background-color: #DEEBFF; }
.status-column.valid-target   { border-color: #4C9AFF; background-color: #DEEBFF; }
.status-column.drag-over      { border-color: #0052CC; background-color: #B3D4FF; }

.drop-indicator           { height: 3px; margin: 0 4px; border-radius: 2px;
                            background-color: transparent;
                            transition: background-color 0.1s ease; }
.drop-indicator--active   { background-color: #4C9AFF;
                            box-shadow: 0 0 0 1px rgba(76, 154, 255, 0.35); }

.top-drop-zone            { height: 10px; border: 1px dashed transparent;
                            transition: background-color 0.1s ease,
                                        border-color 0.1s ease, height 0.1s ease; }
.top-drop-zone--active    { height: 28px; background-color: #DEEBFF;
                            border-color: #4C9AFF; }

.draggable { cursor: grab; }
.draggable:active { cursor: grabbing; opacity: 0.7; }
```

---

## 12. Container queries for self-adaptive components

When a component must shrink gracefully inside variable-width parents
(ticket rows shown in both a wide table and a narrow kanban card), use
container queries — not media queries. See
[aoTicketItem.css:352-376](../main/default/lwc/aoTicketItem/aoTicketItem.css#L352-L376):

```css
:host {
    container-type: inline-size;
    container-name: ticket;
}
@container ticket (max-width: 42em) { .ticket-epic { display: none; } }
@container ticket (max-width: 34em) { .ticket-priority { display: none; } }
@container ticket (max-width: 26em) { .ticket-assignee { display: none; } }
```

Use container-CSS-variables (`--gap-row`, `--row-pad-inline`, etc.) so the
breakpoints adjust spacing in one place.

---

## 13. Section comments inside a CSS file

For any file longer than ~80 lines, separate concerns with this exact
comment shape (matches every page-level CSS in the repo):

```css
/* ── Section name ────────────────────────────────────────────────────────── */
```

Typical section order for a page:
1. `:host` + base font
2. Page wrapper
3. Panels / containers
4. Header rows
5. Empty state
6. Error banner
7. Bulk-action bar (if any)
8. Modal
9. Peek panel (if any)
10. Drag-and-drop
11. Loading overlay
12. Container queries

---

## 14. Things to NEVER do

- ❌ Hard-code colors not in §2.
- ❌ Use `!important` (single exception: when an `ao-*` child's inner
  control needs to be re-themed by a parent — see
  [ticketView.css:100-106](../main/default/lwc/ticketView/ticketView.css#L100-L106)).
- ❌ Use SLDS classes (`slds-*`) and custom classes on the same element —
  pick one approach per element. SLDS reset is fine; SLDS layout mixed
  with custom layout is not.
- ❌ Set a resting `border` on inputs/selects — use `border: 1px solid
  transparent` so focus doesn't jitter (§8 input recipe).
- ❌ Use `display: none` to hide focusable controls — use the visually-
  hidden pattern from [aoCheckbox.css:14-24](../main/default/lwc/aoCheckbox/aoCheckbox.css#L14-L24)
  (`position: absolute; width: 1px; height: 1px; clip: rect(0,0,0,0);`).
- ❌ Animate `transform` or `opacity` on hover.
- ❌ Use pixel font-sizes inside an `em`-based component
  ([aoTicketItem.css](../main/default/lwc/aoTicketItem/aoTicketItem.css)).
- ❌ Style by tag (`button`, `input`) instead of by class.
- ❌ Use `box-shadow` for borders. Use a real `border` (or `border-left`
  for left-accent banners).
- ❌ Introduce new border-radius values outside `3 / 4 / 6 / 12 px`.
- ❌ Forget `box-sizing: border-box;` on anything with explicit width
  AND padding.

---

## 15. Checklist before committing a new `.css` file

Run through this list every time:

- [ ] `:host` sets `font-family` (and `display`).
- [ ] All colors are from §2 (no `#fff` shortcuts — use `#FFFFFF`).
- [ ] All radii are `3 / 4 / 6 / 12 px`.
- [ ] All transitions are `0.1s` (controls) or `0.15s` (containers),
      with explicit properties (no `all`).
- [ ] Every interactive class has `:hover`, `:focus-visible` (or
      `:focus`), `:active` (where applicable), `:disabled`.
- [ ] BEM naming: `block__element--modifier`, JS toggle states without
      `--`.
- [ ] Modals/overlays follow §9.5 dimensions and z-indexes.
- [ ] Empty states + error banners match §9.3–9.4.
- [ ] If shown in variable widths → container queries from §12.
- [ ] No `!important`, no inline styles, no SLDS-mixed-with-custom.
- [ ] Section comments (§13) if file > ~80 lines.

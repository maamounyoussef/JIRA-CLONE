import { LightningElement, api } from 'lwc';

/**
 * c-ao-input — Design-system input for the Neobrutalism theme.
 *
 * Replaces lightning-input for all field types: text, number, date,
 * and checkbox. Fires the same `change` event shape so it is a drop-in
 * replacement in existing handlers.
 *
 * QUICK REFERENCE
 * ───────────────
 * Text field (with label):
 *   <c-ao-input label="Summary" required value={form.summary}
 *               data-field="summary" onchange={handleChange}>
 *
 * Number field:
 *   <c-ao-input label="Story Points" type="number" min="0"
 *               value={form.storyPoint} data-field="storyPoint" onchange={handleChange}>
 *
 * Date field:
 *   <c-ao-input label="Start Date" type="date" value={form.startDate}
 *               data-field="startDate" onchange={handleChange}>
 *
 * Checkbox (row-level select):
 *   <c-ao-input type="checkbox" checked={ticket.isSelected} onchange={handleSelect}>
 *
 * Inline text edit (no label, inside a row cell):
 *   <c-ao-input variant="label-hidden" value={summaryDraft}
 *               class="summary-input" onchange={handleSummaryDraftChange}>
 *
 * EVENT SHAPE
 * ───────────
 * onchange (text/number/date) → event.detail.value   (string)
 * onchange (checkbox)         → event.detail.checked (boolean)
 *                               event.detail.value   (boolean, same as checked)
 *
 * Shared handler pattern:
 *   const val = event.detail ? event.detail.value : event.target.value;
 */
export default class AoInput extends LightningElement {

    /**
     * @api label {string}
     * Text label rendered above the input.
     * — Required for accessible forms (modals, create/edit sections).
     * — Omit for checkboxes with no visible text, or with variant="label-hidden"
     *   for inline editing inside row cells.
     * — Label is uppercased and monospace by CSS.
     */
    @api label;

    /**
     * @api value {string}  default: ''
     * Current field value (text, number, or date as a string).
     * — For checkboxes use `checked` instead; `value` is ignored on checkbox.
     * — For date fields, pass ISO format: 'YYYY-MM-DD'.
     * — For number fields, pass the number as a string; parse with
     *   parseInt / parseFloat in the handler before sending to Apex.
     */
    @api value = '';

    /**
     * @api type {string}  default: 'text'
     * Maps to the native HTML input type attribute.
     *
     * 'text'     — Single-line text. Use for names, summaries, goals.
     * 'number'   — Numeric keyboard on mobile, browser min/max validation.
     *              Use for story points, duration (days).
     * 'date'     — Date picker rendered by the browser (ISO value).
     *              Use for sprint start date, epic start/end dates.
     * 'checkbox' — Custom-styled checkbox. Activates the checkbox template;
     *              use `checked` prop instead of `value`.
     *              Use for row-level selection in ticket and subtask rows.
     */
    @api type = 'text';

    /**
     * @api placeholder {string}
     * Hint text shown inside the input when it is empty.
     * — Use sparingly; a visible label is preferred over placeholder-only.
     * — Useful for inline inputs without labels (variant="label-hidden").
     */
    @api placeholder = '';

    /**
     * @api required {boolean}  default: false
     * Marks the field as required: renders a red asterisk (*) next to the label
     * and activates native browser validation on submit.
     * — Always pair with JS-side validation before calling Apex so you can
     *   show a `modalError` message instead of a browser tooltip.
     */
    @api required = false;

    /**
     * @api disabled {boolean}  default: false
     * Disables the input: prevents interaction, dims the control.
     * Use when the field is not editable in the current state
     * (e.g. a read-only name on a completed record).
     */
    @api disabled = false;

    /**
     * @api readonly {boolean}  default: false
     * Renders the input read-only: value is visible but not editable.
     * Differs from `disabled` — read-only fields remain focusable and
     * their values participate in form submission.
     * Use to display a value that can be copied but not changed.
     */
    @api readonly = false;

    /**
     * @api checked {boolean}  default: false
     * Current checked state for type="checkbox" inputs only.
     * — Ignored for all other types.
     * — Bind to a boolean on the record or UI state:
     *   checked={ticket.isSelected}
     * — Handler receives event.detail.checked (boolean).
     */
    @api checked = false;

    /**
     * @api min {string|number}
     * Minimum allowed value for type="number" or type="date".
     * — Number: min="0" to prevent negative story points.
     * — Date:   min="2024-01-01" (ISO string).
     * — Omit when no lower-bound constraint is needed.
     */
    @api min;

    /**
     * @api max {string|number}
     * Maximum allowed value for type="number" or type="date".
     * — Number: max="999".
     * — Date:   max="2099-12-31".
     * — Omit when no upper-bound constraint is needed.
     */
    @api max;

    /**
     * @api step {string|number}
     * Increment step for type="number" (browser validation + spinner arrow).
     * — step="1" for whole numbers, step="0.5" for half-point story points.
     * — Omit to use the browser default (1 for type="number").
     */
    @api step;

    /**
     * @api variant {string}
     * Controls label visibility.
     *
     * (unset / default) — Shows label above the input.
     *                     Use in modal forms and standalone form sections.
     *
     * 'label-hidden'    — Hides the label; no top gap is rendered.
     *                     Use for inline editing inside row cells where
     *                     surrounding layout provides context
     *                     (e.g. summary edit input inside a ticket row).
     */
    @api variant;

    // ── Internal computed getters ────────────────────────────────────────────���

    get isCheckbox() {
        return this.type === 'checkbox';
    }

    get showLabel() {
        return !!this.label && this.variant !== 'label-hidden';
    }

    get ariaLabel() {
        return this.label || undefined;
    }

    get fieldClass() {
        return this.showLabel ? 'ao-field' : 'ao-field ao-field--bare';
    }

    // ── Event forwarding ──────────────────────────────────────────────────────

    handleInput(event) {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: event.target.value }
        }));
    }

    handleCheckboxChange(event) {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                checked: event.target.checked,
                value  : event.target.checked
            }
        }));
    }
}

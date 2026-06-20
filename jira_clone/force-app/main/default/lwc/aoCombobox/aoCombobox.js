import { LightningElement, api } from 'lwc';

/**
 * c-ao-combobox — Design-system single-select dropdown for the Neobrutalism theme.
 *
 * Replaces lightning-combobox with a native <select> element styled to match
 * the hard-border, offset-shadow design language. Fires the same `change` event
 * shape so it is a drop-in replacement in existing handlers.
 *
 * QUICK REFERENCE
 * ───────────────
 * Standard (with label):
 *   <c-ao-combobox
 *       label="Priority"
 *       value={ticket.priority}
 *       options={priorityOptions}
 *       onchange={handlePriorityChange}>
 *   </c-ao-combobox>
 *
 * Inline / compact (no label, inside a row cell):
 *   <c-ao-combobox
 *       variant="label-hidden"
 *       placeholder="State"
 *       value={ticket.CurrentState__c}
 *       options={statusOptions}
 *       onchange={handleStateChange}>
 *   </c-ao-combobox>
 *
 * Lazy-load options on first open:
 *   <c-ao-combobox
 *       variant="label-hidden"
 *       placeholder="Assignee"
 *       value={ticket.AssignedTo__c}
 *       options={memberOptions}
 *       onchange={handleAssigneeChange}
 *       onclick={handleLoadMembers}
 *       onfocus={handleLoadMembers}>
 *   </c-ao-combobox>
 *
 * EVENT SHAPE
 * ───────────
 * onchange → event.detail.value  (the selected option's value string)
 * onclick  → bubbles to parent (use to trigger lazy data loads)
 * onfocus  → bubbles to parent (use as fallback trigger for lazy loads)
 */
export default class AoCombobox extends LightningElement {

    /**
     * @api label {string}
     * Text label rendered above the select control.
     * — Required for accessible forms (modals, create/edit forms).
     * — Omit together with variant="label-hidden" when the surrounding
     *   layout already provides visual context (e.g. a table column header).
     * — Label is uppercased and rendered in monospace by CSS.
     */
    @api label;

    /**
     * @api placeholder {string}
     * Hint text shown as the first, unselectable <option> when no value is set.
     * — Use a short noun: "State", "Assignee", "Priority".
     * — Use "─" (em dash) as a compact placeholder in tight row cells where
     *   a word would take too much horizontal space.
     * — Omit if one of the real options should always be pre-selected.
     */
    @api placeholder;

    /**
     * @api disabled {boolean}  default: false
     * Disables the select: prevents interaction, dims the control.
     * Use when the field is conditionally unavailable (e.g. state cannot
     * change after the record is closed).
     */
    @api disabled = false;

    /**
     * @api variant {string}
     * Controls label visibility and control sizing.
     *
     * (unset / default) — Full-size control with visible label above it.
     *                     Use in modal forms and standalone form sections.
     *
     * 'label-hidden'    — Compact control, no label, smaller font, tighter
     *                     padding. Use inside ticket rows, subtask rows, or
     *                     any dense table-like layout where the column
     *                     position provides the semantic context.
     */
    @api variant;

    /**
     * @api value {string}
     * The currently selected option value (matches an option's `value` field).
     * — Pass the raw record ID or primitive value, not the label.
     * — Set to null / empty string to show the placeholder.
     * — Synced to the native <select> via renderedCallback to handle
     *   re-renders triggered by parent state changes.
     */
    _value;

    @api
    get value() { return this._value; }
    set value(v) { this._value = v; }

    /**
     * @api options {Array<{label: string, value: string}>}
     * Array of option objects. Each must have:
     *   label — human-readable text shown in the dropdown
     *   value — machine value emitted in the change event
     *
     * Build with Array.map from Apex result:
     *   statusOptions = statuses.map(s => ({ label: s.Name, value: s.Id }));
     *
     * — Pass [] (empty array) while loading; the select will be empty but
     *   renders without error.
     * — For lazy loading, pass [] initially and populate on onclick/onfocus.
     */
    _options = [];

    @api
    get options() { return this._options; }
    set options(val) { this._options = val || []; }

    // ── Internal computed getters ─────────────────────────────────────────────

    renderedCallback() {
        const select = this.template.querySelector('select');
        if (select && this._value != null) {
            select.value = this._value;
        }
    }

    get showLabel() {
        return !!this.label && this.variant !== 'label-hidden';
    }

    get ariaLabel() {
        return this.label || undefined;
    }

    get isNothingSelected() {
        return this._value == null || this._value === '';
    }

    get wrapperClass() {
        return this.variant === 'label-hidden'
            ? 'ao-select ao-select--compact'
            : 'ao-select';
    }

    get computedOptions() {
        return this._options.map(opt => ({
            ...opt,
            isSelected: opt.value === this._value
        }));
    }

    // ── Event forwarding ──────────────────────────────────────────────────────

    handleChange(event) {
        this._value = event.target.value;
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: event.target.value }
        }));
    }

    handleClick() {
        this.dispatchEvent(new CustomEvent('click', { bubbles: true, composed: false }));
    }

    handleFocus() {
        this.dispatchEvent(new CustomEvent('focus', { bubbles: true, composed: false }));
    }
}

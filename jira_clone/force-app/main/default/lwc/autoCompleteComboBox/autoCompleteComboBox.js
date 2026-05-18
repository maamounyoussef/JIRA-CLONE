import { LightningElement, api } from 'lwc';

/**
 * c-auto-complete-combo-box — Type-to-filter single-select dropdown for the
 * Neobrutalism theme. Shares the visual language of c-ao-combobox but uses a
 * text input so users can narrow long option lists by typing.
 *
 * QUICK REFERENCE
 * ───────────────
 * Standard (with label):
 *   <c-auto-complete-combo-box
 *       label="Assignee"
 *       value={ticket.AssignedTo__c}
 *       options={memberOptions}
 *       onchange={handleAssigneeChange}>
 *   </c-auto-complete-combo-box>
 *
 * Compact / inline (no label):
 *   <c-auto-complete-combo-box
 *       variant="label-hidden"
 *       placeholder="Search…"
 *       value={ticket.AssignedTo__c}
 *       options={memberOptions}
 *       onchange={handleAssigneeChange}>
 *   </c-auto-complete-combo-box>
 *
 * EVENT SHAPE
 * ───────────
 * onchange → event.detail.value  (the selected option's value string)
 * onclick  → bubbles to parent (use to trigger lazy data loads)
 * onfocus  → bubbles to parent (use as fallback trigger for lazy loads)
 */
export default class AutoCompleteComboBox extends LightningElement {

    /**
     * @api label {string}
     * Text label rendered above the input. Required for accessible forms.
     */
    @api label;

    /**
     * @api placeholder {string}
     * Hint text shown when the input is empty.
     */
    @api placeholder;

    /**
     * @api disabled {boolean}  default: false
     */
    @api disabled = false;

    /**
     * @api variant {string}
     * (unset / default) — Full-size control with visible label.
     * 'label-hidden'    — Compact control for dense rows / table cells.
     */
    @api variant;

    /**
     * @api value {string}
     * The currently selected option value (matches an option's `value` field).
     * The input text mirrors the matching option's label.
     */
    _value;

    @api
    get value() { return this._value; }
    set value(v) {
        this._value = v;
        this._inputText = this._labelFor(v);
    }

    /**
     * @api options {Array<{label: string, value: string}>}
     * Array of option objects.
     */
    _options = [];

    @api
    get options() { return this._options; }
    set options(val) {
        this._options = val || [];
        if (this._value != null && !this._inputText) {
            this._inputText = this._labelFor(this._value);
        }
    }

    // ── Internal state ────────────────────────────────────────────────────────

    _inputText = '';
    _isOpen = false;
    _activeIndex = -1;

    // ── Computed getters ──────────────────────────────────────────────────────

    get inputText() { return this._inputText; }

    get isOpen() { return this._isOpen; }

    get showLabel() {
        return !!this.label && this.variant !== 'label-hidden';
    }

    get ariaLabel() {
        return this.label || undefined;
    }

    get wrapperClass() {
        return this.variant === 'label-hidden'
            ? 'ao-select ao-select--compact'
            : 'ao-select';
    }

    get visibleOptions() {
        const query = (this._inputText || '').toLowerCase().trim();
        const matchesSelectedLabel = query === (this._labelFor(this._value) || '').toLowerCase();
        const filtered = (!query || matchesSelectedLabel)
            ? this._options
            : this._options.filter(o => (o.label || '').toLowerCase().includes(query));

        return filtered.map((opt, idx) => ({
            ...opt,
            isSelected: opt.value === this._value,
            itemClass: idx === this._activeIndex
                ? 'ao-select__menu-item ao-select__menu-item--active'
                : 'ao-select__menu-item'
        }));
    }

    get showEmptyState() {
        return this.visibleOptions.length === 0;
    }

    // ── Event handlers ────────────────────────────────────────────────────────

    handleInput(event) {
        this._inputText = event.target.value;
        this._isOpen = true;
        this._activeIndex = -1;
    }

    handleClick() {
        this._isOpen = true;
        this.dispatchEvent(new CustomEvent('click', { bubbles: true, composed: false }));
    }

    handleFocus() {
        this._isOpen = true;
        this.dispatchEvent(new CustomEvent('focus', { bubbles: true, composed: false }));
    }

    handleBlur() {
        // Delay so an option mousedown can fire first.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this._isOpen = false;
            this._activeIndex = -1;
            // If user typed but did not pick a match, restore the selected label.
            if (this._inputText !== this._labelFor(this._value)) {
                this._inputText = this._labelFor(this._value);
            }
        }, 120);
    }

    handleOptionMouseDown(event) {
        // mousedown fires before blur — prevent default so the input keeps focus
        // long enough for us to commit the selection.
        event.preventDefault();
        const value = event.currentTarget.dataset.value;
        this._commitSelection(value);
    }

    handleKeyDown(event) {
        const opts = this.visibleOptions;
        switch (event.key) {
            case 'ArrowDown':
                event.preventDefault();
                this._isOpen = true;
                if (opts.length) {
                    this._activeIndex = (this._activeIndex + 1) % opts.length;
                }
                break;
            case 'ArrowUp':
                event.preventDefault();
                if (opts.length) {
                    this._activeIndex = this._activeIndex <= 0
                        ? opts.length - 1
                        : this._activeIndex - 1;
                }
                break;
            case 'Enter':
                if (this._isOpen && this._activeIndex >= 0 && opts[this._activeIndex]) {
                    event.preventDefault();
                    this._commitSelection(opts[this._activeIndex].value);
                }
                break;
            case 'Escape':
                this._isOpen = false;
                this._activeIndex = -1;
                this._inputText = this._labelFor(this._value);
                break;
            default:
                break;
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    _commitSelection(value) {
        this._value = value;
        this._inputText = this._labelFor(value);
        this._isOpen = false;
        this._activeIndex = -1;
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value }
        }));
    }

    _labelFor(value) {
        if (value == null || value === '') return '';
        const match = this._options.find(o => o.value === value);
        return match ? match.label : '';
    }
}

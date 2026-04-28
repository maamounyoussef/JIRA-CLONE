import { LightningElement, api } from 'lwc';

/**

 */
export default class AoInput extends LightningElement {

    /** Text label rendered above the input. Omit with variant="label-hidden" for inline inputs. */
    @api label;

    /**
     * Current field value (string). For date fields use ISO format 'YYYY-MM-DD'.
     * For number fields parse with parseInt/parseFloat in the handler before sending to Apex.
     */
    @api value = '';

    /**
     * HTML input type: 'text' | 'number' | 'date'.
     * For checkboxes use c-ao-checkbox. For dropdowns use c-ao-combobox.
     */
    @api type = 'text';

    /** Hint text shown inside the input when empty. */
    @api placeholder = '';

    /** Marks the field required: red asterisk + native browser validation. */
    @api required = false;

    /** Disables the input: prevents interaction, dims the control. */
    @api disabled = false;

    /** Makes the input read-only: value visible but not editable. */
    @api readonly = false;

    /** Minimum value for type="number" or type="date". */
    @api min;

    /** Maximum value for type="number" or type="date". */
    @api max;

    /** Increment step for type="number". */
    @api step;

    /**
     * Controls label visibility.
     * (unset) — Shows label above the input.
     * 'label-hidden' — Hides the label; use for inline editing inside row cells.
     */
    @api variant;

    get resolvedType() {
        return this.type || 'text';
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

    handleInput(event) {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: event.target.value }
        }));
    }
}

import { LightningElement, api } from 'lwc';

export default class AoCheckbox extends LightningElement {

    /** Visible text next to the checkbox. Omit for icon-only rows. */
    @api label;

    /** Current checked state. Bind to a boolean: checked={record.isSelected} */
    @api checked = false;

    /** Dims the control and prevents interaction. */
    @api disabled = false;

    handleChange(event) {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                checked: event.target.checked,
                value  : event.target.checked
            }
        }));
    }
}

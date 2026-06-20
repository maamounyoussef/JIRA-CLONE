import { LightningElement, api } from 'lwc';

/**
 * c-ao-btn — Design-system button for the Neobrutalism theme.
 *
 * Replaces both lightning-button (text actions) and lightning-button-icon
 * (icon-only toolbar actions) with a single consistent component.
 *
 * QUICK REFERENCE
 * ───────────────
 * Text button:      <c-ao-btn label="Save" variant="primary" onclick={save}>
 * Icon-only button: <c-ao-btn icon-name="utility:delete" variant="bare" title="Delete" onclick={del}>
 * Text + icon:      <c-ao-btn label="Add" icon-name="utility:add" variant="secondary" onclick={add}>
 * Danger confirm:   <c-ao-btn label="Delete" variant="danger" onclick={confirmDelete}>
 * Submit in form:   <c-ao-btn label="Submit" type="submit" variant="primary">
 */
export default class AoBtn extends LightningElement {

    /**
     * @api label {string}
     * Visible button text.
     * — Omit when you only want an icon (icon-only mode).
     * — Required when iconName is absent; otherwise the button renders empty.
     * — Text is automatically uppercased by CSS (text-transform: uppercase).
     */
    @api label;

    /**
     * @api iconName {string}
     * SLDS icon token, e.g. "utility:add", "utility:delete", "utility:edit".
     * — When provided without `label`, the button enters icon-only mode:
     *   square, compact, uses `title` as the accessible label.
     * — When provided alongside `label`, the icon appears to the left of the text.
     * — Full icon catalogue: https://www.lightningdesignsystem.com/icons/
     * — Always pair with `title` when icon-only so screen readers have a label.
     */
    @api iconName;

    /**
     * @api variant {string}  default: 'secondary'
     * Controls the visual weight and color of the button.
     *
     * 'primary'   — Blue fill (#0176d3), black border + offset shadow.
     *               Use for the single most important action in a view or modal
     *               (e.g. "Create", "Save", "Confirm").
     *
     * 'secondary' — White fill, black border + offset shadow.
     *               Use for secondary or neutral actions alongside a primary
     *               (e.g. "Edit", "+ Sprint").
     *
     * 'danger'    — White fill, red border + red offset shadow.
     *               Use for destructive actions that require confirmation
     *               (e.g. "Delete", "Remove", confirm buttons in dialogs).
     *
     * 'ghost'     — Transparent background; border and shadow appear only on
     *               hover. Use for low-priority actions that should not compete
     *               visually (e.g. "Cancel", "Dismiss").
     *
     * 'bare'      — No border, no shadow, icon tinted gray until hover.
     *               Use as a replacement for lightning-button-icon in dense
     *               rows (e.g. inline edit pencil, delete trash, expand chevron).
     */
    @api variant = 'secondary';

    /**
     * @api size {string}  default: 'md'
     * Controls font-size and padding.
     *
     * 'sm' — 0.625rem font, compact padding. Use inside ticket/subtask rows
     *        where space is constrained (inline edit, toolbar icons).
     * 'md' — 0.6875rem font, standard padding. Default for most buttons.
     * 'lg' — 0.8125rem font, generous padding. Use for modal footers or
     *        hero CTAs where more breathing room is appropriate.
     */
    @api size = 'md';

    /**
     * @api disabled {boolean}  default: false
     * Disables the button: prevents clicks, reduces opacity to 0.38,
     * suppresses shadow/transform hover effects.
     * Use for actions that are not yet available (e.g. pagination when on
     * the first or last page, submit before required fields are filled).
     */
    @api disabled = false;

    /**
     * @api type {string}  default: 'button'
     * Native HTML button type attribute.
     *
     * 'button' — Default. Use for all event-driven actions (onclick handlers).
     * 'submit' — Submits the nearest <form>. Rarely needed in LWC since
     *            form submission is typically handled imperatively.
     * 'reset'  — Resets the nearest <form>. Use sparingly.
     */
    @api type = 'button';

    /**
     * @api title {string}
     * Tooltip shown on hover (native browser tooltip).
     * — Required for icon-only buttons: this becomes the aria-label so
     *   screen readers can announce the button's purpose.
     * — Optional for text buttons: only add if the label alone is ambiguous
     *   in context.
     */
    @api title;

    // ── Internal computed getters ─────────────────────────────────────────────

    get ariaLabel() {
        return this.title || this.label || undefined;
    }

    get isIconOnly() {
        return !!this.iconName && !this.label;
    }

    get iconSize() {
        return this.size === 'lg' ? 'small' : 'x-small';
    }

    get computedClass() {
        const classes = [
            'ao-btn',
            `ao-btn--${this.variant}`,
            `ao-btn--${this.size}`
        ];
        if (this.isIconOnly) classes.push('ao-btn--icon-only');
        return classes.join(' ');
    }
}

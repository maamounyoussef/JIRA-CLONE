import { LightningElement, api } from 'lwc';

/**
 * c-ao-spinner — Design-system loading spinner for the Jira-clone theme.
 *
 * A pure-CSS replacement for <lightning-spinner>. Renders a brand-blue
 * rotating ring; optionally lays a translucent backdrop over the viewport
 * so the spinner reads as a blocking "loading" state.
 *
 * QUICK REFERENCE
 * ───────────────
 * Inline (in flow):     <c-ao-spinner size="small"></c-ao-spinner>
 * Centered in a box:    <c-ao-spinner size="large"></c-ao-spinner>
 * Full-page overlay:    <c-ao-spinner overlay size="medium"></c-ao-spinner>
 */
export default class AoSpinner extends LightningElement {

    /**
     * @api size {string}  default: 'medium'
     * Diameter of the ring.
     * 'small'  — 1rem,  use inline inside dense rows (loading a sprint's tickets).
     * 'medium' — 2rem,  default; use centered in overlays / panels.
     * 'large'  — 3rem,  use as the primary full-area loading indicator.
     */
    @api size = 'medium';

    /**
     * @api overlay {boolean}  default: false
     * When true, the spinner is centered over a fixed, full-viewport backdrop
     * tinted with the app's navy at 70% transparency (rgba(9,30,66,0.30)),
     * dimming the page behind it. Use for blocking loads. When false, the
     * spinner renders in normal document flow with no backdrop.
     */
    @api overlay = false;

    /**
     * @api alternativeText {string}  default: 'Loading'
     * Accessible label announced by screen readers (aria-label on the
     * role="status" element). Always describe what is loading.
     */
    @api alternativeText = 'Loading';

    get spinnerClass() {
        return `ao-spinner ao-spinner--${this.size}`;
    }
}

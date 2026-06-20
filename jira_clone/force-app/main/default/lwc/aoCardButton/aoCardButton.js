import { LightningElement, api } from 'lwc';

/**
 * c-ao-card-button — Design-system clickable card for the Neobrutalism theme.
 *
 * A reusable presentation card that behaves like a button: it renders a
 * thumbnail image, a heading and a description, and dispatches a lowercase
 * `select` event (with `detail.value`) when clicked or activated by keyboard.
 *
 * Presentation only: it never calls Apex and never mutates its @api inputs.
 *
 * QUICK REFERENCE
 * ───────────────
 * <c-ao-card-button
 *     value={detail.Id}
 *     heading={detail.Name}
 *     description={detail.Description__c}
 *     image-url={detail.Image_URL__c}
 *     onselect={handleCardSelect}>
 * </c-ao-card-button>
 */
export default class AoCardButton extends LightningElement {

    /** @api value {string} Identifier echoed back in the `select` event detail. */
    @api value;

    /** @api heading {string} Bold card title. */
    @api heading;

    /** @api description {string} Supporting text under the heading. */
    @api description;

    /** @api imageUrl {string} Optional thumbnail/preview image URL. */
    @api imageUrl;

    get hasImage() {
        return !!this.imageUrl;
    }

    handleClick() {
        this.dispatchEvent(new CustomEvent('select', {
            detail: { value: this.value }
        }));
    }

    handleKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleClick();
        }
    }
}

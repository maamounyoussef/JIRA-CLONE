/**
 * Ticket Validator
 * Validations for the ticket domain in aoCreateTicketModal.
 */

const TICKET_NAME_MAX = 80;  // Ticket__c nameField (Text, SF default 80)
const SUMMARY_MAX     = 255; // Ticket__c.Summary__c length 255
const STORY_POINT_MAX = 99;  // Ticket__c.StoryPoint__c precision 2 scale 0

/**
 * Validates all required and type-constrained fields for creating a Ticket__c.
 * Required by object: Summary__c, CurrentState__c.
 * Required for this operation: ticketTypeId (business rule).
 */
export function validateTicketCreate({ name, summary, ticketTypeId, currentStateId, storyPoint }) {
    if (!name || !name.trim()) return 'Name is required.';
    if (name.trim().length > TICKET_NAME_MAX) return `Name must be ${TICKET_NAME_MAX} characters or fewer.`;
    if (!summary || !summary.trim()) return 'Summary is required.';
    if (summary.trim().length > SUMMARY_MAX) return `Summary must be ${SUMMARY_MAX} characters or fewer.`;
    if (!ticketTypeId) return 'Ticket Type is required.';
    if (!currentStateId) return 'Status is required.';
    if (storyPoint != null && storyPoint !== '') {
        const sp = Number(storyPoint);
        if (!Number.isInteger(sp) || sp < 0 || sp > STORY_POINT_MAX) {
            return `Story Point must be a whole number between 0 and ${STORY_POINT_MAX}.`;
        }
    }
    return null;
}

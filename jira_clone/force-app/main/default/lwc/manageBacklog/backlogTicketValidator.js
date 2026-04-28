/**
 * Ticket Validator
 * Validations for the ticket domain.
 */

const TICKET_NAME_MAX  = 80;  // Ticket__c nameField (Text, SF default 80)
const SUMMARY_MAX      = 255; // Ticket__c.Summary__c length 255
const STORY_POINT_MAX  = 99;  // Ticket__c.StoryPoint__c precision 2 scale 0
const PRIORITY_VALUES  = new Set(['Critical', 'High', 'Medium', 'Low']);

export function validateTicketName(name) {
    if (!name || !name.trim()) return 'Name is required.';
    if (name.trim().length > TICKET_NAME_MAX) return `Name must be ${TICKET_NAME_MAX} characters or fewer.`;
    return null;
}

// Ticket__c.Summary__c is required and max 255 chars.
export function validateTicketSummary(summary) {
    if (!summary || !summary.trim()) return 'Summary is required.';
    if (summary.trim().length > SUMMARY_MAX) return `Summary must be ${SUMMARY_MAX} characters or fewer.`;
    return null;
}

// Ticket__c.Ticket_Type__c is not required in the object but required for create.
export function validateTicketType(ticketTypeId) {
    if (!ticketTypeId) return 'Ticket Type is required.';
    return null;
}

// Ticket__c.CurrentState__c is required in the object.
export function validateTicketCurrentState(currentStateId) {
    if (!currentStateId) return 'Status is required.';
    return null;
}

// Ticket__c.StoryPoint__c: Number precision 2 scale 0 (integer 0–99).
export function validateTicketStoryPoint(storyPoint) {
    if (storyPoint == null || storyPoint === '') return null;
    const sp = Number(storyPoint);
    if (!Number.isInteger(sp) || sp < 0 || sp > STORY_POINT_MAX) {
        return `Story Point must be a whole number between 0 and ${STORY_POINT_MAX}.`;
    }
    return null;
}

// Per-apex-call: Priority__c is required by updateTicketPriority (apex/store required = yes).
// Priority is optional at the LWC object level, so aoTicketItem does not enforce it.
export function validatePriorityForUpdate(priority) {
    if (!priority) return 'Priority is required.';
    if (!PRIORITY_VALUES.has(priority)) return 'Priority must be Critical, High, Medium, or Low.';
    return null;
}


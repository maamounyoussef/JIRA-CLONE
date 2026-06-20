/**
 * Manage Ticket Tracking Validator
 * Root-level validations shared across the manage ticket tracking page.
 */

export function validateChangeTicketState(ticketId, toStatusId) {
    if (!ticketId)   return 'ticketId is required';
    if (!toStatusId) return 'toStatusId is required';
    return null;
}

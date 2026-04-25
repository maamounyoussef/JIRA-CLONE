/**
 * Ticket Validator
 * Validations for the ticket domain.
 */

export function validateTicketName(name) {
    if (!name || !name.trim()) return 'Name is required.';
    return null;
}

export function validateTicketType(ticketTypeId) {
    if (!ticketTypeId) return 'Ticket Type is required.';
    return null;
}

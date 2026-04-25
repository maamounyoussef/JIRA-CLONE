/**
 * Ticket Utils
 * Utility functions for the ticket domain.
 * Add formatters, mappers, and factory functions here as the domain grows.
 */

export function enrichTickets(tickets, epics, ticketTypeOptions, memberOptions) {
    const epicMap       = Object.fromEntries((epics             || []).map(e => [e.Id,    e.Name]));
    const ticketTypeMap = Object.fromEntries((ticketTypeOptions || []).map(o => [o.value, o.label]));
    const memberMap     = Object.fromEntries((memberOptions     || []).map(m => [m.value, m.label]));
    return tickets.map(t => ({
        ...t,
        epicName      : epicMap[t.Epic__c]              || '',
        ticketTypeName: ticketTypeMap[t.Ticket_Type__c] || '',
        assigneeName  : memberMap[t.AssignedTo__c]      || '',
        isSelected    : false,
    }));
}

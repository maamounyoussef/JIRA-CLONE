/**
 * Ticket Utils
 * Utility functions for the ticket domain.
 */

export function emptyTicket() {
    return { name: '', summary: '', description: '', storyPoint: null, ticketTypeId: '', currentStateId: '', priority: '' };
}

const _rk = () => Math.random().toString(36).slice(2);

export function formatTicket(rawTicket, ticketTypeOptions, ticketTypeId) {
    return {
        ...rawTicket,
        epicName      : '',
        ticketTypeName: ticketTypeOptions.find(o => o.value === ticketTypeId)?.label || '',
        isSelected    : false,
        _key          : _rk(),
    };
}

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
        _key          : _rk(),
    }));
}

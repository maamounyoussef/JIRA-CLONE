/**
 * Ticket Utils
 * Utility functions for the ticket domain.
 */

/**
 * Generates a random key for a ticket. LWC diffs the board list by this key,
 * so spreading a ticket and assigning a fresh key forces that one card to
 * re-render. Call it on load and again on every field update.
 */
export function newTicketKey() {
    return (typeof crypto !== 'undefined' && crypto.randomUUID)
        ? crypto.randomUUID()
        : 'k-' + Math.random().toString(36).slice(2) + Date.now().toString(36);
}

/**
 * Looks up a member's display name from the members list.
 */
export function getMemberName(memberId, members) {
    if (!memberId) return '';
    const member = (members || []).find(m => m.Id === memberId);
    return member ? (member.User__r && member.User__r.Name) || member.Name || '' : '';
}

/**
 * Shapes the flat Apex response into the nested ticket list the page works with.
 * Each ticket carries its own ticket type, and each ticket type carries the
 * workflow transitions for its workflow. The data is duplicated across tickets
 * on purpose — this page only reads types and workflows, it never edits them,
 * so there is no shared state to keep in sync.
 */
export function buildSprintTickets(sprintTickets, ticketTypes, workflows, statuses, members) {
    const endStatusIds = new Set((statuses || []).filter(s => s.isEnd__c).map(s => s.Id));
    return (sprintTickets || []).map(t => {
        const baseType = (ticketTypes || []).find(tt => tt.Id === t.Ticket_Type__c) || null;
        const ticketType = baseType
            ? { ...baseType, workflowTransitions: (workflows || []).filter(w => w.Workflow__c === baseType.Workflow__c) }
            : null;
        return {
            ...t,
            key:            newTicketKey(),
            ticketType,
            ticketTypeName: (ticketType && ticketType.Name) || '',
            assigneeName:   getMemberName(t.AssignedTo__c, members),
            isEndStatus:    endStatusIds.has(t.CurrentState__c),
        };
    });
}

/**
 * Builds the board column structure from statuses and tickets.
 * Each column holds the tickets whose CurrentState__c matches the status Id.
 * Columns whose statusId is in validTargetIds are flagged as drop targets.
 */
export function buildColumns(statuses, tickets, validTargetIds) {
    const validSet = new Set(validTargetIds || []);
    return (statuses || []).map(status => ({
        statusId:      status.Id,
        statusName:    status.Name,
        tickets:       (tickets || [])
            .filter(t => t.CurrentState__c === status.Id)
            .map(t => ({
                _renderKey:      t.key,
                Id:              t.Id,
                Name:            t.Name,
                Ticket_Type__c:  t.Ticket_Type__c,
                ticketTypeName:  t.ticketTypeName  || '',
                Summary__c:      t.Summary__c      || '',
                StoryPoint__c:   t.StoryPoint__c,
                AssignedTo__c:   t.AssignedTo__c,
                assigneeName:    t.assigneeName    || '',
                CurrentState__c: t.CurrentState__c,
                isEndStatus:     t.isEndStatus     || false,
            })),
        isValidTarget: validSet.has(status.Id)
    }));
}

/**
 * Returns a new tickets array with the target ticket's state fields updated.
 */
export function enrichTicketsWithStateChange(tickets, ticketId, toStatusId, isEndStatus) {
    return (tickets || []).map(ticket =>
        ticket.Id === ticketId
            ? { ...ticket, key: newTicketKey(), CurrentState__c: toStatusId, isEndStatus: isEndStatus || false }
            : ticket
    );
}

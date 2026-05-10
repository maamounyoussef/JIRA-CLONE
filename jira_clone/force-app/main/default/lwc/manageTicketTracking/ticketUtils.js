/**
 * Ticket Utils
 * Utility functions for the ticket domain.
 */

/**
 * Builds the board column structure from statuses and tickets.
 * Each column holds the tickets whose CurrentState__c matches the status Id.
 */
export function buildColumns(statuses, tickets) {
    return statuses.map(status => ({
        statusId:      status.Id,
        statusName:    status.Name,
        tickets:       (tickets || [])
            .filter(t => t.CurrentState__c === status.Id)
            .map(t => ({
                _renderKey:      t.Id,
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
        isValidTarget: false
    }));
}

/**
 * Looks up a member's display name from the members list.
 */
export function getMemberName(memberId, members) {
    if (!memberId) return '';
    const member = (members || []).find(m => m.Id === memberId);
    return member ? (member.User__r && member.User__r.Name) || member.Name || '' : '';
}

export function enrichTicketsWithTypeName(tickets, ticketTypes) {
    return (tickets || []).map(t => ({
        ...t,
        ticketTypeName: ((ticketTypes || []).find(tt => tt.Id === t.Ticket_Type__c) || {}).Name || ''
    }));
}

export function enrichTicketsWithAssigneeName(tickets, members) {
    return (tickets || []).map(t => ({
        ...t,
        assigneeName: getMemberName(t.AssignedTo__c, members)
    }));
}

/**
 * Returns a new tickets array with the target ticket's state fields updated.
 */
export function enrichTicketsWithStateChange(tickets, ticketId, toStatusId, statuses, isEndStatus) {
    return (tickets || []).map(ticket =>
        ticket.Id === ticketId
            ? {
                ...ticket,
                CurrentState__c: toStatusId,
                currentStatuses: (statuses || []).find(s => s.statusId === toStatusId) || null,
                isEndStatus:     isEndStatus || false
              }
            : ticket
    );
}

/**
 * Handles the end-status transition: flips the ticket's isEndStatus flag and
 * forces a re-render in the columns, and enriches the sprint with the latest
 * TotalEndedStoryPoint__c. Returns the new { columns, sprint }.
 */
export function enrichSprintWithEndedTicket(sprint, columns, ticketId, updatedSprint) {
    const newColumns = (columns || []).map(col => ({
        ...col,
        tickets: col.tickets.map(t =>
            t.Id === ticketId
                ? { ...t, isEndStatus: true, _renderKey: t.Id + '_' + Date.now() }
                : t
        )
    }));
    const newSprint = updatedSprint
        ? { ...sprint, TotalEndedStoryPoint__c: updatedSprint.TotalEndedStoryPoint__c }
        : sprint;
    return { columns: newColumns, sprint: newSprint };
}

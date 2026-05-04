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

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
        tickets:       (tickets || []).filter(t => t.CurrentState__c === status.Id),
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

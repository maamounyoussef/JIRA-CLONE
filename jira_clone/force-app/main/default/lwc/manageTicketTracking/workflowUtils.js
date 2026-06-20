/**
 * Workflow Utils
 * Computes valid drag-drop targets from the workflow DFA without a backend call.
 * The transitions are nested on the ticket type itself, so no separate lookup
 * across a global transitions list is needed.
 */

/**
 * Returns a Set of valid target status IDs for the given ticket type and current
 * status, by reading the ticket type's own workflow transitions.
 */
export function getValidTargetStatusIds(ticketType, currentStatusId) {
    const validTargets = new Set();
    ((ticketType && ticketType.workflowTransitions) || []).forEach(t => {
        if (t.FromStatus__c === currentStatusId) {
            validTargets.add(t.ToStatus__c);
        }
    });
    return validTargets;
}

/**
 * Finds the transition Id for a specific from→to status move within a ticket
 * type's workflow. Returns null if no matching transition exists.
 */
export function findTransitionId(ticketType, fromStatusId, toStatusId) {
    const transition = ((ticketType && ticketType.workflowTransitions) || []).find(t =>
        t.FromStatus__c === fromStatusId &&
        t.ToStatus__c   === toStatusId
    );
    return transition ? transition.Id : null;
}

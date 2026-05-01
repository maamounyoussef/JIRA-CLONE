/**
 * Workflow Utils
 * Utility functions for the workflow domain.
 * Used to compute valid drag-drop targets from the workflow DFA without a backend call.
 */

/**
 * Returns a Set of valid target status IDs for a given ticket being dragged.
 * Looks up the ticket type's workflow, then finds all active transitions
 * whose FromStatus matches the current status.
 */
export function getValidTargetStatusIds(ticketTypeId, currentStatusId, ticketTypes, workflowTransitions) {
    const ticketType = (ticketTypes || []).find(tt => tt.Id === ticketTypeId);
    if (!ticketType) return new Set();

    const workflowId = ticketType.Workflow__c;
    const validTargets = new Set();

    (workflowTransitions || []).forEach(t => {
        if (t.Workflow__c === workflowId && t.FromStatus__c === currentStatusId) {
            validTargets.add(t.ToStatus__c);
        }
    });

    return validTargets;
}

/**
 * Finds the transition Id for a specific from→to status move within a ticket type's workflow.
 * Returns null if no matching transition exists.
 */
export function findTransitionId(ticketTypeId, fromStatusId, toStatusId, ticketTypes, workflowTransitions) {
    const ticketType = (ticketTypes || []).find(tt => tt.Id === ticketTypeId);
    if (!ticketType) return null;

    const workflowId = ticketType.Workflow__c;
    const transition = (workflowTransitions || []).find(t =>
        t.Workflow__c === workflowId &&
        t.FromStatus__c === fromStatusId &&
        t.ToStatus__c   === toStatusId
    );
    return transition ? transition.Id : null;
}

/**
 * Returns the workflow Id for the given ticket type Id.
 */
export function getWorkflowId(ticketTypeId, ticketTypes) {
    const ticketType = (ticketTypes || []).find(tt => tt.Id === ticketTypeId);
    return ticketType ? ticketType.Workflow__c : null;
}

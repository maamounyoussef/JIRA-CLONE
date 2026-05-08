/**
 * @description Business-rule invariants for all domain operations.
 *              Existence / record-availability checks live in DomainCorrectness and
 *              are the responsibility of the controller layer.
 *
 *              Convention:
 *                requireXxx(...)  — validates a business invariant, throws if violated
 */
public with sharing class DomainCompleteValidator {

    // ═══════════════════════════════════════════════════════════════
    // PROJECT MEMBER — authorization
    // ═══════════════════════════════════════════════════════════════

    public static ProjectMember__c requireCurrentUserMemberForProject(ProjectMember__c member, String userId) {
        if (member == null || member.User__c != userId) {
            throw new ServiceException('User ' + userId + ' is not an active member of this project');
        }
        return member;
    }

    // ═══════════════════════════════════════════════════════════════
    // SPRINT — state machine
    // ═══════════════════════════════════════════════════════════════

        /**
     * Only one sprint per project can be in_progress at a time.
     * Prevents starting a new sprint when another is already running.
     */
    public static void requireNoActiveSprintInProject(List<Sprint__c> activeSprint ) {
        if (!activeSprint.isEmpty()) throw new ServiceException('Project already has an active sprint in progress');
    }
    /**
     * Sprint must be in 'future' status to be started.
     */
    public static void requireSprintIsStartable(Sprint__c sprint) {
        if (sprint.RecordStatus__c != 'future') {
            throw new ServiceException('Sprint can only be started from future status, current status: ' + sprint.RecordStatus__c);
        }
    }

    /**
     * Sprint must be in 'in_progress' status to be completed.
     */
    public static void requireSprintIsCompletable(Sprint__c sprint) {
        if (sprint.RecordStatus__c != 'in_progress') {
            throw new ServiceException('Sprint can only be completed from in_progress status, current status: ' + sprint.RecordStatus__c);
        }
    }

    /**
     * Ticket cannot be moved from one sprint to another sprint.
     * It can only be moved from backlog (null) to a sprint, or from a sprint to backlog (null).
     */
    public static void requireTicketNotInDifferentSprint(Ticket__c ticket, String targetSprintId) {
        if (String.isNotBlank(ticket.Sprint__c) && ticket.Sprint__c != targetSprintId) {
            throw new ServiceException('Ticket cannot be moved from one sprint to another sprint');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW TRANSITION — invariants
    // ═══════════════════════════════════════════════════════════════

    /**
     * FromStatus and ToStatus must not be the same — a self-loop transition is invalid.
     */
    public static void requireTransitionStatusesDifferent(String fromStatusId, String toStatusId) {
        if (fromStatusId == toStatusId) {
            throw new ServiceException('From Status and To Status must be different');
        }
    }

    /**
     * Transition name must be unique — caller queries duplicates and passes the result.
     */
    public static void requireTransitionNameUnique(List<WorkflowTransition__c> duplicates) {
        if (!duplicates.isEmpty()) throw new ServiceException('Transition name already exists in this workflow');
    }

    /**
     * Only pending transitions can be activated.
     */
    public static void requireTransitionIsPending(WorkflowTransition__c transition) {
        if (transition.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
            throw new ServiceException('Workflow Transition can only be activated from pending status');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // VALIDATION RULE — state machine
    // ═══════════════════════════════════════════════════════════════

    /**
     * Only pending validation rules can be activated.
     */
    public static void requireValidationRuleIsPending(ValidationRule__c rule) {
        if (rule.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
            throw new ServiceException('Validation Rule can only be activated from pending status');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE — business rules
    // ═══════════════════════════════════════════════════════════════

    public static void requireWorkflowAssignedToTicketType(TicketType__c ticketType, String workflowId) {
        if (ticketType.Workflow__c != workflowId) {
            throw new ServiceException('Workflow is not assigned to this Ticket Type');
        }
    }

    public static void requireTransitionBelongsToWorkflow(WorkflowTransition__c transition, String workflowId) {
        if (transition.Workflow__c != workflowId) {
            throw new ServiceException('Workflow Transition does not belong to this Workflow');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW — transition availability
    // ═══════════════════════════════════════════════════════════════

    public static WorkflowTransition__c requireTransitionAllowed(String fromStatusId, String toStatusId, List<WorkflowTransition__c> transitions) {
        for (WorkflowTransition__c t : transitions) {
            if (t.FromStatus__c == fromStatusId && t.ToStatus__c == toStatusId) {
                return t;
            }
        }
        throw new ServiceException('Transition from current status to target status is not allowed by the workflow');
    }

    public static Boolean isEndStatus(Status__c status) {
        return status.isEnd__c;
    }

    /**
     * No outgoing transition may originate from an end status — it is terminal.
     */
    public static void requireFromStatusNotEnd(Status__c fromStatus) {
        if (fromStatus.isEnd__c) {
            throw new ServiceException('Cannot create a transition from an end status');
        }
    }

    /**
     * No transition may target the start (todo) status — it is the entry point only.
     */
    public static void requireToStatusNotStart(Status__c toStatus) {
        if (toStatus.isStart__c) {
            throw new ServiceException('Cannot create a transition to the start (todo) status');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PAGINATION — utilities
    // ═══════════════════════════════════════════════════════════════

    public static Integer safeOffset(Integer offset) {
        return (offset != null && offset >= 0) ? offset : 0;
    }

    public static Integer safePageSize(Integer pageSize, Integer defaultPageSize) {
        return (pageSize != null && pageSize > 0) ? pageSize : defaultPageSize;
    }
}

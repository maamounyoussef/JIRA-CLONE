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
    // PAGINATION — utilities
    // ═══════════════════════════════════════════════════════════════

    public static Integer safeOffset(Integer offset) {
        return (offset != null && offset >= 0) ? offset : 0;
    }

    public static Integer safePageSize(Integer pageSize, Integer defaultPageSize) {
        return (pageSize != null && pageSize > 0) ? pageSize : defaultPageSize;
    }
}

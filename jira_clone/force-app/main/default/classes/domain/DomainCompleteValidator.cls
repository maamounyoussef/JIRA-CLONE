/**
 * @description Central validator class for domain-level existence checks and business invariants.
 *              Required field (blank) checks belong in the controller layer, not here.
 *
 *              Convention:
 *                requireXxx(...)          — record existence / business invariant, throws if invalid
 *                requireOptionalXxx(...)  — only validates when the value is non-blank
 */
public with sharing class DomainCompleteValidator {

    // ═══════════════════════════════════════════════════════════════
    // PROJECT
    // ═══════════════════════════════════════════════════════════════

    public static Project__c requireProjectExists(String projectId) {
        List<Project__c> rows = [SELECT Id, Name FROM Project__c WHERE Id = :projectId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Project not found');
        return rows[0];
    }

    public static Project__c requireProjectExistsByName(String projectName) {
        List<Project__c> rows = [SELECT Id, Name FROM Project__c WHERE Name = :projectName LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Project not found: ' + projectName);
        return rows[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // PROJECT MEMBER
    // ═══════════════════════════════════════════════════════════════

    public static User requireUserExists(String userId) {
        List<User> rows = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('User does not exist');
        return rows[0];
    }

    public static ProjectMember__c requireProjectMemberActive(String memberId) {
        List<ProjectMember__c> rows = [
            SELECT Id, User__c, Project__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE Id = :memberId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Project member not found or inactive: ' + memberId);
        return rows[0];
    }

    public static void requireOptionalProjectMemberActive(String memberId) {
        if (String.isBlank(memberId)) return;
        requireProjectMemberActive(memberId);
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE
    // ═══════════════════════════════════════════════════════════════

    public static TicketType__c requireTicketTypeExists(String ticketTypeId) {
        List<TicketType__c> rows = [
            SELECT Id, Name, Project__c, Workflow__c, RecordStatus__c
            FROM TicketType__c
            WHERE Id = :ticketTypeId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Ticket Type not found');
        return rows[0];
    }

    public static TicketType__c requireTicketTypeExistsByName(String ticketTypeName, String projectId) {
        List<TicketType__c> rows = [
            SELECT Id, Name, Project__c FROM TicketType__c
            WHERE Name = :ticketTypeName AND Project__c = :projectId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Ticket Type not found: ' + ticketTypeName);
        return rows[0];
    }

    /**
     * Workflow must belong to the same project as the ticket type.
     * Domain invariant: a ticket type must not reference a workflow from a different project.
     */
    public static void requireWorkflowBelongsToProject(String workflowId, String projectId) {
        List<Workflow__c> rows = [
            SELECT Id FROM Workflow__c
            WHERE Id = :workflowId AND Project__c = :projectId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Workflow does not belong to the specified project');
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET
    // ═══════════════════════════════════════════════════════════════

    public static Ticket__c requireTicketExists(String ticketId) {
        List<Ticket__c> rows = [
            SELECT Id, Name, Summary__c, Description__c, Priority__c,
                   CurrentState__c, AssignedTo__c, Creator__c, Ticket_Type__c,
                   Epic__c, Sprint__c, RecordStatus__c, StoryPoint__c,
                   StartDate__c, EndDate__c
            FROM Ticket__c
            WHERE Id = :ticketId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Ticket not found: ' + ticketId);
        return rows[0];
    }

    public static void requireOptionalEpicActive(String epicId) {
        List<Epic__c> rows = [SELECT Id FROM Epic__c WHERE Id = :epicId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Epic not found: ' + epicId);
    }

    public static void requireOptionalSprintExists(String sprintId) {
        List<Sprint__c> rows = [SELECT Id FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Sprint not found: ' + sprintId);
    }

    public static void requireOptionalStatusExists(String statusId) {
        List<Status__c> rows = [SELECT Id FROM Status__c WHERE Id = :statusId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Status not found: ' + statusId);
    }

    /**
     * Resolve the current Salesforce user to their active ProjectMember for the given project.
     * Used to auto-set Creator__c on Ticket__c.
     */
    public static ProjectMember__c requireCurrentUserMemberForProject(String projectId) {
        String currentUserId = UserInfo.getUserId();
        List<ProjectMember__c> rows = [
            SELECT Id, User__c, Project__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE User__c = :currentUserId AND Project__c = :projectId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Current user is not an active member of this project');
        return rows[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // SUBTASK
    // ═══════════════════════════════════════════════════════════════

    public static Subtask__c requireSubtaskExists(String subtaskId) {
        List<Subtask__c> rows = [
            SELECT Id, Summary__c, Description__c, Assignee__c,
                   CurrentState__c, StoryPoint__c, StartDate__c,
                   RecordStatus__c, Ticket__c
            FROM Subtask__c
            WHERE Id = :subtaskId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Subtask not found: ' + subtaskId);
        return rows[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // EPIC
    // ═══════════════════════════════════════════════════════════════

    public static Epic__c requireEpicExists(String epicId) {
        List<Epic__c> rows = [
            SELECT Id, Name, Summary__c, Description__c, Project__c,
                   StartDate__c, EndDate__c
            FROM Epic__c
            WHERE Id = :epicId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Epic not found: ' + epicId);
        return rows[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // SPRINT
    // ═══════════════════════════════════════════════════════════════

    public static Sprint__c requireSprintExists(String sprintId) {
        List<Sprint__c> rows = [
            SELECT Id, Name, Project__c, StartDate__c, Duration__c, Goal__c, RecordStatus__c
            FROM Sprint__c
            WHERE Id = :sprintId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Sprint not found');
        return rows[0];
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
    // STATUS
    // ═══════════════════════════════════════════════════════════════

    public static Status__c requireStatusExists(String statusId) {
        if (String.isBlank(statusId)) throw new ServiceException('Status Id is required');
        List<Status__c> rows = [
            SELECT Id, Name, Project__c
            FROM Status__c
            WHERE Id = :statusId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Status not found: ' + statusId);
        return rows[0];
    }

    /**
     * Status name must be unique within the project — domain invariant.
     */
    public static void requireStatusCreateInputs(String name, String projectId) {
        if (String.isBlank(name)) throw new ServiceException('Status Name is required');
        requireProjectExists(projectId);
        List<Status__c> dupe = [
            SELECT Id FROM Status__c
            WHERE Name = :name AND Project__c = :projectId
            LIMIT 1
        ];
        if (!dupe.isEmpty()) throw new ServiceException('Status name already exists in this project');
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW
    // ═══════════════════════════════════════════════════════════════

    public static Workflow__c requireWorkflowExists(String workflowId) {
        List<Workflow__c> rows = [
            SELECT Id, Name, Project__c
            FROM Workflow__c
            WHERE Id = :workflowId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Workflow not found');
        return rows[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW TRANSITION
    // ═══════════════════════════════════════════════════════════════

    public static WorkflowTransition__c requireTransitionExists(String transitionId) {
        List<WorkflowTransition__c> rows = [
            SELECT Id, Name, Workflow__c, FromStatus__c, ToStatus__c, RecordStatus__c
            FROM WorkflowTransition__c
            WHERE Id = :transitionId AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Workflow Transition not found');
        return rows[0];
    }

    /**
     * FromStatus and ToStatus must not be the same — a transition that loops on itself is invalid.
     */
    public static void requireTransitionStatusesDifferent(String fromStatusId, String toStatusId) {
        if (fromStatusId == toStatusId) {
            throw new ServiceException('From Status and To Status must be different');
        }
    }

    /**
     * Transition name must be unique within the workflow among non-deleted transitions.
     */
    public static void requireTransitionNameUnique(String workflowId, String name) {
        List<WorkflowTransition__c> dupe = [
            SELECT Id FROM WorkflowTransition__c
            WHERE Workflow__c = :workflowId AND Name = :name AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (!dupe.isEmpty()) throw new ServiceException('Transition name already exists in this workflow');
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
    // VALIDATION RULE
    // ═══════════════════════════════════════════════════════════════

    public static ValidationRule__c requireValidationRuleExists(String ruleId) {
        List<ValidationRule__c> rows = [
            SELECT Id, RecordStatus__c, WorkflowTransition__c, TicketField__c, Type__c
            FROM ValidationRule__c
            WHERE Id = :ruleId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Validation Rule not found');
        return rows[0];
    }

    /**
     * Only pending validation rules can be activated.
     */
    public static void requireValidationRuleIsPending(ValidationRule__c rule) {
        if (rule.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
            throw new ServiceException('Validation Rule can only be activated from pending status');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PAGINATION
    // ═══════════════════════════════════════════════════════════════

    public static Integer safeOffset(Integer offset) {
        return (offset != null && offset >= 0) ? offset : 0;
    }

    public static Integer safePageSize(Integer pageSize, Integer defaultPageSize) {
        return (pageSize != null && pageSize > 0) ? pageSize : defaultPageSize;
    }
}

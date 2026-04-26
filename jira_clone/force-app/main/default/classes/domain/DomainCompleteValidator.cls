/**
 * @description Central validator class consolidating all domain-level validation
 *              rules across the application. Group methods by domain section.
 *              Call these before any DML to get a consistent, single error surface.
 *
 *              Convention:
 *                requireXxx(...)          — required field / record, throws if invalid
 *                requireOptionalXxx(...)  — only validates when the value is non-blank
 */
public with sharing class DomainCompleteValidator {

    // ═══════════════════════════════════════════════════════════════
    // PROJECT
    // ═══════════════════════════════════════════════════════════════

    /** projectId must be non-blank before any project lookup */
    public static void requireProjectId(String projectId) {
        if (String.isBlank(projectId)) throw new ServiceException('projectId is required');
    }

    /** project record must exist for the given id */
    public static Project__c requireProjectExists(String projectId) {
        requireProjectId(projectId);
        List<Project__c> rows = [SELECT Id, Name FROM Project__c WHERE Id = :projectId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Project not found');
        return rows[0];
    }

    /** project record must exist for the given name */
    public static Project__c requireProjectExistsByName(String projectName) {
        if (String.isBlank(projectName)) throw new ServiceException('projectName is required');
        List<Project__c> rows = [SELECT Id, Name FROM Project__c WHERE Name = :projectName LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Project not found: ' + projectName);
        return rows[0];
    }

    // ═══════════════════════════════════════════════════════════════
    // PROJECT MEMBER
    // ═══════════════════════════════════════════════════════════════

    /** userId must be non-blank before any member operation */
    public static void requireUserId(String userId) {
        if (String.isBlank(userId)) throw new ServiceException('userId is required');
    }

    /** user record must exist for the given id */
    public static User requireUserExists(String userId) {
        requireUserId(userId);
        List<User> rows = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('User does not exist');
        return rows[0];
    }

    /** both userId and projectId are required to add/remove a member */
    public static void requireProjectMemberInputs(String userId, String projectId) {
        requireUserId(userId);
        requireProjectId(projectId);
    }

    /** memberId must resolve to an active (not soft-deleted) ProjectMember record */
    public static ProjectMember__c requireProjectMemberActive(String memberId) {
        if (String.isBlank(memberId)) throw new ServiceException('memberId is required');
        List<ProjectMember__c> rows = [
            SELECT Id, User__c, Project__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE Id = :memberId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Project member not found or inactive: ' + memberId);
        return rows[0];
    }

    /** if memberId is provided, verify the member exists and is not soft-deleted */
    public static void requireOptionalProjectMemberActive(String memberId) {
        if (String.isBlank(memberId)) return;
        requireProjectMemberActive(memberId);
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE
    // ═══════════════════════════════════════════════════════════════

    /** ticketTypeId must be non-blank before any ticket-type lookup */
    public static void requireTicketTypeId(String ticketTypeId) {
        if (String.isBlank(ticketTypeId)) throw new ServiceException('ticketTypeId is required');
    }

    /** ticket type must exist and be active (RecordStatus__c != 'delete') for the given id */
    public static TicketType__c requireTicketTypeExists(String ticketTypeId) {
        requireTicketTypeId(ticketTypeId);
        List<TicketType__c> rows = [
            SELECT Id, Name, Project__c, Workflow__c, RecordStatus__c
            FROM TicketType__c
            WHERE Id = :ticketTypeId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Ticket Type not found');
        return rows[0];
    }

    /** both ticketTypeName and projectId must be non-blank (input-only check, no DB) */
    public static void requireTicketTypeNameInputs(String ticketTypeName, String projectId) {
        if (String.isBlank(ticketTypeName)) throw new ServiceException('ticketTypeName is required');
        requireProjectId(projectId);
    }

    /** ticket type must exist for the given name within a project */
    public static TicketType__c requireTicketTypeExistsByName(String ticketTypeName, String projectId) {
        requireTicketTypeNameInputs(ticketTypeName, projectId);
        List<TicketType__c> rows = [
            SELECT Id, Name, Project__c FROM TicketType__c
            WHERE Name = :ticketTypeName AND Project__c = :projectId AND RecordStatus__c != 'delete'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Ticket Type not found: ' + ticketTypeName);
        return rows[0];
    }

    /** all fields needed to create a ticket type must be present */
    public static void requireTicketTypeCreateInputs(String name, String workflowId, String projectId) {
        if (String.isBlank(name))       throw new ServiceException('name is required');
        if (String.isBlank(workflowId)) throw new ServiceException('workflowId is required');
        requireProjectId(projectId);
    }

    /** project must exist before a ticket type can be attached to it */
    public static Project__c requireProjectExistsForTicketType(String projectId) {
        return requireProjectExists(projectId);
    }

    /**
     * Workflow must belong to the same project as the ticket type.
     * This is a domain invariant: a ticket type must not reference a workflow from a different project.
     */
    public static void requireWorkflowBelongsToProject(String workflowId, String projectId) {
        requireWorkflowId(workflowId);
        requireProjectId(projectId);
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

    /** ticketId must be non-blank before any ticket lookup */
    public static void requireTicketId(String ticketId) {
        if (String.isBlank(ticketId)) throw new ServiceException('ticketId is required');
    }

    /** ticket record must exist and not be soft-deleted; returns the record */
    public static Ticket__c requireTicketExists(String ticketId) {
        requireTicketId(ticketId);
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

    /** ticketIds list must be non-null and non-empty for bulk operations */
    public static void requireTicketIds(List<String> ticketIds) {
        if (ticketIds == null || ticketIds.isEmpty()) throw new ServiceException('ticketIds are required');
    }

    /** ticket must have a valid, active ticket type linked to it */
    public static TicketType__c requireTicketHasValidTicketType(String ticketTypeId) {
        return requireTicketTypeExists(ticketTypeId);
    }

    /** all fields needed to create a ticket must be present */
    public static void requireTicketCreateInputs(String name, String ticketTypeId) {
        if (String.isBlank(name)) throw new ServiceException('name is required');
        requireTicketTypeId(ticketTypeId);
    }

    /** ticket update payload (full object form) must carry id and name */
    public static void requireTicketUpdateInputs(Ticket__c ticket) {
        if (ticket == null)               throw new ServiceException('ticket is required');
        if (String.isBlank(ticket.Id))    throw new ServiceException('ticketId is required');
        if (String.isBlank(ticket.Name))  throw new ServiceException('name is required');
    }

    /** priority must be provided when updating ticket priority */
    public static void requireTicketPriorityInputs(String ticketId, String priority) {
        requireTicketId(ticketId);
        if (priority == null) throw new ServiceException('priority is required');
    }

    /** stateId must be provided when moving a ticket to a new state */
    public static void requireTicketStateInputs(String ticketId, String stateId) {
        requireTicketId(ticketId);
        if (String.isBlank(stateId)) throw new ServiceException('stateId is required');
    }

    /** summary must be provided when updating a ticket summary */
    public static void requireTicketSummaryInputs(String ticketId, String summary) {
        requireTicketId(ticketId);
        if (summary == null) throw new ServiceException('summary is required');
    }

    /** memberId must be provided when assigning a ticket */
    public static void requireTicketAssignInputs(String ticketId, String memberId) {
        requireTicketId(ticketId);
        if (String.isBlank(memberId)) throw new ServiceException('memberId is required');
    }

    // ─── optional ticket relationship validators ───────────────────

    /** if epicId is provided, the epic must exist and not be soft-deleted */
    public static void requireOptionalEpicActive(String epicId) {
        if (String.isBlank(epicId)) return;
        List<Epic__c> rows = [SELECT Id FROM Epic__c WHERE Id = :epicId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Epic not found: ' + epicId);
    }

    /** if sprintId is provided, the sprint must exist */
    public static void requireOptionalSprintExists(String sprintId) {
        if (String.isBlank(sprintId)) return;
        List<Sprint__c> rows = [SELECT Id FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Sprint not found: ' + sprintId);
    }

    /** if statusId is provided, the status record must exist */
    public static void requireOptionalStatusExists(String statusId) {
        if (String.isBlank(statusId)) return;
        List<Status__c> rows = [SELECT Id FROM Status__c WHERE Id = :statusId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Status not found: ' + statusId);
    }

    // ═══════════════════════════════════════════════════════════════
    // SUBTASK
    // ═══════════════════════════════════════════════════════════════

    /** subtaskId must be non-blank before any subtask lookup */
    public static void requireSubtaskId(String subtaskId) {
        if (String.isBlank(subtaskId)) throw new ServiceException('subtaskId is required');
    }

    /** subtask record must exist and not be soft-deleted; returns the record */
    public static Subtask__c requireSubtaskExists(String subtaskId) {
        requireSubtaskId(subtaskId);
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

    /** subtaskIds list must be non-null and non-empty for bulk operations */
    public static void requireSubtaskIds(List<String> subtaskIds) {
        if (subtaskIds == null || subtaskIds.isEmpty()) throw new ServiceException('subtaskIds are required');
    }

    /** all fields needed to create a subtask must be present */
    public static void requireSubtaskCreateInputs(String summary, String ticketId) {
        if (String.isBlank(summary)) throw new ServiceException('summary is required');
        requireTicketId(ticketId);
    }

    /** subtask update payload (full object form) must carry id and summary */
    public static void requireSubtaskUpdateInputs(Subtask__c subtask) {
        if (subtask == null)                    throw new ServiceException('subtask is required');
        if (String.isBlank(subtask.Id))         throw new ServiceException('subtaskId is required');
        if (String.isBlank(subtask.Summary__c)) throw new ServiceException('summary is required');
    }

    /** memberId must be provided when assigning a subtask */
    public static void requireSubtaskAssignInputs(String subtaskId, String memberId) {
        requireSubtaskId(subtaskId);
        if (String.isBlank(memberId)) throw new ServiceException('memberId is required');
    }

    /** summary must be provided when updating a subtask summary */
    public static void requireSubtaskSummaryInputs(String subtaskId, String summary) {
        requireSubtaskId(subtaskId);
        if (summary == null) throw new ServiceException('summary field is required');
    }

    // ═══════════════════════════════════════════════════════════════
    // EPIC
    // ═══════════════════════════════════════════════════════════════

    /** epicId must be non-blank before any epic lookup */
    public static void requireEpicId(String epicId) {
        if (String.isBlank(epicId)) throw new ServiceException('epicId is required');
    }

    /** epic record must exist; returns the record (Epic__c has no RecordStatus__c) */
    public static Epic__c requireEpicExists(String epicId) {
        requireEpicId(epicId);
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

    /**
     * All fields needed to create an epic must be present and its project must exist.
     * Project__c is required on Epic__c (see field metadata).
     */
    public static void requireEpicCreateInputs(Epic__c epic) {
        if (epic == null)                    throw new ServiceException('Epic is required');
        if (String.isBlank(epic.Name))       throw new ServiceException('name is required');
        if (String.isBlank(epic.Summary__c)) throw new ServiceException('summary is required');
        if (String.isBlank(epic.Project__c)) throw new ServiceException('projectId is required');
        requireProjectExists(epic.Project__c);
    }

    /** epic update payload must carry id and name, and the record must exist */
    public static Epic__c requireEpicUpdateInputs(Epic__c epic) {
        if (epic == null)              throw new ServiceException('Epic is required');
        if (String.isBlank(epic.Id))   throw new ServiceException('epicId is required');
        if (String.isBlank(epic.Name)) throw new ServiceException('name is required');
        return requireEpicExists(epic.Id);
    }

    /** project must exist before an epic can be listed for it */
    public static Project__c requireProjectExistsForEpic(String projectId) {
        return requireProjectExists(projectId);
    }

    // ═══════════════════════════════════════════════════════════════
    // SPRINT
    // ═══════════════════════════════════════════════════════════════

    /** sprintId must be non-blank before any sprint lookup */
    public static void requireSprintId(String sprintId) {
        if (String.isBlank(sprintId)) throw new ServiceException('sprintId is required');
    }

    /** sprint record must exist; returns the record */
    public static Sprint__c requireSprintExists(String sprintId) {
        requireSprintId(sprintId);
        List<Sprint__c> rows = [
            SELECT Id, Name, Project__c, StartDate__c, Duration__c, Goal__c, RecordStatus__c
            FROM Sprint__c
            WHERE Id = :sprintId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Sprint not found');
        return rows[0];
    }

    /** all fields needed to create a sprint must be present. Project__c is required on Sprint__c. */
    public static void requireSprintCreateInputs(Sprint__c sprint) {
        if (sprint == null)                    throw new ServiceException('Sprint is required');
        if (String.isBlank(sprint.Name))       throw new ServiceException('name is required');
        if (String.isBlank(sprint.Project__c)) throw new ServiceException('projectId is required');
    }

    /** sprint update payload must carry id and name */
    public static void requireSprintUpdateInputs(Sprint__c sprint) {
        if (sprint == null)              throw new ServiceException('Sprint is required');
        if (String.isBlank(sprint.Id))   throw new ServiceException('sprintId is required');
        if (String.isBlank(sprint.Name)) throw new ServiceException('name is required');
    }

    /** sprintId must be non-null when assigning a ticket to a sprint */
    public static void requireSprintIdForTicket(Id sprintId) {
        if (sprintId == null) throw new ServiceException('sprintId is required');
    }

    /**
     * Sprint must be in 'future' status to be started.
     * A sprint that is already in_progress or completed cannot be started again.
     */
    public static void requireSprintIsStartable(Sprint__c sprint) {
        if (sprint.RecordStatus__c != 'future') {
            throw new ServiceException('Sprint can only be started from future status, current status: ' + sprint.RecordStatus__c);
        }
    }

    /**
     * Sprint must be in 'in_progress' status to be completed.
     * A sprint that has not been started cannot be completed.
     */
    public static void requireSprintIsCompletable(Sprint__c sprint) {
        if (sprint.RecordStatus__c != 'in_progress') {
            throw new ServiceException('Sprint can only be completed from in_progress status, current status: ' + sprint.RecordStatus__c);
        }
    }

    /**
     * Only one sprint per project can be in_progress at a time.
     * Prevents starting a new sprint when another is already running.
     */
    public static void requireNoActiveSprintInProject(String projectId) {
        requireProjectId(projectId);
        List<Sprint__c> active = [
            SELECT Id FROM Sprint__c
            WHERE Project__c = :projectId AND RecordStatus__c = 'in_progress'
            LIMIT 1
        ];
        if (!active.isEmpty()) throw new ServiceException('Project already has an active sprint in progress');
    }

    // ═══════════════════════════════════════════════════════════════
    // STATUS
    // ═══════════════════════════════════════════════════════════════

    /** statusId must be non-blank before any status lookup */
    public static void requireStatusId(String statusId) {
        if (String.isBlank(statusId)) throw new ServiceException('Status Id is required');
    }

    /** status record must exist for the given id; returns the record */
    public static Status__c requireStatusExists(String statusId) {
        requireStatusId(statusId);
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
     * All fields needed to create a status must be present, the project must exist,
     * and the name must be unique within that project.
     * Status__c.Project__c is required (see field metadata).
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

    /** statusName and projectId must be non-blank, and the project must exist */
    public static void requireStatusUpdateInputs(String statusName, String projectId) {
        if (String.isBlank(statusName)) throw new ServiceException('Status Name is required');
        requireProjectExists(projectId);
    }

    /** projectId must be provided when listing statuses */
    public static void requireProjectIdForStatus(String projectId) {
        requireProjectId(projectId);
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW
    // ═══════════════════════════════════════════════════════════════

    /** workflowId must be non-blank before any workflow operation */
    public static void requireWorkflowId(String workflowId) {
        if (String.isBlank(workflowId)) throw new ServiceException('Workflow Id is required');
    }

    /** workflow name must be non-blank */
    public static void requireWorkflowName(String name) {
        if (String.isBlank(name)) throw new ServiceException('Workflow Name is required');
    }

    /** workflow record must exist for the given id; returns the record */
    public static Workflow__c requireWorkflowExists(String workflowId) {
        requireWorkflowId(workflowId);
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

    /** workflow transition id must be non-blank */
    public static void requireTransitionId(String transitionId) {
        if (String.isBlank(transitionId)) throw new ServiceException('Workflow Transition Id is required');
    }

    /** transition name must be non-blank */
    public static void requireTransitionName(String name) {
        if (String.isBlank(name)) throw new ServiceException('Transition name is required');
    }

    /** both fromStatusId and toStatusId must be non-blank for a transition */
    public static void requireTransitionStatusInputs(String fromStatusId, String toStatusId) {
        if (String.isBlank(fromStatusId)) throw new ServiceException('From Status Id is required');
        if (String.isBlank(toStatusId))   throw new ServiceException('To Status Id is required');
    }

    /**
     * Workflow transition must exist and not be soft-deleted; returns the record.
     * RecordStatus__c = 'deleted' means the transition has been removed.
     */
    public static WorkflowTransition__c requireTransitionExists(String transitionId) {
        requireTransitionId(transitionId);
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
     * FromStatus and ToStatus must not be the same status.
     * A transition that loops on itself is not a valid workflow step.
     */
    public static void requireTransitionStatusesDifferent(String fromStatusId, String toStatusId) {
        requireTransitionStatusInputs(fromStatusId, toStatusId);
        if (fromStatusId == toStatusId) {
            throw new ServiceException('From Status and To Status must be different');
        }
    }

    /**
     * Transition name must be unique within the workflow (among non-deleted transitions).
     * Prevents duplicate transition names that would confuse workflow configuration.
     */
    public static void requireTransitionNameUnique(String workflowId, String name) {
        requireWorkflowId(workflowId);
        requireTransitionName(name);
        List<WorkflowTransition__c> dupe = [
            SELECT Id FROM WorkflowTransition__c
            WHERE Workflow__c = :workflowId AND Name = :name AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (!dupe.isEmpty()) throw new ServiceException('Transition name already exists in this workflow');
    }

    /**
     * Transition must be in 'pending' status to be activated.
     * Only pending transitions can be promoted to active.
     */
    public static void requireTransitionIsPending(WorkflowTransition__c transition) {
        if (transition.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
            throw new ServiceException('Workflow Transition can only be activated from pending status');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // VALIDATION RULE
    // ═══════════════════════════════════════════════════════════════

    /** validation rule id must be non-blank */
    public static void requireValidationRuleId(String ruleId) {
        if (String.isBlank(ruleId)) throw new ServiceException('Validation Rule Id is required');
    }

    /** ticketField and validationType must both be non-blank for a validation rule */
    public static void requireValidationRuleInputs(String ticketField, String validationType) {
        if (String.isBlank(ticketField))    throw new ServiceException('Ticket field is required');
        if (String.isBlank(validationType)) throw new ServiceException('Validation type is required');
    }

    /** validation rule record must exist; returns the record */
    public static ValidationRule__c requireValidationRuleExists(String ruleId) {
        requireValidationRuleId(ruleId);
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
     * Validation rule must be in 'pending' status to be activated.
     * Only pending rules can be promoted to active.
     */
    public static void requireValidationRuleIsPending(ValidationRule__c rule) {
        if (rule.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
            throw new ServiceException('Validation Rule can only be activated from pending status');
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PAGINATION
    // ═══════════════════════════════════════════════════════════════

    /** clamp offset to >= 0; returns 0 when caller omits it */
    public static Integer safeOffset(Integer offset) {
        return (offset != null && offset >= 0) ? offset : 0;
    }

    /** clamp pageSize to a positive value; falls back to defaultPageSize when caller omits it */
    public static Integer safePageSize(Integer pageSize, Integer defaultPageSize) {
        return (pageSize != null && pageSize > 0) ? pageSize : defaultPageSize;
    }
}

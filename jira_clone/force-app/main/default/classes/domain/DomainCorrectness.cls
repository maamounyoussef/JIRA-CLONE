
public with sharing class DomainCorrectness {

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
    // USER / PROJECT MEMBER
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
        if (rows.isEmpty()) throw new ServiceException('Project member not found or deleted: ' + memberId);
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
            SELECT Id, Name, Project__c, Workflow__c, Description__c, IconUrl__c, RecordStatus__c, CreatedDate
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
        if (String.isBlank(epicId)) return;
        List<Epic__c> rows = [SELECT Id FROM Epic__c WHERE Id = :epicId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Epic not found: ' + epicId);
    }

    public static void requireOptionalSprintExists(String sprintId) {
        if (String.isBlank(sprintId)) return;
        List<Sprint__c> rows = [SELECT Id FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Sprint not found: ' + sprintId);
    }

    public static void requireOptionalStatusExists(String statusId) {
        if (String.isBlank(statusId)) return;
        List<Status__c> rows = [SELECT Id FROM Status__c WHERE Id = :statusId LIMIT 1];
        if (rows.isEmpty()) throw new ServiceException('Status not found: ' + statusId);
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

    // ═══════════════════════════════════════════════════════════════
    // STATUS
    // ═══════════════════════════════════════════════════════════════

    public static Status__c requireStatusExists(String statusId) {
        List<Status__c> rows = [
            SELECT Id, Name, Project__c
            FROM Status__c
            WHERE Id = :statusId
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Status not found: ' + statusId);
        return rows[0];
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
            SELECT Id, Name, Workflow__c, FromStatus__c, ToStatus__c,
                   FromStatus__r.Name, ToStatus__r.Name, RecordStatus__c, CreatedDate
            FROM WorkflowTransition__c
            WHERE Id = :transitionId AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Workflow Transition not found');
        return rows[0];
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
}

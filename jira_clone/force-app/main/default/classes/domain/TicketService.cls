/**
 * @description Service class for Ticket, Subtask, and TicketType operations
 */
public with sharing class TicketService {

    private static final Integer DEFAULT_PAGE_SIZE = 5;

    // ═══════════════════════════════════════════════════════════════
    // TICKET — Repository
    // ═══════════════════════════════════════════════════════════════

    public static List<Ticket__c> getActiveTicketsByProjectOrderByPriorityAsc(String projectId) {
        try {
            List<TicketType__c> types = [SELECT Id FROM TicketType__c WHERE Project__c = :projectId];
            if (types.isEmpty()) return new List<Ticket__c>();
            List<Id> typeIds = new List<Id>();
            for (TicketType__c t : types) typeIds.add(t.Id);
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c
                FROM Ticket__c
                WHERE Ticket_Type__c IN :typeIds AND RecordStatus__c = 'active'
                ORDER BY Priority__c ASC, EndDate__c DESC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying tickets: ' + ex.getMessage());
        }
    }

    public static Ticket__c findTicketById(String ticketId) {
        try {
            List<Ticket__c> res = [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c
                FROM Ticket__c
                WHERE Id = :ticketId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving ticket: ' + ex.getMessage());
        }
    }

    public static Ticket__c createTicket(Ticket__c ticket) {
        try {
            // Ticket_Type__c is required — validate it is active and resolve the project
            TicketType__c ticketType = DomainCompleteValidator.requireTicketHasValidTicketType(ticket.Ticket_Type__c);
            String projectId = ticketType.Project__c;

            // Project must exist (TicketType.Project__c is a required lookup)
            DomainCompleteValidator.requireProjectExists(projectId);

            // Optional relationship fields: validate only when provided
            DomainCompleteValidator.requireOptionalEpicActive(ticket.Epic__c);
            DomainCompleteValidator.requireOptionalSprintExists(ticket.Sprint__c);
            DomainCompleteValidator.requireOptionalProjectMemberActive(ticket.AssignedTo__c);
            DomainCompleteValidator.requireOptionalProjectMemberActive(ticket.Creator__c);

            // CurrentState__c is required on Ticket__c — default to Todo when blank or invalid
            if (String.isBlank(ticket.CurrentState__c)) {
                ticket.CurrentState__c = getTodoStatus(projectId).Id;
            } else {
                List<Status__c> existing = [SELECT Id FROM Status__c WHERE Id = :ticket.CurrentState__c LIMIT 1];
                if (existing.isEmpty()) {
                    ticket.CurrentState__c = getTodoStatus(projectId).Id;
                }
            }

            ticket.RecordStatus__c = 'active';
            insert ticket;
            return ticket;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket: ' + ex.getMessage());
        }
    }

    private static Status__c getTodoStatus(String projectId) {
        List<Status__c> statuses = [
            SELECT Id, Name
            FROM Status__c
            WHERE Project__c = :projectId AND Name = 'Todo'
            LIMIT 1
        ];
        if (statuses.isEmpty()) throw new ServiceException('Todo status not found for project: ' + projectId);
        return statuses[0];
    }

    public static Ticket__c updateTicket(Ticket__c ticket) {
        try {
            update ticket;
            return ticket;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket: ' + ex.getMessage());
        }
    }

    public static void deleteTicketsByIds(List<String> ids) {
        try {
            List<Ticket__c> found = [SELECT Id, RecordStatus__c FROM Ticket__c WHERE Id IN :ids];
            if (!found.isEmpty()) {
                for (Ticket__c t : found) t.RecordStatus__c = 'delete';
                update found;
            }
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting tickets: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting tickets: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET — Use cases
    // ═══════════════════════════════════════════════════════════════

    public static Ticket__c assignTicket(String ticketId, String memberId) {
        try {
            DomainCompleteValidator.requireTicketAssignInputs(ticketId, memberId);
            Ticket__c existing = DomainCompleteValidator.requireTicketExists(ticketId);
            // Assignee must be an active project member (has RecordStatus__c)
            DomainCompleteValidator.requireProjectMemberActive(memberId);

            existing.AssignedTo__c = memberId;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning ticket: ' + ex.getMessage());
        }
    }

    public static void deleteTickets(List<String> ticketIds) {
        try {
            DomainCompleteValidator.requireTicketIds(ticketIds);
            deleteTicketsByIds(ticketIds);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting tickets: ' + ex.getMessage());
        }
    }

    public static Ticket__c getTicketById(String ticketId) {
        try {
            DomainCompleteValidator.requireTicketId(ticketId);
            return findTicketById(ticketId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving ticket: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> loadActiveTicketsOrderByPriorityAsc(String projectId) {
        try {
            // Project must exist before querying its tickets
            DomainCompleteValidator.requireProjectExists(projectId);
            return getActiveTicketsByProjectOrderByPriorityAsc(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading tickets: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> getBacklogTicketsByProject(String projectId, Integer offset, Integer pageSize) {
        try {
            List<TicketType__c> types = [SELECT Id FROM TicketType__c WHERE Project__c = :projectId];
            if (types.isEmpty()) return new List<Ticket__c>();
            List<Id> typeIds = new List<Id>();
            for (TicketType__c t : types) typeIds.add(t.Id);

            Integer currentOffset   = DomainCompleteValidator.safeOffset(offset);
            Integer currentPageSize = DomainCompleteValidator.safePageSize(pageSize, DEFAULT_PAGE_SIZE);
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c
                FROM Ticket__c
                WHERE Ticket_Type__c IN :typeIds AND RecordStatus__c = 'active' AND Sprint__c = null
                ORDER BY Priority__c ASC, EndDate__c DESC
                LIMIT :currentPageSize OFFSET :currentOffset
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying backlog tickets: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> loadBacklogTickets(String projectId, Integer offset, Integer pageSize) {
        try {
            DomainCompleteValidator.requireProjectExists(projectId);
            return getBacklogTicketsByProject(projectId, offset, pageSize);
        } catch (Exception ex) {
            throw new ServiceException('Error loading backlog tickets: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> getActiveTicketsBySprintOrderByPriorityAsc(Id sprintId, Integer offset, Integer pageSize) {
        try {
                    if (String.isBlank(sprintId)) throw new ServiceException('sprintId is required');

            Integer currentOffset   = DomainCompleteValidator.safeOffset(offset);
            Integer currentPageSize = DomainCompleteValidator.safePageSize(pageSize, DEFAULT_PAGE_SIZE);
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c
                FROM Ticket__c
                WHERE Sprint__c = :sprintId AND RecordStatus__c = 'active'
                ORDER BY Priority__c ASC, EndDate__c DESC
                LIMIT :currentPageSize OFFSET :currentOffset
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying tickets by sprint: ' + ex.getMessage());
        }
    }

    public static Map<Id, List<Ticket__c>> getActiveTicketsBySprintsOrderByPriorityAsc(List<Id> sprintIds) {
        try {
            Map<Id, List<Ticket__c>> result = new Map<Id, List<Ticket__c>>();
            if (sprintIds == null || sprintIds.isEmpty()) return result;

            for (Id sid : sprintIds) {
                List<Ticket__c> tickets = [
                    SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                           AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                           StartDate__c, EndDate__c
                    FROM Ticket__c
                    WHERE Sprint__c = :sid AND RecordStatus__c = 'active'
                    ORDER BY Priority__c ASC, EndDate__c DESC
                    LIMIT 3
                ];
                result.put(sid, tickets);
            }
            return result;
        } catch (Exception ex) {
            throw new ServiceException('Error querying tickets by sprints: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketPriority(String ticketId, String priority) {
        try {
            DomainCompleteValidator.requireTicketPriorityInputs(ticketId, priority);
            Ticket__c existing = DomainCompleteValidator.requireTicketExists(ticketId);

            existing.Priority__c = priority;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket priority: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketState(String ticketId, String stateId) {
        try {
            DomainCompleteValidator.requireTicketStateInputs(ticketId, stateId);
            // CurrentState__c references Status__c — verify the state record exists
            DomainCompleteValidator.requireOptionalStatusExists(stateId);
            Ticket__c existing = DomainCompleteValidator.requireTicketExists(ticketId);

            existing.CurrentState__c = stateId;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket state: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketSummary(String ticketId, String summary) {
        try {
            DomainCompleteValidator.requireTicketSummaryInputs(ticketId, summary);
            Ticket__c existing = DomainCompleteValidator.requireTicketExists(ticketId);

            existing.Summary__c = summary;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket summary: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketWithValidation(Ticket__c ticket) {
        try {
            DomainCompleteValidator.requireTicketUpdateInputs(ticket);
            // Confirm the record still exists and is not soft-deleted
            DomainCompleteValidator.requireTicketExists(ticket.Id);

            return updateTicket(ticket);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SUBTASK — Repository
    // ═══════════════════════════════════════════════════════════════

    public static List<Subtask__c> findSubtasksByTicket(String ticketId) {
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, StartDate__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Ticket__c = :ticketId AND RecordStatus__c != 'delete'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c findSubtaskById(String subtaskId) {
        try {
            List<Subtask__c> res = [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Id = :subtaskId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c createSubtask(Subtask__c s) {
        try {
            // Ticket__c is required on Subtask__c — validate the parent ticket is active
            DomainCompleteValidator.requireTicketExists(s.Ticket__c);
            // Optional relationship fields: validate only when provided
            DomainCompleteValidator.requireOptionalProjectMemberActive(s.Assignee__c);
            DomainCompleteValidator.requireOptionalStatusExists(s.CurrentState__c);

            s.RecordStatus__c = 'active';
            insert s;
            return s;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtask(Subtask__c s) {
        try {
            update s;
            return s;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasksByIds(List<String> ids) {
        try {
            List<Subtask__c> found = [SELECT Id, RecordStatus__c FROM Subtask__c WHERE Id IN :ids];
            if (!found.isEmpty()) {
                for (Subtask__c s : found) s.RecordStatus__c = 'delete';
                update found;
            }
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting subtasks: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting subtasks: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SUBTASK — Use cases
    // ═══════════════════════════════════════════════════════════════

    public static Subtask__c assignSubtask(String subtaskId, String memberId) {
        try {
            DomainCompleteValidator.requireSubtaskAssignInputs(subtaskId, memberId);
            Subtask__c existing = DomainCompleteValidator.requireSubtaskExists(subtaskId);
            // Assignee must be an active project member (has RecordStatus__c)
            DomainCompleteValidator.requireProjectMemberActive(memberId);

            existing.Assignee__c = memberId;
            return updateSubtask(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasks(List<String> subtaskIds) {
        try {
            DomainCompleteValidator.requireSubtaskIds(subtaskIds);
            deleteSubtasksByIds(subtaskIds);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting subtasks: ' + ex.getMessage());
        }
    }

    public static List<Subtask__c> getSubtasksByTicket(String ticketId) {
        try {
            DomainCompleteValidator.requireTicketId(ticketId);
            return findSubtasksByTicket(ticketId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskSummary(String subtaskId, String summary) {
        try {
            DomainCompleteValidator.requireSubtaskSummaryInputs(subtaskId, summary);
            Subtask__c s = DomainCompleteValidator.requireSubtaskExists(subtaskId);

            s.Summary__c = summary;
            return updateSubtask(s);
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskWithValidation(Subtask__c subtask) {
        try {
            DomainCompleteValidator.requireSubtaskUpdateInputs(subtask);
            // Confirm the record still exists and is not soft-deleted
            DomainCompleteValidator.requireSubtaskExists(subtask.Id);

            return updateSubtask(subtask);
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE — Repository
    // ═══════════════════════════════════════════════════════════════

    public static List<TicketType__c> getTicketTypesByProject(String projectId) {
        return [
            SELECT Id, Name, Project__c, CreatedDate
            FROM TicketType__c
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }

    public static TicketType__c getTicketTypeById(String ticketTypeId) {
        List<TicketType__c> ticketTypes = [
            SELECT Id, Name, Project__c, Workflow__c, Description__c, IconUrl__c, CreatedDate
            FROM TicketType__c
            WHERE Id = :ticketTypeId
            LIMIT 1
        ];
        if (ticketTypes.isEmpty()) throw new ServiceException('Ticket Type not found');
        return ticketTypes[0];
    }

    public static TicketType__c getTicketTypeByName(String ticketTypeName, String projectId) {
        List<TicketType__c> ticketTypes = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM TicketType__c
            WHERE Name = :ticketTypeName AND Project__c = :projectId
            LIMIT 1
        ];
        if (ticketTypes.isEmpty()) throw new ServiceException('Ticket Type not found: ' + ticketTypeName);
        return ticketTypes[0];
    }

    public static TicketType__c createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            TicketType__c ticketType = new TicketType__c(
                Name            = name,
                Description__c  = description,
                IconUrl__c      = iconUrl,
                Workflow__c     = workflowId,
                Project__c      = projectId,
                RecordStatus__c = 'active'
            );
            insert ticketType;
            return ticketType;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating ticket type: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE — Use cases
    // ═══════════════════════════════════════════════════════════════

    public static List<TicketType__c> loadTicketTypes(String projectId) {
        try {
            // Project must exist — ticket types live under a project
            DomainCompleteValidator.requireProjectExists(projectId);
            return getTicketTypesByProject(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket types: ' + ex.getMessage());
        }
    }

    public static TicketType__c getTicketTypeByIdWithValidation(String ticketTypeId) {
        try {
            DomainCompleteValidator.requireTicketTypeId(ticketTypeId);
            return getTicketTypeById(ticketTypeId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    public static TicketType__c getTicketTypeByNameWithValidation(String ticketTypeName, String projectId) {
        try {
            // Validate both inputs are non-blank before querying
            DomainCompleteValidator.requireTicketTypeNameInputs(ticketTypeName, projectId);
            return getTicketTypeByName(ticketTypeName, projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    public static TicketType__c createTicketTypeWithValidation(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            // name, workflowId, and projectId are all required (Workflow__c is required on TicketType__c)
            DomainCompleteValidator.requireTicketTypeCreateInputs(name, workflowId, projectId);
            // Project must exist before attaching a ticket type to it
            DomainCompleteValidator.requireProjectExistsForTicketType(projectId);
            return createTicketType(name, description, iconUrl, workflowId, projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket type: ' + ex.getMessage());
        }
    }
}

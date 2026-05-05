/**
 * @description Service class for Ticket, Subtask, and TicketType operations
 */
public with sharing class TicketService {

    private static final Integer DEFAULT_PAGE_SIZE = 5;

    // ═══════════════════════════════════════════════════════════════
    // TICKET
    // ═══════════════════════════════════════════════════════════════

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
            TicketType__c ticketType = getTicketTypeById(ticket.Ticket_Type__c);
            String projectId = ticketType.Project__c;

            if (String.isBlank(ticket.Creator__c)) {
                String userId = UserInfo.getUserId();
                List<ProjectMember__c> rows = [
                    SELECT Id, User__c, Project__c, RecordStatus__c
                    FROM ProjectMember__c
                    WHERE User__c = :userId AND Project__c = :projectId AND RecordStatus__c != 'delete'
                    LIMIT 1
                ];
                ProjectMember__c creator = rows.isEmpty() ? null : rows[0];
                DomainCompleteValidator.requireCurrentUserMemberForProject(creator, userId);
                ticket.Creator__c = creator.Id;
            }

            if (String.isBlank(ticket.Priority__c)) ticket.Priority__c = 'Medium';

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


    public static Ticket__c assignTicket(Ticket__c existing, String memberId) {
        try {
            existing.AssignedTo__c = memberId;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning ticket: ' + ex.getMessage());
        }
    }

    public static void deleteTicket(Ticket__c ticket) {
        try {
            ticket.RecordStatus__c = 'delete';
            updateTicket(ticket);
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting ticket: ' + ex.getMessage());
        }
    }

    public static void deleteTickets(List<String> ticketIds) {
        try {
            List<Ticket__c> found = [SELECT Id, RecordStatus__c, Ticket_Type__c, Description__c, Creator__c FROM Ticket__c WHERE Id IN :ticketIds];
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

    public static List<Ticket__c> loadBacklogTickets(Project__c project, Integer offset, Integer pageSize) {
        try {
            List<TicketType__c> types = [SELECT Id FROM TicketType__c WHERE Project__c = :project.Id];
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

    public static List<Ticket__c> getActiveTicketsBySprintOrderByPriorityAsc(Sprint__c sprint, Integer offset, Integer pageSize) {
        try {
            Integer currentOffset   = DomainCompleteValidator.safeOffset(offset);
            Integer currentPageSize = DomainCompleteValidator.safePageSize(pageSize, DEFAULT_PAGE_SIZE);
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c
                FROM Ticket__c
                WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
                ORDER BY Priority__c ASC, EndDate__c DESC
                LIMIT :currentPageSize OFFSET :currentOffset
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying tickets by sprint: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> loadActiveTicketsBySprint(Sprint__c sprint) {
        try {
            return [
                SELECT Id, Name, Summary__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Epic__c, Sprint__c, Ticket_Type__c, RecordStatus__c
                FROM Ticket__c
                WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
                ORDER BY Priority__c ASC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error loading active tickets by sprint: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketPriority(Ticket__c existing, String priority) {
        try {
            existing.Priority__c = priority;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket priority: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketSummary(Ticket__c existing, String summary) {
        try {
            existing.Summary__c = summary;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket summary: ' + ex.getMessage());
        }
    }


    // ═══════════════════════════════════════════════════════════════
    // SUBTASK 
    // ═══════════════════════════════════════════════════════════════

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


    public static Subtask__c assignSubtask(Subtask__c existing, String memberId) {
        try {
            existing.Assignee__c = memberId;
            return updateSubtask(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtask(Subtask__c subtask) {
        try {
            subtask.RecordStatus__c = 'delete';
            updateSubtask(subtask);
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasks(List<String> subtaskIds) {
        try {
            List<Subtask__c> found = [SELECT Id, RecordStatus__c FROM Subtask__c WHERE Id IN :subtaskIds];
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

    public static List<Subtask__c> getSubtasksByTicket(Ticket__c ticket) {
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, StartDate__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Ticket__c = :ticket.Id AND RecordStatus__c != 'delete'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskSummary(Subtask__c existing, String summary) {
        try {
            existing.Summary__c = summary;
            return updateSubtask(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskWithValidation(Subtask__c subtask) {
        try {
            return updateSubtask(subtask);
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE
    // ═══════════════════════════════════════════════════════════════

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

    public static List<TicketType__c> loadTicketTypes(Project__c project) {
        try {
            return [
                SELECT
                    Id,
                    Name,
                    Description__c,
                    IconUrl__c,
                    Project__c,
                    RecordStatus__c,
                    Workflow__c,
                    Workflow__r.Name
                FROM TicketType__c
                WHERE Project__c = :project.Id
                AND RecordStatus__c != 'delete'
                ORDER BY Name ASC
            ];

        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket types: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET LINKS
    // ═══════════════════════════════════════════════════════════════

    public static List<Map<String, String>> getTicketLinkTypes() {
        try {
            List<Map<String, String>> result = new List<Map<String, String>>();
            Schema.DescribeFieldResult fieldResult = TicketLink__c.Type__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    result.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            return result;
        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket link types: ' + ex.getMessage());
        }
    }

    public static List<TicketLinkToDto> getTicketLinkedTo(String ticketId) {
        try {
            List<TicketLink__c> links = [
                SELECT Id, Type__c,
                       LinkedToTicket__c,
                       LinkedToTicket__r.Name,
                       LinkedToTicket__r.Summary__c,
                       LinkedToTicket__r.CurrentState__c,
                       LinkedToTicket__r.CurrentState__r.Name,
                       LinkedToTicket__r.AssignedTo__c,
                       LinkedToTicket__r.AssignedTo__r.User__r.Name,
                       LinkedToTicket__r.Priority__c,
                       LinkedToTicket__r.Ticket_Type__c,
                       LinkedToTicket__r.Ticket_Type__r.Name
                FROM TicketLink__c
                WHERE LinkedFromTicket__c = :ticketId AND RecordStatus__c != 'delete'
            ];

            List<TicketLinkToDto> result = new List<TicketLinkToDto>();
            for (TicketLink__c link : links) {
                TicketLinkToDto dto     = new TicketLinkToDto();
                dto.linkId              = link.Id;
                dto.linkType            = link.Type__c;
                dto.ticketId            = link.LinkedToTicket__c;
                dto.ticketName          = link.LinkedToTicket__r.Name;
                dto.summary             = link.LinkedToTicket__r.Summary__c;
                dto.currentStatusId     = link.LinkedToTicket__r.CurrentState__c;
                dto.currentStatusName   = link.LinkedToTicket__r.CurrentState__r.Name;
                dto.assigneeId          = link.LinkedToTicket__r.AssignedTo__c;
                dto.assigneeName        = (link.LinkedToTicket__r.AssignedTo__c != null &&
                                           link.LinkedToTicket__r.AssignedTo__r != null &&
                                           link.LinkedToTicket__r.AssignedTo__r.User__r != null)
                                          ? link.LinkedToTicket__r.AssignedTo__r.User__r.Name
                                          : null;
                dto.priority            = link.LinkedToTicket__r.Priority__c;
                dto.ticketTypeId        = link.LinkedToTicket__r.Ticket_Type__c;
                dto.ticketTypeName      = link.LinkedToTicket__r.Ticket_Type__r.Name;
                result.add(dto);
            }
            return result;
        } catch (Exception ex) {
            throw new ServiceException('Error loading linked tickets: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW STATE CHANGE
    // ═══════════════════════════════════════════════════════════════

    public static Boolean changeTicketState(Ticket__c ticket, String fromStatusId, String toStatusId, List<WorkflowTransition__c> transitions) {
        try {
            DomainCompleteValidator.requireTransitionAllowed(fromStatusId, toStatusId, transitions);
            ticket.CurrentState__c = toStatusId;
            updateTicket(ticket);
            return DomainCompleteValidator.isEndStatus(toStatusId, transitions);
        } catch (Exception ex) {
            throw new ServiceException('Error changing ticket state: ' + ex.getMessage());
        }
    }

}

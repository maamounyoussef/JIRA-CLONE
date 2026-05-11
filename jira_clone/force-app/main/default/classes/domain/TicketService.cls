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

    public static CreateTicketResponse createTicketWithoutSprint(Ticket__c ticket, TicketType__c ticketType) {
        try {
            prepareTicketForInsert(ticket, ticketType);
            insert ticket;
            return new CreateTicketResponse(ticket);
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket: ' + ex.getMessage());
        }
    }

    public static CreateTicketResponse createTicketWithSprint(Ticket__c ticket, TicketType__c ticketType) {
        try {
            Status__c status = prepareTicketForInsert(ticket, ticketType);
            insert ticket;

            Sprint__c updatedSprint;
            if (DomainCompleteValidator.isEndStatus(status)) {
                updatedSprint = SprintService.increaseTotalAndEndedStoryPoint(ticket.Sprint__c, ticket.StoryPoint__c, ticket.StoryPoint__c);
            } else {
                updatedSprint = SprintService.increaseTotalAndEndedStoryPoint(ticket.Sprint__c, ticket.StoryPoint__c, 0);
            }
            return new CreateTicketResponse(ticket, updatedSprint);
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket: ' + ex.getMessage());
        }
    }

    private static Status__c prepareTicketForInsert(Ticket__c ticket, TicketType__c ticketType) {
        String projectId = ticketType.Project__c;

        if (String.isBlank(ticket.Creator__c)) {
            String userId = UserInfo.getUserId();
            ProjectMember__c creator = ProjectService.findActiveMemberByUserAndProject(userId, projectId);
            DomainCompleteValidator.requireCurrentUserMemberForProject(creator, userId);
            ticket.Creator__c = creator.Id;
        }

        if (String.isBlank(ticket.Priority__c)) ticket.Priority__c = 'Medium';

        Status__c status;
        if (String.isBlank(ticket.CurrentState__c)) {
            status = StatusService.getStartStatus(projectId);
        } else {
            status = StatusService.findStatus(ticket.CurrentState__c);
        }
        ticket.CurrentState__c = status.Id;

        ticket.RecordStatus__c = 'active';
        return status;
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

    public static Sprint__c deleteTicket(Ticket__c ticket) {
        try {
            ticket.RecordStatus__c = 'delete';
            updateTicket(ticket);
            if (String.isNotBlank(ticket.Sprint__c)) {
                Status__c status = StatusService.findStatus(ticket.CurrentState__c);
                if(DomainCompleteValidator.isEndStatus(status))
                    return SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, ticket.StoryPoint__c);
                else 
                    return SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, 0);
            }
            return null;
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting ticket: ' + ex.getMessage());
        }
    }
        
    public static List<Sprint__c> deleteTickets(List<Ticket__c> tickets) {
        try {
            if (tickets.isEmpty()) return new List<Sprint__c>();

            for (Ticket__c t : tickets) t.RecordStatus__c = 'delete';
            update tickets;

            Map<String, Decimal> sprintTotalStoryPointMap = new Map<String, Decimal>();
            Map<String, Decimal> sprintEndedStoryPointMap = new Map<String, Decimal>();

            for (Ticket__c t : tickets) {
                if (String.isNotBlank(t.Sprint__c)) {
                    Decimal storyPoints = t.StoryPoint__c != null ? t.StoryPoint__c : 0;

                    Decimal currentTotal = sprintTotalStoryPointMap.containsKey(t.Sprint__c) ? sprintTotalStoryPointMap.get(t.Sprint__c) : 0;
                    sprintTotalStoryPointMap.put(t.Sprint__c, currentTotal + storyPoints);

                    Decimal currentEnded = sprintEndedStoryPointMap.containsKey(t.Sprint__c) ? sprintEndedStoryPointMap.get(t.Sprint__c) : 0;
                    Status__c status = StatusService.findStatus(t.CurrentState__c);
                    Decimal endedPoints = DomainCompleteValidator.isEndStatus(status) ? storyPoints : 0;
                    sprintEndedStoryPointMap.put(t.Sprint__c, currentEnded + endedPoints);
                }
            }

            List<Sprint__c> updatedSprints = new List<Sprint__c>();
            for (String sprintId : sprintTotalStoryPointMap.keySet()) {
                Sprint__c updated = SprintService.decreaseTotalAndEndedStoryPoints(
                    sprintId,
                    sprintTotalStoryPointMap.get(sprintId),
                    sprintEndedStoryPointMap.get(sprintId)
                );
                updatedSprints.add(updated);
            }

            return updatedSprints;
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

    public static Sprint__c removeTicketSprint(Ticket__c ticket) {
        try {
            if (String.isNotBlank(ticket.Sprint__c)) {
                Sprint__c updated;
                Status__c status = StatusService.findStatus(ticket.CurrentState__c);
                if (DomainCompleteValidator.isEndStatus(status))
                    updated = SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, ticket.StoryPoint__c);
                else
                    updated = SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, 0);

                ticket.Sprint__c = null;
                updateTicket(ticket);
                return updated;
            }
            return null;
        } catch (Exception ex) {
            throw new ServiceException('Error removing ticket from sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c moveTicketToSprint(Ticket__c ticket, Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireTicketNotInDifferentSprint(ticket, sprint.Id);
            ticket.Sprint__c = sprint.Id;
            updateTicket(ticket);
            Status__c status = StatusService.findStatus(ticket.CurrentState__c);
            System.debug('status '+status);
            if(DomainCompleteValidator.isEndStatus(status))
                return SprintService.increaseTotalAndEndedStoryPoint(sprint.Id, ticket.StoryPoint__c,ticket.StoryPoint__c);
            else 
                return SprintService.increaseTotalAndEndedStoryPoint(sprint.Id, ticket.StoryPoint__c,0);
        } catch (Exception ex) {
            throw new ServiceException('Error moving ticket to sprint: ' + ex.getMessage());
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

    public static void createTicketLink(String fromTicketId, String toTicketId, String linkType) {
        try {
            TicketLink__c link = new TicketLink__c(
                LinkedFromTicket__c = fromTicketId,
                LinkedToTicket__c   = toTicketId,
                Type__c             = linkType,
                RecordStatus__c     = 'active'
            );
            insert link;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket link: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket link: ' + ex.getMessage());
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

    public static ChangeTicketStateDto changeTicketState(Ticket__c ticket, Status__c fromStatus, Status__c toStatus, List<WorkflowTransition__c> transitions) {
        try {
            DomainCompleteValidator.requireTransitionAllowed(fromStatus.Id, toStatus.Id, transitions);
            ticket.CurrentState__c = toStatus.Id;
            updateTicket(ticket);

            Boolean isEndStatus = DomainCompleteValidator.isEndStatus(toStatus);
            Sprint__c updatedSprint = null;

            if (isEndStatus && String.isNotBlank(ticket.Sprint__c)) {
                updatedSprint = SprintService.increaseTotalAndEndedStoryPoint(ticket.Sprint__c, 0,ticket.StoryPoint__c);
            }

            return new ChangeTicketStateDto(isEndStatus, updatedSprint);
        } catch (Exception ex) {
            throw new ServiceException('Error changing ticket state: ' + ex.getMessage());
        }
    }

}

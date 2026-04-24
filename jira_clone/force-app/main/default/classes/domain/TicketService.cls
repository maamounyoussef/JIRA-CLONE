/**
 * @description Service class for Ticket operations
 * Consolidates all usecases and repository methods for Ticket domain
 */
public with sharing class TicketService {
    
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
                ORDER BY Priority__c ASC , EndDate__c DESC
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
            // check if  the Ticket type  exist 
            List<TicketType__c> ticketTypes = [SELECT Id, Project__c FROM TicketType__c WHERE Id = :ticket.Ticket_Type__c LIMIT 1];
            if (ticketTypes.isEmpty()) throw new ServiceException('Ticket type not found');
            String projectId = ticketTypes[0].Project__c;
            // check if the ticket type belong to a valid project
            ProjectService.getProjectById(projectId);

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
    
    // Use case methods
    public static Ticket__c assignTicket(String ticketId, String memberId) {
        try {
            if (String.isBlank(ticketId)) throw new ServiceException('ticketId is required');
            if (String.isBlank(memberId)) throw new ServiceException('memberId is required');

            Ticket__c existing = findTicketById(ticketId);
            if (existing == null) throw new ServiceException('Ticket not found: ' + ticketId);

            existing.AssignedTo__c = memberId;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning ticket: ' + ex.getMessage());
        }
    }

    public static Ticket__c createTicketWithValidation(Ticket__c ticket) {
        try {
            if (ticket == null) throw new ServiceException('Ticket is required');
            if (String.isBlank(ticket.Ticket_Type__c)) throw new ServiceException('ticket_type is required');
            if (String.isBlank(ticket.Name)) throw new ServiceException('name is required');
            if (String.isBlank(ticket.CurrentState__c)) throw new ServiceException('current_state is required');

            TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Id = :ticket.Ticket_Type__c LIMIT 1];
            if (tt == null) throw new ServiceException('Invalid ticket type');

            Status__c status = [SELECT Id FROM Status__c WHERE Id = :ticket.CurrentState__c LIMIT 1];
            if (status == null) throw new ServiceException('Invalid status');

            return createTicket(ticket);
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket: ' + ex.getMessage());
        }
    }

    public static void deleteTickets(List<String> ticketIds) {
        try {
            if (ticketIds == null || ticketIds.isEmpty()) throw new ServiceException('ticketIds are required');
            deleteTicketsByIds(ticketIds);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting tickets: ' + ex.getMessage());
        }
    }

    public static Ticket__c getTicketById(String ticketId) {
        try {
            if (String.isBlank(ticketId)) throw new ServiceException('ticketId is required');
            return findTicketById(ticketId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving ticket: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> loadActiveTicketsOrderByPriorityAsc(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new ServiceException('projectId is required');
            ProjectService.getProjectById(projectId);
            return getActiveTicketsByProjectOrderByPriorityAsc(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading tickets: ' + ex.getMessage());
        }
    }

    private static final Integer DEFAULT_PAGE_SIZE = 5;

    public static List<Ticket__c> getActiveTicketsBySprintOrderByPriorityAsc(Id sprintId, Integer offset, Integer pageSize) {
        try {
            if (sprintId == null) throw new ServiceException('sprintId is required');
            Integer currentOffset   = (offset   != null && offset   >= 0) ? offset   : 0;
            Integer currentPageSize = (pageSize != null && pageSize >  0) ? pageSize : DEFAULT_PAGE_SIZE;
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
            if (String.isBlank(ticketId)) throw new ServiceException('ticketId is required');
            if (priority == null) throw new ServiceException('priority is required');

            Ticket__c existing = findTicketById(ticketId);
            if (existing == null) throw new ServiceException('Ticket not found: ' + ticketId);

            existing.Priority__c = priority;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket priority: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketState(String ticketId, String stateId) {
        try {
            if (String.isBlank(ticketId)) throw new ServiceException('ticketId is required');
            if (String.isBlank(stateId)) throw new ServiceException('stateId is required');

            Ticket__c existing = findTicketById(ticketId);
            if (existing == null) throw new ServiceException('Ticket not found: ' + ticketId);

            existing.CurrentState__c = stateId;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket state: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketSummary(String ticketId, String summary) {
        try {
            if (String.isBlank(ticketId)) throw new ServiceException('ticketId is required');
            if (summary == null) throw new ServiceException('summary is required');

            Ticket__c existing = findTicketById(ticketId);
            if (existing == null) throw new ServiceException('Ticket not found: ' + ticketId);

            existing.Summary__c = summary;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket summary: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketWithValidation(Ticket__c ticket) {
        try {
            if (ticket == null) throw new ServiceException('ticket is required');
            if (String.isBlank(ticket.Id)) throw new ServiceException('ticketId is required');
            if (String.isBlank(ticket.Name)) throw new ServiceException('name is required');

            Ticket__c existing = findTicketById(ticket.Id);
            if (existing == null) throw new ServiceException('Ticket not found: ' + ticket.Id);

            return updateTicket(ticket);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket: ' + ex.getMessage());
        }
    }
}

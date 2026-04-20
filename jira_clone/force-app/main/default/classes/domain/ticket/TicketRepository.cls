/**
 * @description Repository for Ticket__c database operations
 */
public with sharing class TicketRepository {

    public static List<Ticket__c> getTicketsByProject(String projectId) {
        if (String.isBlank(projectId)) return new List<Ticket__c>();
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
                WHERE Ticket_Type__c IN :typeIds
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw new TicketException('Error querying tickets: ' + ex.getMessage());
        }
    }

    /**
     * @description Retrieve ticket by Id
     * @param ticketId The Id of the ticket
     * @return Ticket__c object or null if not found
     */
    public static Ticket__c findTicketById(String ticketId) {
        if (String.isBlank(ticketId)) return null;
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
            throw new TicketException('Error retrieving ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Create a new Ticket__c record
     * @param ticket The Ticket__c domain object to insert
     * @return The created Ticket__c object with Id
     */
    public static Ticket__c createTicket(Ticket__c ticket) {
        if (ticket == null) throw new TicketException('ticket is required');
        try {
            insert ticket;
            return ticket;
        } catch (DmlException dex) {
            throw new TicketException('DML error creating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new TicketException('Error creating ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Update a Ticket__c record
     * Input is the updated domain object instance, just update directly
     * @param ticket The updated Ticket__c object
     * @return The updated Ticket__c object
     */
    public static Ticket__c updateTicket(Ticket__c ticket) {
        if (ticket == null) throw new TicketException('ticket is required');
        if (String.isBlank(ticket.Id)) throw new TicketException('ticket Id is required');
        try {
            update ticket;
            return ticket;
        } catch (DmlException dex) {
            throw new TicketException('DML error updating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Delete tickets by Id (soft delete via RecordStatus)
     * @param ids List of Ticket Ids to delete
     */
    public static void deleteTicketsByIds(List<String> ids) {
        if (ids == null || ids.isEmpty()) return;
        try {
            List<Ticket__c> found = [SELECT Id, RecordStatus__c FROM Ticket__c WHERE Id IN :ids];
            if (!found.isEmpty()) {
                for (Ticket__c t : found) t.RecordStatus__c = 'delete';
                update found;
            }
        } catch (DmlException dex) {
            throw new TicketException('DML error deleting tickets: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new TicketException('Error deleting tickets: ' + ex.getMessage());
        }
    }
}

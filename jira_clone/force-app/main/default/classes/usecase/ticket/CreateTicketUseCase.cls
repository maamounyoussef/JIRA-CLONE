/**
 * @description UseCase for creating a ticket from domain object
 * Validates required fields and references before creating
 */
public with sharing class CreateTicketUseCase {
    
    public static Ticket__c execute(Ticket__c ticket) {
        try {
            if (ticket == null) throw new TicketException('Ticket is required');
            if (String.isBlank(ticket.TicketType__c)) throw new TicketException('ticket_type is required');
            if (String.isBlank(ticket.Name)) throw new TicketException('name is required');
            if (String.isBlank(ticket.CurrentState__c)) throw new TicketException('current_state is required');

            // Validate ticket type exists
            TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Id = :ticket.TicketType__c LIMIT 1];
            if (tt == null) throw new TicketException('Invalid ticket type');

            // Validate status exists
            Status__c status = [SELECT Id FROM Status__c WHERE Id = :ticket.CurrentState__c LIMIT 1];
            if (status == null) throw new TicketException('Invalid status');

            // Call repo method with domain object
            return TicketRepository.createTicket(ticket);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error creating ticket: ' + ex.getMessage());
        }
    }
}

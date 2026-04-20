/**
 * @description UseCase for updating a ticket with domain object
 * Pattern: Retrieve → Call Repository
 */
public with sharing class UpdateTicketUseCase {
    
    public static Ticket__c execute(Ticket__c ticket) {
        try {
            if (ticket == null) throw new TicketException('ticket is required');
            if (String.isBlank(ticket.Id)) throw new TicketException('ticketId is required');
            if (String.isBlank(ticket.Name)) throw new TicketException('name is required');

            // Retrieve the right object
            Ticket__c existing = GetTicketByIdUseCase.execute(ticket.Id);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticket.Id);

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(ticket);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket: ' + ex.getMessage());
        }
    }
}

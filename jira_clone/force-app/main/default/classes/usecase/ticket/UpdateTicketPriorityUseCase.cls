/**
 * @description UseCase for updating ticket priority
 * Pattern: Retrieve → Update → Call Repository
 */
public with sharing class UpdateTicketPriorityUseCase {
    
    public static Ticket__c execute(String ticketId, String priority) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (priority == null) throw new TicketException('priority is required');

            // Retrieve the right object
            Ticket__c existing = GetTicketByIdUseCase.execute(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.Priority__c = priority;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket priority: ' + ex.getMessage());
        }
    }
}

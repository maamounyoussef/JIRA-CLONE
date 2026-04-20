/**
 * @description UseCase for updating ticket state/status
 * Pattern: Retrieve → Update → Call Repository
 */
public with sharing class UpdateTicketStateUseCase {
    
    public static Ticket__c execute(String ticketId, String stateId) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (String.isBlank(stateId)) throw new TicketException('stateId is required');

            // Retrieve the right object
            Ticket__c existing = GetTicketByIdUseCase.execute(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.CurrentState__c = stateId;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket state: ' + ex.getMessage());
        }
    }
}

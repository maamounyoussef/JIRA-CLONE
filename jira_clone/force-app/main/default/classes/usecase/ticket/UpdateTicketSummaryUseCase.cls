/**
 * @description UseCase for updating ticket summary
 * Pattern: Retrieve → Update → Call Repository
 */
public with sharing class UpdateTicketSummaryUseCase {
    
    public static Ticket__c execute(String ticketId, String summary) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (summary == null) throw new TicketException('summary is required');

            // Retrieve the right object
            Ticket__c existing = GetTicketByIdUseCase.execute(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.Summary__c = summary;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket summary: ' + ex.getMessage());
        }
    }
}

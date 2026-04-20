/**
 * @description UseCase for assigning ticket to a project member
 * Pattern: Retrieve → Update → Call Repository
 */
public with sharing class AssignTicketUseCase {
    
    public static Ticket__c execute(String ticketId, String memberId) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (String.isBlank(memberId)) throw new TicketException('memberId is required');

            // Retrieve the right object
            Ticket__c existing = GetTicketByIdUseCase.execute(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.AssignedTo__c = memberId;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error assigning ticket: ' + ex.getMessage());
        }
    }
}

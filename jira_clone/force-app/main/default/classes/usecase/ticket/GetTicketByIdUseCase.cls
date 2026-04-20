/**
 * @description UseCase for retrieving a ticket by Id
 */
public with sharing class GetTicketByIdUseCase {
    
    public static Ticket__c execute(String ticketId) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            return TicketRepository.findTicketById(ticketId);
        } catch (Exception ex) {
            throw new TicketException('Error retrieving ticket: ' + ex.getMessage());
        }
    }
}

/**
 * @description UseCase for retrieving a TicketType by Id
 */
public class GetTicketTypeByIdUseCase {
    
    /**
     * @description Get a ticket type by Id
     * @param ticketTypeId The ticket type Id
     * @return TicketType__c object
     * @throws TicketTypeException if ticket type not found
     */
    public static TicketType__c execute(String ticketTypeId) {
        try {
            if (String.isBlank(ticketTypeId)) throw new TicketTypeException('ticketTypeId is required');
            return TicketTypeRepository.getTicketTypeById(ticketTypeId);
        } catch (TicketTypeException ttex) {
            throw ttex;
        } catch (Exception ex) {
            throw new TicketTypeException('Error retrieving ticket type: ' + ex.getMessage());
        }
    }
}

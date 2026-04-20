/**
 * @description UseCase for retrieving a TicketType by name
 */
public class GetTicketTypeByNameUseCase {
    
    /**
     * @description Get a ticket type by name and project
     * @param ticketTypeName The ticket type name
     * @param projectId The project Id
     * @return TicketType__c object
     * @throws TicketTypeException if ticket type not found or validation fails
     */
    public static TicketType__c execute(String ticketTypeName, String projectId) {
        try {
            if (String.isBlank(ticketTypeName)) throw new TicketTypeException('ticketTypeName is required');
            if (String.isBlank(projectId)) throw new TicketTypeException('projectId is required');
            return TicketTypeRepository.getTicketTypeByName(ticketTypeName, projectId);
        } catch (TicketTypeException ttex) {
            throw ttex;
        } catch (Exception ex) {
            throw new TicketTypeException('Error retrieving ticket type: ' + ex.getMessage());
        }
    }
}

/**
 * @description Service class for TicketType business logic
 * Handles validation and orchestration of ticket type operations using TicketTypeRepository
 */
public with sharing class TicketTypeService {
    
    /**
     * @description Load all ticket types for a project
     * @param projectId - The Project__c record Id
     * @return List of TicketType__c objects
     * @throws TicketTypeException - If error occurs
     */
    public static List<TicketType__c> loadTicketTypes(String projectId) {
        try {
            validateIdParameter(projectId, 'Project Id');
            
            return TicketTypeRepository.getTicketTypesByProject(projectId);
        } catch (TicketTypeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new TicketTypeException('Error loading ticket types: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get ticket type by name and project
     * @param ticketTypeName - The name of the ticket type
     * @param projectId - The Project__c record Id
     * @return TicketType__c object
     * @throws TicketTypeException - If ticket type not found or other errors occur
     */
    public static TicketType__c getTicketTypeByName(String ticketTypeName, String projectId) {
        try {
            validateNameParameter(ticketTypeName, 'Ticket Type Name');
            validateIdParameter(projectId, 'Project Id');
            
            return TicketTypeRepository.getTicketTypeByName(ticketTypeName, projectId);
        } catch (TicketTypeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new TicketTypeException('Error retrieving ticket type by name: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that a parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws TicketTypeException - If value is blank
     */
    private static void validateNameParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new TicketTypeException(paramName + ' is required');
        }
    }
    
    /**
     * @description Validate that an Id parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws TicketTypeException - If value is blank
     */
    private static void validateIdParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new TicketTypeException(paramName + ' is required');
        }
    }
}

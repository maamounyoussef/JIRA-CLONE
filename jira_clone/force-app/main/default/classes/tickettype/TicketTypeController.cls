/**
 * @description Controller for managing TicketType operations
 * Handles ticket type retrieval and listing
 * Uses TicketTypeService for business logic and TicketTypeRepository for data access
 */
public with sharing class TicketTypeController {
    
    /**
     * @description Load all ticket types for a project
     * @param projectId - The Project__c record Id
     * @return APIResponse containing List<TicketType__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketTypes(String projectId) {
        try {
            List<TicketType__c> ticketTypes = TicketTypeService.loadTicketTypes(projectId);
            return new APIResponse(true, 'Ticket Types loaded successfully', ticketTypes);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading ticket types: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get ticket type by name and project
     * @param ticketTypeName - The name of the ticket type
     * @param projectId - The Project__c record Id
     * @return APIResponse containing TicketType__c in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeByName(String ticketTypeName, String projectId) {
        try {
            TicketType__c ticketType = TicketTypeService.getTicketTypeByName(ticketTypeName, projectId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    /**
     * @description Get ticket type by Id
     * @param ticketTypeId - The TicketType__c record Id
     * @return APIResponse containing TicketType__c in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeById(String ticketTypeId) {
        try {
            TicketType__c ticketType = TicketTypeService.getTicketTypeById(ticketTypeId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }
    /**
     * @description Create a new ticket type
     * @param name - The ticket type name
     * @param description - The ticket type description
     * @param iconUrl - The icon URL
     * @param workflowId - The Workflow__c record Id
     * @param projectId - The Project__c record Id
     * @return APIResponse containing created TicketType__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            TicketType__c ticketType = TicketTypeService.createTicketType(name, description, iconUrl, workflowId, projectId);
            return new APIResponse(true, 'Ticket Type created successfully', ticketType);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket type: ' + ex.getMessage());
        }
    }
}

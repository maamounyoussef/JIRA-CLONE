/**
 * @description Repository class for TicketType-related database operations
 * Handles all SOQL queries and DML operations for ticket type objects
 */
public with sharing class TicketTypeRepository {
    
    /**
     * @description Get all ticket types for a project
     * @param projectId - The Project__c record Id
     * @return List of TicketType__c records
     */
    public static List<TicketType__c> getTicketTypesByProject(String projectId) {
        return [
            SELECT Id, Name, Project__c, CreatedDate
            FROM TicketType__c
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Get ticket type by name and project
     * @param ticketTypeName - The name of the ticket type
     * @param projectId - The Project__c record Id
     * @return TicketType__c record if found
     * @throws TicketTypeException - If ticket type not found
     */
    public static TicketType__c getTicketTypeByName(String ticketTypeName, String projectId) {
        List<TicketType__c> ticketTypes = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM TicketType__c
            WHERE Name = :ticketTypeName
              AND Project__c = :projectId
            LIMIT 1
        ];
        
        if (ticketTypes.isEmpty()) {
            throw new TicketTypeException('Ticket Type not found: ' + ticketTypeName);
        }
        
        return ticketTypes[0];
    }
    

    
    /**
     * @description Create a new ticket type
     * @param name - The ticket type name
     * @param description - The ticket type description
     * @param iconUrl - The icon URL
     * @param workflowId - The Workflow__c record Id
     * @param projectId - The Project__c record Id
     * @return The created TicketType__c record
     * @throws TicketTypeException - If DML exception occurs
     */
    public static TicketType__c createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            TicketType__c ticketType = new TicketType__c(
                Name = name,
                Description__c = description,
                IconUrl__c = iconUrl,
                Workflow__c = workflowId,
                Project__c = projectId
            );
            insert ticketType;
            return ticketType;
        } catch (DmlException ex) {
            throw new TicketTypeException('Error creating ticket type: ' + ex.getMessage());
        }
    }
}

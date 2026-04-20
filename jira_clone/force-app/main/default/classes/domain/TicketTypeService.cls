/**
 * @description Service class for TicketType operations
 * Consolidates all usecases and repository methods for TicketType domain
 */
public with sharing class TicketTypeService {
    
    // Repository methods
    public static List<TicketType__c> getTicketTypesByProject(String projectId) {
        return [
            SELECT Id, Name, Project__c, CreatedDate
            FROM TicketType__c
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    
    public static TicketType__c getTicketTypeByName(String ticketTypeName, String projectId) {
        List<TicketType__c> ticketTypes = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM TicketType__c
            WHERE Name = :ticketTypeName
              AND Project__c = :projectId
            LIMIT 1
        ];
        
        if (ticketTypes.isEmpty()) {
            throw new Exception('Ticket Type not found: ' + ticketTypeName);
        }
        
        return ticketTypes[0];
    }

    public static TicketType__c getTicketTypeById(String ticketTypeId) {
        List<TicketType__c> ticketTypes = [
            SELECT Id, Name, Project__c, Workflow__c, Description__c, IconUrl__c, CreatedDate
            FROM TicketType__c
            WHERE Id = :ticketTypeId
            LIMIT 1
        ];
        
        if (ticketTypes.isEmpty()) {
            throw new Exception('Ticket Type not found');
        }
        
        return ticketTypes[0];
    }
    
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
            throw new Exception('Error creating ticket type: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static TicketType__c createTicketTypeWithValidation(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            if (String.isBlank(name)) throw new Exception('name is required');
            if (String.isBlank(workflowId)) throw new Exception('workflowId is required');
            if (String.isBlank(projectId)) throw new Exception('projectId is required');
            
            ProjectService.getProjectById(projectId);
            
            return createTicketType(name, description, iconUrl, workflowId, projectId);
        } catch (Exception ex) {
            throw new Exception('Error creating ticket type: ' + ex.getMessage());
        }
    }

    public static TicketType__c getTicketTypeByIdWithValidation(String ticketTypeId) {
        try {
            if (String.isBlank(ticketTypeId)) throw new Exception('ticketTypeId is required');
            return getTicketTypeById(ticketTypeId);
        } catch (Exception ex) {
            throw new Exception('Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    public static TicketType__c getTicketTypeByNameWithValidation(String ticketTypeName, String projectId) {
        try {
            if (String.isBlank(ticketTypeName)) throw new Exception('ticketTypeName is required');
            if (String.isBlank(projectId)) throw new Exception('projectId is required');
            return getTicketTypeByName(ticketTypeName, projectId);
        } catch (Exception ex) {
            throw new Exception('Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    public static List<TicketType__c> loadTicketTypes(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new Exception('projectId is required');
            ProjectService.getProjectById(projectId);
            return getTicketTypesByProject(projectId);
        } catch (Exception ex) {
            throw new Exception('Error loading ticket types: ' + ex.getMessage());
        }
    }
}

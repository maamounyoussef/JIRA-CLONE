/**
 * @description Repository class for Status-related database operations
 * Handles all SOQL queries and DML operations for status objects
 */
public with sharing class StatusRepository {
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c records
     */
    public static List<Status__c> getStatusesByProject(String projectId) {
        return [
            SELECT Id, Name, Project__c, CreatedDate
            FROM Status__c
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Get status by name and project
     * @param statusName - The name of the status
     * @param projectId - The Project__c record Id
     * @return Status__c record if found
     * @throws StatusException - If status not found
     */
    public static Status__c getStatusByName(String statusName, String projectId) {
        List<Status__c> statuses = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM Status__c
            WHERE Name = :statusName
              AND Project__c = :projectId
            LIMIT 1
        ];
        
        if (statuses.isEmpty()) {
            throw new StatusException('Status not found: ' + statusName);
        }
        
        return statuses[0];
    }
    
    /**
     * @description Get status by Id
     * @param statusId - The Status__c record Id
     * @return Status__c record
     * @throws StatusException - If status not found
     */
    public static Status__c getStatusById(String statusId) {
        List<Status__c> statuses = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM Status__c
            WHERE Id = :statusId
            LIMIT 1
        ];
        
        if (statuses.isEmpty()) {
            throw new StatusException('Status not found');
        }
        
        return statuses[0];
    }
    
    /**
     * @description Create a new status
     * @param name - The status name
     * @param projectId - The Project__c record Id
     * @return The created Status__c record
     * @throws StatusException - If DML exception occurs
     */
    public static Status__c createStatus(String name, String projectId) {
        try {
            Status__c status = new Status__c(
                Name = name,
                Project__c = projectId
            );
            insert status;
            return status;
        } catch (DmlException ex) {
            throw new StatusException('Error creating status: ' + ex.getMessage());
        }
    }
}

/**
 * @description Controller for managing Status operations
 * Handles status retrieval and listing
 * Uses StatusService for business logic and StatusRepository for data access
 */
public with sharing class StatusController {
    
    /**
     * @description Load all statuses for a project
     * @param projectId - The Project__c record Id
     * @return APIResponse containing List<Status__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadStatuses(String projectId) {
        try {
            List<Status__c> statuses = StatusService.loadStatuses(projectId);
            return new APIResponse(true, 'Statuses loaded successfully', statuses);
        } catch (StatusException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new status
     * @param name - The status name
     * @param projectId - The Project__c record Id
     * @return APIResponse containing created Status__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createStatus(String name, String projectId) {
        try {
            Status__c status = StatusService.createStatus(name, projectId);
            return new APIResponse(true, 'Status created successfully', status);
        } catch (StatusException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating status: ' + ex.getMessage());
        }
    }
}

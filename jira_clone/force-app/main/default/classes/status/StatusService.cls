/**
 * @description Service class for Status business logic
 * Handles validation and orchestration of status operations using StatusRepository
 */
public with sharing class StatusService {
    
    /**
     * @description Load all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c objects
     * @throws StatusException - If error occurs
     */
    public static List<Status__c> loadStatuses(String projectId) {
        try {
            validateIdParameter(projectId, 'Project Id');
            
            return StatusRepository.getStatusesByProject(projectId);
        } catch (StatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new StatusException('Error loading statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get status by name and project
     * @param statusName - The name of the status
     * @param projectId - The Project__c record Id
     * @return Status__c object
     * @throws StatusException - If status not found or other errors occur
     */
    public static Status__c getStatusByName(String statusName, String projectId) {
        try {
            validateNameParameter(statusName, 'Status Name');
            validateIdParameter(projectId, 'Project Id');
            
            return StatusRepository.getStatusByName(statusName, projectId);
        } catch (StatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new StatusException('Error retrieving status by name: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get status by Id
     * @param statusId - The Status__c record Id
     * @return Status__c object
     * @throws StatusException - If status not found or other errors occur
     */
    public static Status__c getStatusById(String statusId) {
        try {
            validateIdParameter(statusId, 'Status Id');
            
            return StatusRepository.getStatusById(statusId);
        } catch (StatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new StatusException('Error retrieving status by id: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new status
     * @param name - The status name
     * @param projectId - The Project__c record Id
     * @return The created Status__c record
     * @throws StatusException - If validation fails or DML error occurs
     */
    public static Status__c createStatus(String name, String projectId) {
        try {
            validateNameParameter(name, 'Status Name');
            validateIdParameter(projectId, 'Project Id');
            
            // Verify project exists
            ProjectRepository.getProjectById(projectId);
            
            return StatusRepository.createStatus(name, projectId);
        } catch (StatusException ex) {
            throw ex;
        } catch (ProjectException ex) {
            throw new StatusException('Invalid project: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new StatusException('Error creating status: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that a parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws StatusException - If value is blank
     */
    private static void validateNameParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new StatusException(paramName + ' is required');
        }
    }
    
    /**
     * @description Validate that an Id parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws StatusException - If value is blank
     */
    private static void validateIdParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new StatusException(paramName + ' is required');
        }
    }
}

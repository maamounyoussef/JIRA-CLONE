/**
 * @description Use Case for retrieving project statuses
 * Single responsibility: Get all statuses for a project
 */
public with sharing class GetProjectStatusesUseCase {
    
    /**
     * @description Execute the use case to get project statuses
     * @param projectId - The Project__c record Id
     * @return List of Status__c objects
     * @throws WorkflowException - If project not found or other errors occur
     */
    public static List<Status__c> execute(String projectId) {
        try {
            validateIdParameter(projectId, 'Project Id');
            
            return WorkflowRepository.getProjectStatuses(projectId);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error retrieving project statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that an Id parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws WorkflowException - If value is blank
     */
    private static void validateIdParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new WorkflowException(paramName + ' is required');
        }
    }
}

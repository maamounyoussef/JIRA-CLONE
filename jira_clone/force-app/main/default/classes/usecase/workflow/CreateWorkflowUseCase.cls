/**
 * @description Use Case for creating a new Workflow
 * Single responsibility: Create workflow record
 */
public with sharing class CreateWorkflowUseCase {
    
    /**
     * @description Execute the use case to create a workflow
     * @param name - The workflow name
     * @param projectId - The Project__c record Id
     * @return The created Workflow__c record
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static Workflow__c execute(String name, String projectId) {
        try {
            validateNameParameter(name, 'Workflow Name');
            validateIdParameter(projectId, 'Project Id');
            
            return WorkflowRepository.createWorkflow(name, projectId);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error creating workflow: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that a parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws WorkflowException - If value is blank
     */
    private static void validateNameParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new WorkflowException(paramName + ' is required');
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

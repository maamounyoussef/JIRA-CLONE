/**
 * @description Use Case for loading all transitions for a workflow
 * Single responsibility: Retrieve workflow transitions
 */
public with sharing class LoadWorkflowTransitionsUseCase {
    
    /**
     * @description Execute the use case to load transitions
     * @param workflowId - The Workflow__c record Id
     * @return List of WorkflowTransition__c objects
     * @throws WorkflowException - If error occurs
     */
    public static List<WorkflowTransition__c> execute(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            return WorkflowTransitionRepository.getTransitionsByWorkflow(workflowId);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error loading workflow transitions: ' + ex.getMessage());
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

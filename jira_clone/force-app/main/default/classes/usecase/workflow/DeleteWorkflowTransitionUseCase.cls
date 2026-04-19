/**
 * @description Use Case for deleting a WorkflowTransition
 * Single responsibility: Soft delete workflow transition
 */
public with sharing class DeleteWorkflowTransitionUseCase {
    
    /**
     * @description Execute the use case to delete a workflow transition
     * Performs soft delete by setting status to deleted
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @throws WorkflowException - If transition not found or other errors occur
     */
    public static void execute(String workflowTransitionId) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            // Get the transition
            WorkflowTransition__c transition = WorkflowTransitionRepository.getTransitionById(workflowTransitionId);
            
            // Soft delete: set status to deleted
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            
            WorkflowRepository.updateRecord(transition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error deleting workflow transition: ' + ex.getMessage());
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

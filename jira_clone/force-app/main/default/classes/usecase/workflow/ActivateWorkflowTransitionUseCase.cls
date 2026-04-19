/**
 * @description Use Case for activating a WorkflowTransition
 * Single responsibility: Activate workflow transition from pending to active
 */
public with sharing class ActivateWorkflowTransitionUseCase {
    
    /**
     * @description Execute the use case to activate a workflow transition
     * Changes status from pending to active
     * One-way operation: can only go from pending to active, not the reverse
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @throws WorkflowException - If transition not pending or other errors occur
     */
    public static void execute(String workflowTransitionId) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            // Get the transition
            WorkflowTransition__c transition = WorkflowTransitionRepository.getTransitionById(workflowTransitionId);
            
            // Can only activate if currently pending
            if (transition.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
                throw new WorkflowException(
                    'Workflow Transition can only be activated from pending status'
                );
            }
            
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            WorkflowRepository.updateRecord(transition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error activating workflow transition: ' + ex.getMessage());
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

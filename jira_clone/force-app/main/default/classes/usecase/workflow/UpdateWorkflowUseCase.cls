/**
 * @description Use Case for updating a Workflow - activates all pending transitions and validation rules
 * Single responsibility: Activate all pending workflow items
 */
public with sharing class UpdateWorkflowUseCase {
    
    /**
     * @description Execute the use case to update workflow
     * Activates all pending transitions and validation rules for the workflow
     * This is called when the user clicks the Update Workflow button
     * Precondition: At least one new transition or validation rule must have been added
     * @param workflowId - The Workflow__c record Id
     * @throws WorkflowException - If workflow not found or other errors occur
     */
    public static void execute(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            // Verify Workflow exists
            WorkflowRepository.getWorkflowById(workflowId);
            
            // Get all pending transitions and validation rules for this workflow
            List<WorkflowTransition__c> pendingTransitions = 
                WorkflowRepository.getPendingTransitions(workflowId);
            
            List<ValidationRule__c> pendingRules = 
                WorkflowRepository.getPendingRules(workflowId);
            
            // Activate all pending transitions
            for (WorkflowTransition__c transition : pendingTransitions) {
                transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            }
            
            // Activate all pending validation rules
            for (ValidationRule__c rule : pendingRules) {
                rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            }
            
            // Perform bulk update
            List<SObject> recordsToUpdate = new List<SObject>();
            recordsToUpdate.addAll(pendingTransitions);
            recordsToUpdate.addAll(pendingRules);
            
            WorkflowRepository.updateRecords(recordsToUpdate);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error updating workflow: ' + ex.getMessage());
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

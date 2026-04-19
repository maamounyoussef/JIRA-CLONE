/**
 * @description Use Case for adding a new Workflow Transition
 * Single responsibility: Create a workflow transition with pending status
 */
public with sharing class AddWorkflowTransitionUseCase {
    
    /**
     * @description Execute the use case to add a workflow transition
     * Creates new WorkflowTransition with pending status
     * @param workflowId - The Workflow__c record Id
     * @param name - The name of the transition
     * @param fromStatusId - The Id of the from status
     * @param toStatusId - The Id of the to status
     * @return Created WorkflowTransition__c with pending status
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static WorkflowTransition__c execute(String workflowId, String name, String fromStatusId, String toStatusId) {
        try {
            // Validate inputs
            validateIdParameter(workflowId, 'Workflow Id');
            
            if (String.isBlank(name)) {
                throw new WorkflowException('Transition name is required');
            }
            
            validateIdParameter(fromStatusId, 'From Status Id');
            validateIdParameter(toStatusId, 'To Status Id');
            
            // Verify Workflow exists
            WorkflowRepository.getWorkflowById(workflowId);
            
            // Verify both statuses exist
            List<Status__c> statuses = WorkflowRepository.getStatusesById(
                new List<String> { fromStatusId, toStatusId }
            );
            
            if (statuses.size() != 2) {
                throw new WorkflowException('One or both statuses not found');
            }
            
            // Ensure transition name is unique within the workflow
            if (WorkflowTransitionRepository.transitionNameExists(workflowId, name)) {
                throw new WorkflowException('Transition name already exists in this workflow');
            }
            
            // Create new Workflow Transition with pending status
            WorkflowTransition__c newTransition = new WorkflowTransition__c();
            newTransition.Workflow__c = workflowId;
            newTransition.Name = name;
            newTransition.FromStatus__c = fromStatusId;
            newTransition.ToStatus__c = toStatusId;
            newTransition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return WorkflowTransitionRepository.insertWorkflowTransition(newTransition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (StatusException ex) {
            throw new WorkflowException('Invalid status: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new WorkflowException('Error adding workflow transition: ' + ex.getMessage());
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

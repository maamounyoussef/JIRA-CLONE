/**
 * @description Use Case for creating a new WorkflowTransition
 * Single responsibility: Create workflow transition record
 */
public with sharing class CreateWorkflowTransitionUseCase {
    
    /**
     * @description Execute the use case to create a workflow transition
     * @param name - The transition name
     * @param workflowId - The Workflow__c record Id
     * @param fromStatusId - The from Status__c record Id
     * @param toStatusId - The to Status__c record Id
     * @param recordStatus - The record status indicator (optional)
     * @return The created WorkflowTransition__c record
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static WorkflowTransition__c execute(String name, String workflowId, String fromStatusId, String toStatusId, String recordStatus) {
        try {
            validateNameParameter(name, 'Transition Name');
            validateIdParameter(workflowId, 'Workflow Id');
            validateIdParameter(fromStatusId, 'From Status Id');
            validateIdParameter(toStatusId, 'To Status Id');
            
            // Verify workflow exists
            WorkflowRepository.getWorkflowById(workflowId);
            
            // Verify statuses exist
            StatusRepository.getStatusById(fromStatusId);
            StatusRepository.getStatusById(toStatusId);
            
            // Ensure transition name is unique within the workflow
            if (WorkflowTransitionRepository.transitionNameExists(workflowId, name)) {
                throw new WorkflowException('Transition name already exists in this workflow');
            }
            
            return WorkflowTransitionRepository.createTransition(name, workflowId, fromStatusId, toStatusId, recordStatus);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (StatusException ex) {
            throw new WorkflowException('Invalid status: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new WorkflowException('Error creating workflow transition: ' + ex.getMessage());
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

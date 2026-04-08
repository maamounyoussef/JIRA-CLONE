/**
 * @description Service class for WorkflowTransition business logic
 * Handles validation and orchestration of workflow transition operations using WorkflowTransitionRepository
 */
public with sharing class WorkflowTransitionService {
    
    /**
     * @description Load all transitions for a workflow
     * @param workflowId - The Workflow__c record Id
     * @return List of WorkflowTransition__c objects
     * @throws WorkflowException - If error occurs
     */
    public static List<WorkflowTransition__c> loadTransitions(String workflowId) {
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
     * @description Get transition by Id
     * @param transitionId - The WorkflowTransition__c record Id
     * @return WorkflowTransition__c object
     * @throws WorkflowException - If transition not found or other errors occur
     */
    public static WorkflowTransition__c getTransitionById(String transitionId) {
        try {
            validateIdParameter(transitionId, 'Transition Id');
            
            return WorkflowTransitionRepository.getTransitionById(transitionId);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error retrieving workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new workflow transition
     * @param name - The transition name
     * @param workflowId - The Workflow__c record Id
     * @param fromStatusId - The from Status__c record Id
     * @param toStatusId - The to Status__c record Id
     * @param recordStatus - The record status indicator (optional)
     * @return The created WorkflowTransition__c record
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static WorkflowTransition__c createTransition(String name, String workflowId, String fromStatusId, String toStatusId, String recordStatus) {
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

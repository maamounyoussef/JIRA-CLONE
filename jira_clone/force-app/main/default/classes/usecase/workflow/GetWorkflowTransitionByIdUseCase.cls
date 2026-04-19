/**
 * @description Use Case for retrieving a WorkflowTransition by ID
 * Single responsibility: Retrieve workflow transition details
 */
public with sharing class GetWorkflowTransitionByIdUseCase {
    
    /**
     * @description Execute the use case to get workflow transition by ID
     * @param transitionId - The WorkflowTransition__c record Id
     * @return WorkflowTransition__c object
     * @throws WorkflowException - If transition not found or other errors occur
     */
    public static WorkflowTransition__c execute(String transitionId) {
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

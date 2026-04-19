/**
 * @description Use Case for adding a Validation Rule to a Workflow Transition
 * Single responsibility: Create validation rule with pending status
 */
public with sharing class AddValidationRuleUseCase {
    
    /**
     * @description Execute the use case to add a validation rule
     * Creates new ValidationRule with pending status
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @param ticketField - The ticket field to validate
     * @param validationType - The type of validation (e.g., "not equals")
     * @return Created ValidationRule__c with pending status
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static ValidationRule__c execute(String workflowTransitionId, String ticketField, String validationType) {
        try {
            // Validate inputs
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            if (String.isBlank(ticketField)) {
                throw new WorkflowException('Ticket field is required');
            }
            
            if (String.isBlank(validationType)) {
                throw new WorkflowException('Validation type is required');
            }
            
            // Verify Workflow Transition exists
            WorkflowRepository.getWorkflowTransitionById(workflowTransitionId);
            
            // Create new Validation Rule with pending status
            ValidationRule__c newRule = new ValidationRule__c();
            newRule.WorkflowTransition__c = workflowTransitionId;
            newRule.TicketField__c = ticketField;
            newRule.Type__c = validationType;
            newRule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return WorkflowRepository.insertValidationRule(newRule);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error adding validation rule: ' + ex.getMessage());
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

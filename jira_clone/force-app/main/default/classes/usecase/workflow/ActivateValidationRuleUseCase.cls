/**
 * @description Use Case for activating a Validation Rule
 * Single responsibility: Activate validation rule from pending to active
 */
public with sharing class ActivateValidationRuleUseCase {
    
    /**
     * @description Execute the use case to activate a validation rule
     * Changes status from pending to active
     * One-way operation: can only go from pending to active, not the reverse
     * @param validationRuleId - The ValidationRule__c record Id
     * @throws WorkflowException - If rule not pending or other errors occur
     */
    public static void execute(String validationRuleId) {
        try {
            validateIdParameter(validationRuleId, 'Validation Rule Id');
            
            // Get the rule
            ValidationRule__c rule = WorkflowRepository.getValidationRuleById(validationRuleId);
            
            // Can only activate if currently pending
            if (rule.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
                throw new WorkflowException(
                    'Validation Rule can only be activated from pending status'
                );
            }
            
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            WorkflowRepository.updateRecord(rule);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error activating validation rule: ' + ex.getMessage());
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

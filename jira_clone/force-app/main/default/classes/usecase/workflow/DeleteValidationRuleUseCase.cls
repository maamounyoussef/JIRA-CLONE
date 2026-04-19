/**
 * @description Use Case for deleting a Validation Rule
 * Single responsibility: Soft delete validation rule
 */
public with sharing class DeleteValidationRuleUseCase {
    
    /**
     * @description Execute the use case to delete a validation rule
     * Performs soft delete by setting status to deleted
     * @param validationRuleId - The ValidationRule__c record Id
     * @throws WorkflowException - If rule not found or other errors occur
     */
    public static void execute(String validationRuleId) {
        try {
            validateIdParameter(validationRuleId, 'Validation Rule Id');
            
            // Get the rule
            ValidationRule__c rule = WorkflowRepository.getValidationRuleById(validationRuleId);
            
            // Soft delete: set status to deleted
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            
            WorkflowRepository.updateRecord(rule);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error deleting validation rule: ' + ex.getMessage());
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

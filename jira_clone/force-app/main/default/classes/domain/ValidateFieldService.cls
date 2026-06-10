/**
 * @description Service class for ValidateField__c operations
 * Owns all SOQL/DML for the ValidateField__c domain (validation rules that
 * assert a Ticket field passes a given validation type).
 */
public with sharing class ValidateFieldService {

    /**
     * @description Build and insert a single ValidateField__c from the chosen
     * Ticket field API name and validation type. The required ErrorMessage__c is
     * derived server-side so the LWC form only needs the two picklists.
     * @param fieldName - The Ticket field API name to validate (FieldName__c)
     * @param type - The validation type (Type__c)
     * @return The inserted ValidateField__c record
     */
    public static ValidateField__c createValidateField(String workflowTransitionId , String fieldName, String type) {
        try {
            DomainCompleteValidator.requireValidateFieldUnique(
                getMatchingValidateFields(workflowTransitionId ,fieldName , type)
            );

            ValidateField__c rule = new ValidateField__c(
                FieldName__c    = fieldName,
                Type__c         = type,
                ErrorMessage__c = buildErrorMessage(fieldName, type),
                RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE,
                workflowTransition__c = workflowTransitionId
            );
            insert rule;
            return rule;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating validation field: ' + ex.getMessage());
        }
    }

    /**
     * @description Fetch any existing (non-deleted) ValidateField__c that already
     * asserts the same field + validation type, so the caller can enforce the
     * (FieldName__c, Type__c) uniqueness invariant before inserting.
     */
    private static List<ValidateField__c> getMatchingValidateFields(String workflowTransitionId, String fieldName, String type) {
        return [
            SELECT Id
            FROM ValidateField__c
            WHERE WorkflowTransition__c  = : workflowTransitionId
              AND FieldName__c = :fieldName
              AND Type__c = :type
              AND RecordStatus__c != :WorkflowConstants.RECORD_STATUS_DELETED
        ];
    }

    /**
     * @description Derive the user-facing failure message from the field + type,
     * e.g. "Summary__c Isn't Empty".
     */
    private static String buildErrorMessage(String fieldName, String type) {
        return fieldName + ' ' + type;
    }
}

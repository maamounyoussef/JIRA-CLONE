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
    public static ValidateField__c createValidateField(String fieldName, String type) {
        try {
            ValidateField__c rule = new ValidateField__c(
                FieldName__c    = fieldName,
                Type__c         = type,
                ErrorMessage__c = buildErrorMessage(fieldName, type),
                RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE
            );
            insert rule;
            return rule;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating validation field: ' + ex.getMessage());
        }
    }

    /**
     * @description Derive the user-facing failure message from the field + type,
     * e.g. "Summary__c Isn't Empty".
     */
    private static String buildErrorMessage(String fieldName, String type) {
        return fieldName + ' ' + type;
    }
}

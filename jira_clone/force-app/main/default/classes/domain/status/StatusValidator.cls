/**
 * @description Validator for Status__c business rules
 */
public with sharing class StatusValidator {

    /**
     * @description Check if a Status exists by ID
     * @param statusId The Status ID
     * @return true if the Status exists, false otherwise
     */
    public static Boolean exists(String statusId) {
        if (String.isBlank(statusId)) return false;
        try {
            List<Status__c> statuses = [
                SELECT Id
                FROM Status__c
                WHERE Id = :statusId
                LIMIT 1
            ];
            return !statuses.isEmpty();
        } catch (Exception ex) {
            throw new StatusException('Error checking status existence: ' + ex.getMessage());
        }
    }
}

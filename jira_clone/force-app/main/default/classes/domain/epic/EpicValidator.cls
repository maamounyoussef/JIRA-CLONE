/**
 * @description Validator for Epic__c business rules
 */
public with sharing class EpicValidator {

    /**
     * @description Check if an Epic exists by ID
     * @param epicId The Epic ID
     * @return true if the Epic exists, false otherwise
     */
    public static Boolean exists(String epicId) {
        if (String.isBlank(epicId)) return false;
        try {
            List<Epic__c> epics = [
                SELECT Id
                FROM Epic__c
                WHERE Id = :epicId
                LIMIT 1
            ];
            return !epics.isEmpty();
        } catch (Exception ex) {
            throw new EpicException('Error checking epic existence: ' + ex.getMessage());
        }
    }
}

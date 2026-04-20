/**
 * @description Validator for Sprint__c business rules
 */
public with sharing class SprintValidator {

    /**
     * @description Check if a Sprint exists by ID
     * @param sprintId The Sprint ID
     * @return true if the Sprint exists, false otherwise
     */
    public static Boolean exists(String sprintId) {
        if (String.isBlank(sprintId)) return false;
        try {
            List<Sprint__c> sprints = [
                SELECT Id
                FROM Sprint__c
                WHERE Id = :sprintId
                LIMIT 1
            ];
            return !sprints.isEmpty();
        } catch (Exception ex) {
            throw new SprintException('Error checking sprint existence: ' + ex.getMessage());
        }
    }
}

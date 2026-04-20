/**
 * @description Validator for Subtask__c business rules
 */
public with sharing class SubtaskValidator {

    /**
     * @description Check if a Subtask exists by ID
     * @param subtaskId The Subtask ID
     * @return true if the Subtask exists, false otherwise
     */
    public static Boolean exists(String subtaskId) {
        if (String.isBlank(subtaskId)) return false;
        try {
            List<Subtask__c> subtasks = [
                SELECT Id
                FROM Subtask__c
                WHERE Id = :subtaskId
                LIMIT 1
            ];
            return !subtasks.isEmpty();
        } catch (Exception ex) {
            throw new SubtaskException('Error checking subtask existence: ' + ex.getMessage());
        }
    }
}

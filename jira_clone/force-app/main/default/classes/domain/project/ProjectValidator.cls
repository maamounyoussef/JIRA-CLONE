/**
 * @description Validator for Project__c business rules
 */
public with sharing class ProjectValidator {

    /**
     * @description Check if a Project exists by ID
     * @param projectId The Project ID
     * @return true if the Project exists, false otherwise
     */
    public static Boolean exists(String projectId) {
        if (String.isBlank(projectId)) return false;
        try {
            List<Project__c> projects = [
                SELECT Id
                FROM Project__c
                WHERE Id = :projectId
                LIMIT 1
            ];
            return !projects.isEmpty();
        } catch (Exception ex) {
            throw new ProjectException('Error checking project existence: ' + ex.getMessage());
        }
    }
}

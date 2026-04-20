/**
 * @description Validator for ProjectMember__c business rules
 */
public with sharing class ProjectMemberValidator {

    /**
     * @description Check if a ProjectMember exists by ID
     * @param projectMemberId The ProjectMember ID
     * @return true if the ProjectMember exists, false otherwise
     */
    public static Boolean exists(String projectMemberId) {
        if (String.isBlank(projectMemberId)) return false;
        try {
            List<ProjectMember__c> members = [
                SELECT Id
                FROM ProjectMember__c
                WHERE Id = :projectMemberId
                LIMIT 1
            ];
            return !members.isEmpty();
        } catch (Exception ex) {
            throw new ProjectMemberException('Error checking project member existence: ' + ex.getMessage());
        }
    }
}

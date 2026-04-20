/**
 * @description Service class for ProjectMember operations
 * Consolidates all usecases and repository methods for ProjectMember domain
 */
public with sharing class ProjectMemberService {
    
    // Repository methods
    public static List<ProjectMember__c> getMembersByProject(String projectId) {
        return [
            SELECT Id, Name, User__c, User__r.Name, Project__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE Project__c = :projectId
            ORDER BY Name
        ];
    }
    
    public static ProjectMember__c createMember(String userId, String projectId, String recordStatus) {
        try {
            ProjectMember__c pm = new ProjectMember__c(
                User__c       = userId,
                Project__c    = projectId,
                RecordStatus__c = recordStatus
            );

            insert pm;
            return pm;
        } catch (DmlException ex) {
            throw new Exception('DML error: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static ProjectMember__c createProjectMember(String userId, String projectId, String recordStatus) {
        try {
            List<User> users = [SELECT Id FROM User WHERE Id = :userId LIMIT 1];
            if (users.isEmpty()) {
                throw new Exception('User does not exist');
            }
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (projects.isEmpty()) {
                throw new Exception('Project does not exist');
            }
            return createMember(userId, projectId, recordStatus);
        } catch (Exception ex) {
            throw new Exception('Error creating project member: ' + ex.getMessage());
        }
    }

    public static List<ProjectMember__c> loadProjectMembers(String projectId) {
        try {
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (projects.isEmpty()) {
                throw new Exception('Project does not exist');
            }
            return getMembersByProject(projectId);
        } catch (Exception ex) {
            throw new Exception('Error loading project members: ' + ex.getMessage());
        }
    }
}

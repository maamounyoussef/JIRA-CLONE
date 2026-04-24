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
    

    
    // Use case methods
    public static ProjectMember__c createProjectMember(String userId, String projectId, String recordStatus) {
        try {
            List<User> users = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
            if (users.isEmpty()) {
                throw new ServiceException('User does not exist');
            }
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (projects.isEmpty()) {
                throw new ServiceException('Project does not exist');
            }
            String memberName = users[0].Name + '-' + generateUUID();
            ProjectMember__c pm = new ProjectMember__c(
                Name          = memberName,
                User__c       = userId,
                Project__c    = projectId,
                RecordStatus__c = recordStatus
            );

            insert pm;
            return pm;
        } catch (Exception ex) {
            throw new ServiceException('Error creating project member: ' + ex.getMessage());
        }
    }

    private static String generateUUID() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0,8) + '-' + h.substring(8,12) + '-' + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20,32);
    }

    public static List<ProjectMember__c> loadProjectMembers(String projectId) {
        try {
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (projects.isEmpty()) {
                throw new ServiceException('Project does not exist');
            }
            return getMembersByProject(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading project members: ' + ex.getMessage());
        }
    }
}

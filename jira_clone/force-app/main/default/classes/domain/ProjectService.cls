/**
 * @description Service class for Project and ProjectMember operations
 */
public with sharing class ProjectService {

    // ═══════════════════════════════════════════════════════════════
    // PROJECT  
    // ═══════════════════════════════════════════════════════════════

    public static Project__c createProject(String name) {
        try {
            Project__c project = new Project__c(Name = name);
            insert project;
            return project;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating project: ' + ex.getMessage());
        }
    }

    public static List<Project__c> loadProjects() {
        try {
            return [SELECT Id, Name, CreatedDate FROM Project__c ORDER BY Name ASC];
        } catch (Exception ex) {
            throw new ServiceException('Error loading projects: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PROJECT MEMBER 
    // ═══════════════════════════════════════════════════════════════

    public static ProjectMember__c createProjectMember(String userId, String projectId, String recordStatus) {
        try {
            User u = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
            String memberName = u.Name + '-' + generateUUID();

            ProjectMember__c pm = new ProjectMember__c(
                Name            = memberName,
                User__c         = userId,
                Project__c      = projectId,
                RecordStatus__c = recordStatus
            );
            insert pm;
            return pm;
        } catch (Exception ex) {
            throw new ServiceException('Error creating project member: ' + ex.getMessage());
        }
    }

    public static List<ProjectMember__c> loadProjectMembers(Project__c project) {
        try {
                return [
        SELECT
            Id,
            Name,
            Project__c,
            User__c,
            User__r.Name,
            User__r.Email,
            RecordStatus__c
        FROM ProjectMember__c
        WHERE Project__c = :project.Id
          AND RecordStatus__c != 'delete'   // exclude soft-deleted members
        ORDER BY User__r.Name ASC NULLS LAST
        ];
        } catch (Exception ex) {
            throw new ServiceException('Error loading project members: ' + ex.getMessage());
        }
    }

    private static String generateUUID() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0,8) + '-' + h.substring(8,12) + '-' + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20,32);
    }
}

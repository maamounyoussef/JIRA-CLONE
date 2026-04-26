/**
 * @description Service class for Project and ProjectMember operations
 */
public with sharing class ProjectService {

    // ═══════════════════════════════════════════════════════════════
    // PROJECT — Repository
    // ═══════════════════════════════════════════════════════════════

    public static Project__c getProjectByName(String projectName) {
        List<Project__c> projects = [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            WHERE Name = :projectName
            LIMIT 1
        ];
        if (projects.isEmpty()) throw new ServiceException('Project not found: ' + projectName);
        return projects[0];
    }

    public static Project__c getProjectById(String projectId) {
        List<Project__c> projects = [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        if (projects.isEmpty()) throw new ServiceException('Project not found');
        return projects[0];
    }

    public static Project__c createProject(String name) {
        try {
            Project__c project = new Project__c(Name = name);
            insert project;
            return project;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating project: ' + ex.getMessage());
        }
    }

    private static List<Project__c> getAllProjects() {
        return [SELECT Id, Name, CreatedDate FROM Project__c ORDER BY Name ASC];
    }

    private static List<ProjectMember__c> getMembersByProject(String projectId) {
        return [
            SELECT Id, Name, User__c, Project__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE Project__c = :projectId
        ];
    }

    // ═══════════════════════════════════════════════════════════════
    // PROJECT — Use cases
    // ═══════════════════════════════════════════════════════════════

    public static Project__c getProjectByNameWithValidation(String projectName) {
        try {
            return getProjectByName(projectName);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving project by name: ' + ex.getMessage());
        }
    }

    public static List<Project__c> loadProjects() {
        try {
            return getAllProjects();
        } catch (Exception ex) {
            throw new ServiceException('Error loading projects: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PROJECT MEMBER — Use cases
    // ═══════════════════════════════════════════════════════════════

    public static ProjectMember__c createProjectMember(String userId, String projectId, String recordStatus) {
        try {
            // Validate user exists and project exists before any DML
            DomainCompleteValidator.requireUserExists(userId);
            DomainCompleteValidator.requireProjectExists(projectId);

            // Re-query user Name for the member record name
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

    public static List<ProjectMember__c> loadProjectMembers(String projectId) {
        try {
            // Project__c is required on ProjectMember__c — confirm it exists first
            DomainCompleteValidator.requireProjectExists(projectId);
            return getMembersByProject(projectId);
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

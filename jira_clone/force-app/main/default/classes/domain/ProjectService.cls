/**
 * @description Service class for Project and ProjectMember operations
 */
public with sharing class ProjectService {

    // ═══════════════════════════════════════════════════════════════
    // PROJECT  
    // ═══════════════════════════════════════════════════════════════

    // After insert, ProjectTrigger automatically creates default 'Todo' (isStart) and 'Done' (isEnd) statuses if they don't exist.
    // Also seeds the per-project NameSequence__c row with all counters at 0 so subsequent
    // Sprint/Ticket/Subtask creates can derive default Names (SPR-N, TKT-N, SUB-N).
    public static Project__c createProject(String name) {
        try {
            Project__c project = new Project__c(Name = name);
            insert project;
            NameSequenceService.createForProject(project.Id);
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

    public static Project__c findProjectById(String projectId) {
        try {
            List<Project__c> rows = [
                SELECT Id, Name, BacklogMaxScore__c
                FROM Project__c
                WHERE Id = :projectId
                LIMIT 1
            ];
            return rows.isEmpty() ? null : rows[0];
        } catch (Exception ex) {
            throw new ServiceException('Error finding project: ' + ex.getMessage());
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

    public static ProjectMember__c findActiveMemberByUserAndProject(String userId, String projectId) {
        try {
            List<ProjectMember__c> rows = [
                SELECT Id, User__c, Project__c, RecordStatus__c
                FROM ProjectMember__c
                WHERE User__c = :userId AND Project__c = :projectId AND RecordStatus__c != 'delete'
                LIMIT 1
            ];
            return rows.isEmpty() ? null : rows[0];
        } catch (Exception ex) {
            throw new ServiceException('Error finding project member: ' + ex.getMessage());
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
            Role__c,
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

    public static List<User> searchUsersByTerm(String projectId, String searchTerm) {
        try {
            Set<Id> alreadyMemberUserIds = new Set<Id>();
            for (ProjectMember__c pm : [
                SELECT User__c
                FROM ProjectMember__c
                WHERE Project__c = :projectId
                  AND RecordStatus__c != 'delete'
            ]) {
                if (pm.User__c != null) {
                    alreadyMemberUserIds.add(pm.User__c);
                }
            }

            // Escape special SOSL characters
            String sanitized = searchTerm
                .replace('\\', '\\\\')
                .replace('"', '\\"')
                .replace('?', '\\?')
                .replace('&', '\\&')
                .replace('|', '\\|')
                .replace('!', '\\!')
                .replace('{', '\\{')
                .replace('}', '\\}')
                .replace('[', '\\[')
                .replace(']', '\\]')
                .replace('(', '\\(')
                .replace(')', '\\)')
                .replace('^', '\\^')
                .replace('~', '\\~')
                .replace('*', '\\*')
                .replace(':', '\\:')
                .replace('\'', '\\\'');

            String soslQuery = 'FIND {*' + sanitized + '*} IN ALL FIELDS ' +
                               'RETURNING User(Id, Name, Username ' +
                               'WHERE IsActive = true ' +
                               'ORDER BY Name ASC LIMIT 50)';

            List<List<SObject>> searchResults = Search.query(soslQuery);
            List<User> users = (List<User>) searchResults[0];

            List<User> eligible = new List<User>();
            for (User u : users) {
                if (!alreadyMemberUserIds.contains(u.Id)) {
                    eligible.add(u);
                }
                if (eligible.size() >= 20) break;
            }
            return eligible;
        } catch (Exception ex) {
            throw new ServiceException('Error searching users: ' + ex.getMessage());
        }
    }

    public static ProjectMember__c updateMemberRole(String memberId, String role) {
        try {
            List<ProjectMember__c> rows = [
                SELECT Id, Role__c, RecordStatus__c
                FROM ProjectMember__c
                WHERE Id = :memberId
                  AND RecordStatus__c != 'delete'
                LIMIT 1
            ];
            if (rows.isEmpty()) {
                throw new ServiceException('Project member not found.');
            }
            ProjectMember__c pm = rows[0];
            pm.Role__c = role;
            update pm;
            return pm;
        } catch (Exception ex) {
            throw new ServiceException('Error updating member role: ' + ex.getMessage());
        }
    }

    public static ProjectMember__c softDeleteMember(String memberId) {
        try {
            List<ProjectMember__c> rows = [
                SELECT Id, RecordStatus__c
                FROM ProjectMember__c
                WHERE Id = :memberId
                  AND RecordStatus__c != 'delete'
                LIMIT 1
            ];
            if (rows.isEmpty()) {
                throw new ServiceException('Project member not found.');
            }
            ProjectMember__c pm = rows[0];
            pm.RecordStatus__c = 'delete';
            update pm;
            return pm;
        } catch (Exception ex) {
            throw new ServiceException('Error removing member: ' + ex.getMessage());
        }
    }

    private static String generateUUID() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0,8) + '-' + h.substring(8,12) + '-' + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20,32);
    }
}

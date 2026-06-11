/**
 * @description Controller for the manageProjectMember LWC.
 * Thin AuraEnabled methods that delegate to ProjectService and return APIResponse.
 */
public with sharing class ManageProjectMemberController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadAllProjects() {
        try {
            List<Project__c> projects = ProjectService.loadProjects();
            return new APIResponse(true, 'Projects loaded', projects);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading projects: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadMembers(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                return new APIResponse(false, 'projectId is required');
            }
            InputSecurityValidator.validatePageAccessManageProjectMember(projectId);
            Project__c project = new Project__c(Id = projectId);
            List<ProjectMember__c> members = ProjectService.loadProjectMembers(project);
            return new APIResponse(true, 'Members loaded', members);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading members: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse searchUsersByTerm(String projectId, String searchTerm) {
        try {
            if (String.isBlank(projectId))  return new APIResponse(false, 'projectId is required');
            if (String.isBlank(searchTerm)) return new APIResponse(false, 'searchTerm is required');

            List<User> users = ProjectService.searchUsersByTerm(projectId, searchTerm);
            return new APIResponse(true, 'Users loaded', users);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error searching users: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse addMember(String projectId, String userId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            if (String.isBlank(userId))    return new APIResponse(false, 'userId is required');

            ProjectMember__c existing = ProjectService.findActiveMemberByUserAndProject(userId, projectId);
            if (existing != null) {
                return new APIResponse(false, 'Already a member of this project');
            }

            ProjectMember__c pm = ProjectService.createProjectMember(userId, projectId, 'active');

            List<ProjectMember__c> rows = [
                SELECT Id, Name, Project__c, User__c, User__r.Name, User__r.Email,
                       Role__c, RecordStatus__c
                FROM ProjectMember__c
                WHERE Id = :pm.Id
                  AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            return new APIResponse(true, 'Member added', rows.isEmpty() ? pm : rows[0]);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error adding member: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateMemberRole(String memberId, String role) {
        try {
            if (String.isBlank(memberId)) return new APIResponse(false, 'memberId is required');
            if (String.isBlank(role))     return new APIResponse(false, 'role is required');

            ProjectMember__c updated = ProjectService.updateMemberRole(memberId, role);
            return new APIResponse(true, 'Member updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating member: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteMember(String memberId) {
        try {
            if (String.isBlank(memberId)) return new APIResponse(false, 'memberId is required');

            ProjectMember__c deleted = ProjectService.softDeleteMember(memberId);
            return new APIResponse(true, 'Member removed', deleted);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error removing member: ' + ex.getMessage());
        }
    }
}

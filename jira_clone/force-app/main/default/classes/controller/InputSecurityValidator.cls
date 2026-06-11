/**
 * @description Validator for page-level access control based on user roles
 * Enforces role-based access to pages on page load
 */
public with sharing class InputSecurityValidator {

    // All available roles
    private static final Set<String> ALL_ROLES = new Set<String>{'Admin', 'PPO', 'Scrum Master', 'Developer', 'Consultant', 'Test Factory'};

    // Page-level access control
    private static final Set<String> PAGE_MANAGE_BACKLOG = new Set<String>{'Admin', 'PPO', 'Scrum Master'};
    private static final Set<String> PAGE_MANAGE_TICKET_TRACKING = new Set<String>{'Admin', 'PPO', 'Scrum Master', 'Developer'};
    private static final Set<String> PAGE_MANAGE_TICKET_TYPE = new Set<String>{'Admin', 'PPO'};
    private static final Set<String> PAGE_MANAGE_PROJECT_MEMBER = new Set<String>{'Admin', 'PPO'};
    private static final Set<String> PAGE_MANAGE_WORKFLOW = new Set<String>{'Admin', 'PPO', 'Scrum Master'};

    // Page-level access validation methods (call on page load)

    public static void validatePageAccessManageBacklog(String projectId) {
        validatePageAccess(projectId, PAGE_MANAGE_BACKLOG);
    }

    public static void validatePageAccessManageTicketTracking(String projectId) {
        validatePageAccess(projectId, PAGE_MANAGE_TICKET_TRACKING);
    }

    public static void validatePageAccessManageTicketType(String projectId) {
        validatePageAccess(projectId, PAGE_MANAGE_TICKET_TYPE);
    }

    public static void validatePageAccessManageProjectMember(String projectId) {
        validatePageAccess(projectId, PAGE_MANAGE_PROJECT_MEMBER);
    }

    public static void validatePageAccessManageWorkflow(String projectId) {
        validatePageAccess(projectId, PAGE_MANAGE_WORKFLOW);
    }

    private static void validatePageAccess(String projectId, Set<String> allowedRoles) {
        String userRole = getUserRoleInProject(projectId);
        if (!allowedRoles.contains(userRole)) {
            throw new InputSecurityException('Access denied. Your role "' + userRole + '" does not have permission to access this page');
        }
    }

    // AuraEnabled method for LWC to call on page load to determine tab visibility
    @AuraEnabled(cacheable=true)
    public static APIResponse getUserRoleForUI(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                return new APIResponse(false, 'projectId is required');
            }
            String userRole = getUserRoleInProject(projectId);
            Map<String, Object> data = new Map<String, Object>{
                'userRole' => userRole,
                'canManageBacklog' => PAGE_MANAGE_BACKLOG.contains(userRole),
                'canManageTicketTracking' => PAGE_MANAGE_TICKET_TRACKING.contains(userRole),
                'canManageTicketType' => PAGE_MANAGE_TICKET_TYPE.contains(userRole),
                'canManageProjectMember' => PAGE_MANAGE_PROJECT_MEMBER.contains(userRole),
                'canManageWorkflow' => PAGE_MANAGE_WORKFLOW.contains(userRole)
            };
            return new APIResponse(true, 'User role loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading user role: ' + ex.getMessage());
        }
    }

    // Get current user's role for a project (internal use)
    private static String getUserRoleInProject(String projectId) {
        Id currentUserId = UserInfo.getUserId();

        List<ProjectMember__c> members = [
            SELECT Role__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE User__c = :currentUserId
              AND Project__c = :projectId
              AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];

        if (members.isEmpty()) {
            return 'Guest';
        }

        String role = members[0].Role__c;
        return String.isBlank(role) ? 'Developer' : role;
    }

    public class InputSecurityException extends Exception {}
}

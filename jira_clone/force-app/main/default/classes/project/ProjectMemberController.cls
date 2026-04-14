/**
 * @description Server-side creator for ProjectMember__c that adapts to installed fields
 */
public with sharing class ProjectMemberController {

    @AuraEnabled
    public static APIResponse createMember(String userId, String projectId, String recordStatus) {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey('ProjectMember__c')) {
                return new APIResponse(false, 'ProjectMember__c object not found in org');
            }

            Schema.SObjectType t = gd.get('ProjectMember__c');
            Map<String, Schema.SObjectField> fieldsMap = t.getDescribe().fields.getMap();
            SObject pm = t.newSObject();

            // set user lookup
            if (userId != null) {
                if (fieldsMap.containsKey('User__c')) pm.put('User__c', userId);
                else if (fieldsMap.containsKey('Member__c')) pm.put('Member__c', userId);
                else if (fieldsMap.containsKey('UserId__c')) pm.put('UserId__c', userId);
                else return new APIResponse(false, 'No user lookup field found on ProjectMember__c');
            }

            // set project lookup
            if (projectId != null) {
                if (fieldsMap.containsKey('Project__c')) pm.put('Project__c', projectId);
                else return new APIResponse(false, 'No project lookup field found on ProjectMember__c');
            }

            // optional record status
            if (recordStatus != null && fieldsMap.containsKey('RecordStatus__c')) pm.put('RecordStatus__c', recordStatus);

            insert pm;
            return new APIResponse(true, 'Project member created', pm);
        } catch (DmlException dex) {
            return new APIResponse(false, 'DML error: ' + dex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project member: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadMembers(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                return new APIResponse(false, 'projectId is required');
            }
            List<ProjectMember__c> members = [
                SELECT Id, Name, User__c, User__r.Name, Project__c, RecordStatus__c
                FROM ProjectMember__c
                WHERE Project__c = :projectId
                ORDER BY Name
            ];
            return new APIResponse(true, 'Project members loaded', members);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading project members: ' + ex.getMessage());
        }
    }

}

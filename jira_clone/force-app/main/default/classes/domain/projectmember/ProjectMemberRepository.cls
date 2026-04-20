/**
 * @description Repository class for ProjectMember-related database operations
 * Handles all SOQL queries and DML operations for project member objects
 */
public with sharing class ProjectMemberRepository {
    
    /**
     * @description Get all project members for a given project
     * @param projectId - The Project__c record Id
     * @return List of ProjectMember__c records
     */
    public static List<ProjectMember__c> getMembersByProject(String projectId) {
        return [
            SELECT Id, Name, User__c, User__r.Name, Project__c, RecordStatus__c
            FROM ProjectMember__c
            WHERE Project__c = :projectId
            ORDER BY Name
        ];
    }
    
    /**
     * @description Create a new project member
     * @param userId - The User Id
     * @param projectId - The Project__c record Id
     * @param recordStatus - Optional record status
     * @return The created ProjectMember__c record
     * @throws ProjectMemberException - If DML exception occurs
     */
    public static ProjectMember__c createMember(String userId, String projectId, String recordStatus) {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey('ProjectMember__c')) {
                throw new ProjectMemberException('ProjectMember__c object not found in org');
            }

            Schema.SObjectType t = gd.get('ProjectMember__c');
            Map<String, Schema.SObjectField> fieldsMap = t.getDescribe().fields.getMap();
            SObject pm = t.newSObject();

            // set user lookup
            if (userId != null) {
                if (fieldsMap.containsKey('User__c')) pm.put('User__c', userId);
                else if (fieldsMap.containsKey('Member__c')) pm.put('Member__c', userId);
                else if (fieldsMap.containsKey('UserId__c')) pm.put('UserId__c', userId);
                else throw new ProjectMemberException('No user lookup field found on ProjectMember__c');
            }

            // set project lookup
            if (projectId != null) {
                if (fieldsMap.containsKey('Project__c')) pm.put('Project__c', projectId);
                else throw new ProjectMemberException('No project lookup field found on ProjectMember__c');
            }

            // optional record status
            if (recordStatus != null && fieldsMap.containsKey('RecordStatus__c')) pm.put('RecordStatus__c', recordStatus);

            insert pm;
            return (ProjectMember__c) pm;
        } catch (DmlException ex) {
            throw new ProjectMemberException('DML error: ' + ex.getMessage());
        } catch (ProjectMemberException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectMemberException('Error creating project member: ' + ex.getMessage());
        }
    }
}

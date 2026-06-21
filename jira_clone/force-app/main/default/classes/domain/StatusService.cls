/**
 * @description Service class for Status operations
 * Consolidates all usecases and repository methods for Status domain
 */
public with sharing class StatusService {

    public static Status__c createStatus(String name, String projectId) {
        try {
            List<Status__c> existingStatuses = [
                SELECT Id
                FROM Status__c
                WHERE Name = :name AND Project__c = :projectId AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];

            if (!existingStatuses.isEmpty()) {
                throw new ServiceException('A status with this name already exists for this project');
            }

            Status__c status = new Status__c(
                Name = name,
                Project__c = projectId,
                RecordStatus__c = 'active'
            );
            insert status;
            return status;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating status: ' + ex.getMessage());
        }
    }

    public static List<Status__c> loadStatuses(Project__c project) {
        try {
            return [
                SELECT Id, Name, Project__c, CreatedDate, isEnd__c, isStart__c
                FROM Status__c
                WHERE Project__c = :project.Id AND RecordStatus__c != 'deleted'
                ORDER BY Name ASC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error loading statuses: ' + ex.getMessage());
        }
    }

    public static Status__c findStatus(String statusId)
    {
        try {
            return [
                SELECT Id, Name, Project__c, CreatedDate, isEnd__c, isStart__c
                FROM Status__c
                WHERE Id = :statusId AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error finding statuses: ' + ex.getMessage());
        }
    }

    /**
     * Bulk-resolve status Ids → Status__c (Id, Name) for history-log rendering.
     * One query for the whole set (no SOQL in a loop).
     * intentional: omits RecordStatus__c != 'deleted' so a historical state name
     * still renders even if that status was later soft-deleted (audit display).
     */
    public static Map<Id, Status__c> findStatusesByIds(Set<Id> statusIds) {
        Map<Id, Status__c> byId = new Map<Id, Status__c>();
        if (statusIds == null || statusIds.isEmpty()) return byId;
        try {
            for (Status__c s : [SELECT Id, Name FROM Status__c WHERE Id IN :statusIds]) {
                byId.put(s.Id, s);
            }
            return byId;
        } catch (Exception ex) {
            throw new ServiceException('Error resolving statuses: ' + ex.getMessage());
        }
    }

    public static Status__c getStartStatus(String projectId)
    {
        try {
            return [
                SELECT Id, Name, Project__c, CreatedDate, isEnd__c, isStart__c
                FROM Status__c
                WHERE Project__c = :projectId AND isStart__c = true AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error getting start status: ' + ex.getMessage());
        }
    }

    public static void deleteStatus(String statusId) {
        try {
            Status__c status = new Status__c(
                Id = statusId,
                RecordStatus__c = 'deleted'
            );
            update status;
        } catch (DmlException ex) {
            throw new ServiceException('Error deleting status: ' + ex.getMessage());
        }
    }
}

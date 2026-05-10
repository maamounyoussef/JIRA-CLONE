/**
 * @description Service class for Status operations
 * Consolidates all usecases and repository methods for Status domain
 */
public with sharing class StatusService {

    public static Status__c createStatus(String name, String projectId) {
        try {
            Status__c status = new Status__c(
                Name = name,
                Project__c = projectId
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
                WHERE Project__c = :project.Id
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
                WHERE Id = :statusId
                LIMIT 1
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error finding statuses: ' + ex.getMessage());
        }
    }

    public static Status__c getStartStatus(String projectId)
    {
        return [
            SELECT Id, Name, Project__c, CreatedDate, isEnd__c, isStart__c
            FROM Status__c
            WHERE Project__c = :projectId AND isStart__c = true
            LIMIT 1
        ];
    }
}

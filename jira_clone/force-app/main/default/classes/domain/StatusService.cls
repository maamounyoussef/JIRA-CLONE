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
                SELECT Id, Name, Project__c, CreatedDate
                FROM Status__c
                WHERE Project__c = :project.Id
                ORDER BY Name ASC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error loading statuses: ' + ex.getMessage());
        }
    }
}

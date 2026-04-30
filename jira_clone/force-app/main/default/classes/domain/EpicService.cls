/**
 * @description Service class for Epic operations
 * Consolidates all usecases and repository methods for Epic domain
 */
public with sharing class EpicService {

    public static Epic__c updateEpic(Epic__c epic) {
        try {
            update epic;
            return epic;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating epic: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating epic: ' + ex.getMessage());
        }
    }

    // Use case methods
    public static Epic__c createEpicWithValidation(Epic__c epic) {
        try {
            epic.CreatedAt__c = DateTime.now();
            epic.UpdatedAt__c = DateTime.now();
            insert epic;
            return epic;
        } catch (Exception ex) {
            throw new ServiceException('Error creating epic: ' + ex.getMessage());
        }
    }

    public static Epic__c getEpicById(String epicId) {
       try {
            List<Epic__c> res = [
                SELECT Id, Name, Summary__c, Description__c, StartDate__c, EndDate__c, Project__c
                FROM Epic__c
                WHERE Id = :epicId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving epic: ' + ex.getMessage());
        }
    }

    public static List<Epic__c> getEpicsByProject(Project__c project) {
        try {
                    return [
                        SELECT Id, Name, Summary__c, Description__c, StartDate__c, EndDate__c, Project__c
                        FROM Epic__c
                        WHERE Project__c = :project.Id
                        ORDER BY Name ASC
                    ];
                } catch (Exception ex) {
                    throw new ServiceException('Error querying epics: ' + ex.getMessage());
        }
    }

}

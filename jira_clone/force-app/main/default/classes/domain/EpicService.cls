/**
 * @description Service class for Epic operations
 * Consolidates all usecases and repository methods for Epic domain
 */
public with sharing class EpicService {
    
    // Repository methods
    public static List<Epic__c> findEpicsByProject(String projectId) {
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, StartDate__c, EndDate__c, Project__c
                FROM Epic__c
                WHERE Project__c = :projectId
                ORDER BY Name ASC
            ];
        } catch (Exception ex) {
            throw new Exception('Error querying epics: ' + ex.getMessage());
        }
    }

    public static Epic__c findEpicById(String epicId) {
        try {
            List<Epic__c> res = [
                SELECT Id, Name, Summary__c, Description__c, StartDate__c, EndDate__c, Project__c
                FROM Epic__c
                WHERE Id = :epicId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new Exception('Error retrieving epic: ' + ex.getMessage());
        }
    }

    public static Epic__c createEpic(Epic__c epic) {
        try {
            insert epic;
            return epic;
        } catch (DmlException dex) {
            throw new Exception('DML error creating epic: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error creating epic: ' + ex.getMessage());
        }
    }

    public static Epic__c updateEpic(Epic__c epic) {
        try {
            update epic;
            return epic;
        } catch (DmlException dex) {
            throw new Exception('DML error updating epic: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error updating epic: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static Epic__c createEpicWithValidation(Epic__c epic) {
        try {
            if (epic == null) {
                throw new Exception('Epic is required');
            }
            if (String.isBlank(epic.Name)) {
                throw new Exception('name is required');
            }
            if (String.isBlank(epic.Summary__c)) {
                throw new Exception('summary is required');
            }
            if (String.isBlank(epic.Project__c)) {
                throw new Exception('projectId is required');
            }
            
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :epic.Project__c LIMIT 1];
            if (projects.isEmpty()) {
                throw new Exception('Project not found');
            }
            
            return createEpic(epic);
        } catch (Exception ex) {
            throw new Exception('Error creating epic: ' + ex.getMessage());
        }
    }

    public static Epic__c getEpicById(String epicId) {
        try {
            if (String.isBlank(epicId)) {
                throw new Exception('epicId is required');
            }
            
            return findEpicById(epicId);
        } catch (Exception ex) {
            throw new Exception('Error retrieving epic: ' + ex.getMessage());
        }
    }

    public static List<Epic__c> getEpicsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                throw new Exception('projectId is required');
            }
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (projects.isEmpty()) {
                throw new Exception('Project not found');
            }
            
            return findEpicsByProject(projectId);
        } catch (Exception ex) {
            throw new Exception('Error loading epics: ' + ex.getMessage());
        }
    }

    public static Epic__c updateEpicWithValidation(Epic__c epic) {
        try {
            if (epic == null) {
                throw new Exception('Epic is required');
            }
            if (String.isBlank(epic.Id)) {
                throw new Exception('epicId is required');
            }
            if (String.isBlank(epic.Name)) {
                throw new Exception('name is required');
            }
            
            Epic__c existing = findEpicById(epic.Id);
            if (existing == null) {
                throw new Exception('Epic not found: ' + epic.Id);
            }
            
            return updateEpic(epic);
        } catch (Exception ex) {
            throw new Exception('Error updating epic: ' + ex.getMessage());
        }
    }
}

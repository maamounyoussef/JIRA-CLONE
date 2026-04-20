/**
 * @description Service class for Status operations
 * Consolidates all usecases and repository methods for Status domain
 */
public with sharing class StatusService {
    
    // Repository methods
    public static List<Status__c> getStatusesByProject(String projectId) {
        return [
            SELECT Id, Name, Project__c, CreatedDate
            FROM Status__c
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    
    public static Status__c getStatusByName(String statusName, String projectId) {
        List<Status__c> statuses = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM Status__c
            WHERE Name = :statusName
              AND Project__c = :projectId
            LIMIT 1
        ];
        
        if (statuses.isEmpty()) {
            throw new ServiceException('Status not found: ' + statusName);
        }
        
        return statuses[0];
    }
    
    public static Status__c getStatusById(String statusId) {
        List<Status__c> statuses = [
            SELECT Id, Name, Project__c, CreatedDate
            FROM Status__c
            WHERE Id = :statusId
            LIMIT 1
        ];
        
        if (statuses.isEmpty()) {
            throw new ServiceException('Status not found');
        }
        
        return statuses[0];
    }
    
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
    
    public static Boolean statusNameExists(String projectId, String name) {
        String normalized = name.trim();
        List<Status__c> found = [
            SELECT Id
            FROM Status__c
            WHERE Project__c = :projectId
            AND Name = :normalized
            LIMIT 1
        ];
        return !found.isEmpty();
    }
    
    // Use case methods
    public static Status__c createStatusWithValidation(String name, String projectId) {
        try {
            if (String.isBlank(name)) {
                throw new ServiceException('Status Name is required');
            }
            if (String.isBlank(projectId)) {
                throw new ServiceException('Project Id is required');
            }
            
            ProjectService.getProjectById(projectId);
            
            if (statusNameExists(projectId, name)) {
                throw new ServiceException('Status name already exists in this project');
            }
            
            return createStatus(name, projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error creating status: ' + ex.getMessage());
        }
    }

    public static Status__c getStatusByIdWithValidation(String statusId) {
        try {
            if (String.isBlank(statusId)) {
                throw new ServiceException('Status Id is required');
            }
            
            return getStatusById(statusId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving status by id: ' + ex.getMessage());
        }
    }

    public static Status__c getStatusByNameWithValidation(String statusName, String projectId) {
        try {
            if (String.isBlank(statusName)) {
                throw new ServiceException('Status Name is required');
            }
            if (String.isBlank(projectId)) {
                throw new ServiceException('Project Id is required');
            }
            
            return getStatusByName(statusName, projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving status by name: ' + ex.getMessage());
        }
    }

    public static List<Status__c> getStatusesByProjectWithValidation(String projectId) {
        try {
            List<Project__c> projects = [SELECT Id FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (projects.isEmpty()) {
                throw new ServiceException('Project not found');
            }
            
            return getStatusesByProject(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving project statuses: ' + ex.getMessage());
        }
    }

    public static List<Status__c> loadStatuses(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                throw new ServiceException('Project Id is required');
            }
            
            return getStatusesByProject(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading statuses: ' + ex.getMessage());
        }
    }
}

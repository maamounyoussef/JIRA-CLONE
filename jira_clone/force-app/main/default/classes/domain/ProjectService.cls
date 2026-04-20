/**
 * @description Service class for Project operations
 * Consolidates all usecases and repository methods for Project domain
 */
public with sharing class ProjectService {
    
    // Repository methods
    public static List<Project__c> getAllProjects() {
        return [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            ORDER BY Name ASC
        ];
    }
    
    public static Project__c getProjectByName(String projectName) {
        List<Project__c> projects = [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            WHERE Name = :projectName
            LIMIT 1
        ];
        
        if (projects.isEmpty()) {
            throw new ServiceException('Project not found: ' + projectName);
        }
        
        return projects[0];
    }
    
    public static Project__c getProjectById(String projectId) {
        List<Project__c> projects = [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        
        if (projects.isEmpty()) {
            throw new ServiceException('Project not found');
        }
        
        return projects[0];
    }
    
    public static Project__c createProject(String name) {
        try {
            Project__c project = new Project__c(
                Name = name
            );
            insert project;
            return project;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating project: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static Project__c createProjectWithValidation(String name) {
        try {
            if (String.isBlank(name)) {
                throw new ServiceException('name is required');
            }
            return createProject(name);
        } catch (Exception ex) {
            throw new ServiceException('Error creating project: ' + ex.getMessage());
        }
    }

    public static Project__c getProjectByNameWithValidation(String projectName) {
        try {
            return getProjectByName(projectName);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving project by name: ' + ex.getMessage());
        }
    }

    public static List<Project__c> loadProjects() {
        try {
            return getAllProjects();
        } catch (Exception ex) {
            throw new ServiceException('Error loading projects: ' + ex.getMessage());
        }
    }
}

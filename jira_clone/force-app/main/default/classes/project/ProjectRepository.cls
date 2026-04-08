/**
 * @description Repository class for Project-related database operations
 * Handles all SOQL queries and DML operations for project objects
 */
public with sharing class ProjectRepository {
    
    /**
     * @description Get all projects
     * @return List of all Project__c records
     */
    public static List<Project__c> getAllProjects() {
        return [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Get project by name
     * @param projectName - The name of the project
     * @return Project__c record if found
     * @throws ProjectException - If project not found
     */
    public static Project__c getProjectByName(String projectName) {
        List<Project__c> projects = [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            WHERE Name = :projectName
            LIMIT 1
        ];
        
        if (projects.isEmpty()) {
            throw new ProjectException('Project not found: ' + projectName);
        }
        
        return projects[0];
    }
    
    /**
     * @description Get project by Id
     * @param projectId - The Project__c record Id
     * @return Project__c record
     * @throws ProjectException - If project not found
     */
    public static Project__c getProjectById(String projectId) {
        List<Project__c> projects = [
            SELECT Id, Name, CreatedDate
            FROM Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        
        if (projects.isEmpty()) {
            throw new ProjectException('Project not found');
        }
        
        return projects[0];
    }
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c records
     */
    public static List<Status__c> getProjectStatuses(String projectId) {
        return [
            SELECT Id, Name, Project__c 
            FROM Status__c 
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
}

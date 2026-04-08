/**
 * @description Controller for managing Project operations
 * Handles project retrieval and listing
 * Uses ProjectService for business logic and ProjectRepository for data access
 */
public with sharing class ProjectController {
    
    /**
     * @description Load all projects
     * @return APIResponse containing List<Project__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadProjects() {
        try {
            List<Project__c> projects = ProjectService.loadProjects();
            return new APIResponse(true, 'Projects loaded successfully', projects);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading projects: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get project by name
     * @param projectName - The name of the project
     * @return APIResponse containing Project__c in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectByName(String projectName) {
        try {
            Project__c project = ProjectService.getProjectByName(projectName);
            return new APIResponse(true, 'Project retrieved successfully', project);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project__c record Id
     * @return APIResponse containing List of Status__c objects in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectStatuses(String projectId) {
        try {
            List<Status__c> statuses = ProjectService.getProjectStatuses(projectId);
            return new APIResponse(true, 'Project statuses retrieved successfully', statuses);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new project
     * @param name - The project name
     * @return APIResponse containing created Project__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createProject(String name) {
        try {
            Project__c project = ProjectService.createProject(name);
            return new APIResponse(true, 'Project created successfully', project);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project: ' + ex.getMessage());
        }
    }
}

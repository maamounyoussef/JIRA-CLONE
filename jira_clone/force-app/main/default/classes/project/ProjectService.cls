/**
 * @description Service class for Project business logic
 * Handles validation and orchestration of project operations using ProjectRepository
 */
public with sharing class ProjectService {
    
    /**
     * @description Load all projects
     * @return List of Project__c objects
     * @throws ProjectException - If error occurs
     */
    public static List<Project__c> loadProjects() {
        try {
            return ProjectRepository.getAllProjects();
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error loading projects: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get project by name
     * @param projectName - The name of the project
     * @return Project__c object
     * @throws ProjectException - If project not found or other errors occur
     */
    public static Project__c getProjectByName(String projectName) {
        try {
            validateNameParameter(projectName, 'Project Name');
            
            return ProjectRepository.getProjectByName(projectName);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error retrieving project by name: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c objects
     * @throws ProjectException - If error occurs
     */
    public static List<Status__c> getProjectStatuses(String projectId) {
        try {
            validateIdParameter(projectId, 'Project Id');
            
            return ProjectRepository.getProjectStatuses(projectId);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error retrieving project statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new project
     * @param name - The project name
     * @return The created Project__c record
     * @throws ProjectException - If validation fails or DML error occurs
     */
    public static Project__c createProject(String name) {
        try {
            validateNameParameter(name, 'Project Name');
            
            return ProjectRepository.createProject(name);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error creating project: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that a parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws ProjectException - If value is blank
     */
    private static void validateNameParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new ProjectException(paramName + ' is required');
        }
    }
    
    /**
     * @description Validate that an Id parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws ProjectException - If value is blank
     */
    private static void validateIdParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new ProjectException(paramName + ' is required');
        }
    }
}

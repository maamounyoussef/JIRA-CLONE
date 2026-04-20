/**
 * @description UseCase for loading all projects
 */
public class LoadProjectsUseCase {
    
    /**
     * @description Execute the use case to load all projects
     * @return List of Project__c records
     * @throws ProjectException - If error occurs
     */
    public static List<Project__c> execute() {
        try {
            return ProjectRepository.getAllProjects();
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error loading projects: ' + ex.getMessage());
        }
    }
}
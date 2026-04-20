/**
 * @description UseCase for getting a project by name
 */
public class GetProjectByNameUseCase {
    
    /**
     * @description Execute the use case to get a project by name
     * @param projectName - The name of the project
     * @return Project__c record
     * @throws ProjectException - If project not found or error occurs
     */
    public static Project__c execute(String projectName) {
        try {
            if (String.isBlank(projectName)) {
                throw new ProjectException('Project Name is required');
            }
            
            return ProjectRepository.getProjectByName(projectName);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error retrieving project by name: ' + ex.getMessage());
        }
    }
}
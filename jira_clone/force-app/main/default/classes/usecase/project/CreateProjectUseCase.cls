/**
 * @description UseCase for creating a new project
 */
public class CreateProjectUseCase {
    
    /**
     * @description Execute the use case to create a new project
     * @param name - The project name
     * @return The created Project__c record
     * @throws ProjectException - If validation fails or DML error occurs
     */
    public static Project__c execute(String name) {
        try {
            if (String.isBlank(name)) {
                throw new ProjectException('name is required');
            }
            return ProjectRepository.createProject(name);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error creating project: ' + ex.getMessage());
        }
    }
}
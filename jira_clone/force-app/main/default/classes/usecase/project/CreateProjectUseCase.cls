/**
 * @description UseCase for creating a new project
 */
public class CreateProjectUseCase {
    
    /**
     * @description Execute the use case to create a new project
     * @param dto - The ProjectCreateDto with project details
     * @return The created Project__c record
     * @throws ProjectException - If validation fails or DML error occurs
     */
    public static Project__c execute(ProjectCreateDto dto) {
        try {
            if (dto == null) {
                throw new ProjectException('ProjectCreateDto is required');
            }
            
            if (String.isBlank(dto.name)) {
                throw new ProjectException('Project Name is required');
            }
            
            return ProjectRepository.createProject(dto.name);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error creating project: ' + ex.getMessage());
        }
    }
}
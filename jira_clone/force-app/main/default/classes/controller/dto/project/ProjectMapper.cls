/**
 * @description Mapper class for Project domain operations
 * Converts between DTOs and domain objects (Project__c)
 */
public class ProjectMapper {
    
    /**
     * @description Map ProjectCreateDto to Project__c
     * @param dto The ProjectCreateDto
     * @return Project__c object
     */
    public static Project__c mapCreateDtoToProject(ProjectCreateDto dto) {
        if (dto == null) {
            return null;
        }
        
        Project__c project = new Project__c();
        project.Name = dto.name;
        return project;
    }
}
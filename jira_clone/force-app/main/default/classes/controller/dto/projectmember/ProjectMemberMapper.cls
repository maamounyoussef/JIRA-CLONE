/**
 * @description Mapper class for ProjectMember domain operations
 * Converts between DTOs and domain objects (ProjectMember__c)
 */
public class ProjectMemberMapper {
    
    /**
     * @description Map ProjectMemberCreateDto to parameters for repository
     * @param dto The ProjectMemberCreateDto
     * @return Map containing userId, projectId, and recordStatus
     */
    public static Map<String, String> mapCreateDtoToParams(ProjectMemberCreateDto dto) {
        if (dto == null) {
            return null;
        }
        
        Map<String, String> params = new Map<String, String>();
        params.put('userId', dto.userId);
        params.put('projectId', dto.projectId);
        params.put('recordStatus', dto.recordStatus);
        return params;
    }
}

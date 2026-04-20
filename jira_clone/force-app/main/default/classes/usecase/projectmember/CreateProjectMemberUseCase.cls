/**
 * @description UseCase for creating a new project member
 */
public class CreateProjectMemberUseCase {
    
    /**
     * @description Execute the use case to create a new project member
     * @param dto - The ProjectMemberCreateDto with project member details
     * @return The created ProjectMember__c record
     * @throws ProjectMemberException - If validation fails or DML error occurs
     */
    public static ProjectMember__c execute(ProjectMemberCreateDto dto) {
        try {
            if (!UserValidator.exists(dto.userId)) {
                throw new ProjectMemberException('User does not exist');
            }
            if (!ProjectValidator.exists(dto.projectId)) {
                throw new ProjectMemberException('Project does not exist');
            }
            return ProjectMemberRepository.createMember(dto.userId, dto.projectId, dto.recordStatus);
        } catch (ProjectMemberException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectMemberException('Error creating project member: ' + ex.getMessage());
        }
    }
}

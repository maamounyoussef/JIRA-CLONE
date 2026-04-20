/**
 * @description UseCase for creating a new project member
 */
public class CreateProjectMemberUseCase {
    
    /**
     * @description Execute the use case to create a new project member
     * @param userId - The user ID
     * @param projectId - The project ID
     * @param recordStatus - The record status
     * @return The created ProjectMember__c record
     * @throws ProjectMemberException - If validation fails or DML error occurs
     */
    public static ProjectMember__c execute(String userId, String projectId, String recordStatus) {
        try {
            if (!UserValidator.exists(userId)) {
                throw new ProjectMemberException('User does not exist');
            }
            if (!ProjectValidator.exists(projectId)) {
                throw new ProjectMemberException('Project does not exist');
            }
            return ProjectMemberRepository.createMember(userId, projectId, recordStatus);
        } catch (ProjectMemberException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectMemberException('Error creating project member: ' + ex.getMessage());
        }
    }
}

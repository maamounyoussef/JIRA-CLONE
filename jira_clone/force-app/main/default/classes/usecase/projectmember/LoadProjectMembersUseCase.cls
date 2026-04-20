/**
 * @description UseCase for loading project members for a given project
 */
public class LoadProjectMembersUseCase {
    
    /**
     * @description Execute the use case to load project members
     * @param projectId - The Project__c record Id
     * @return List of ProjectMember__c records
     * @throws ProjectMemberException - If error occurs
     */
    public static List<ProjectMember__c> execute(String projectId) {
        try {
            if (!ProjectValidator.exists(projectId)) {
                throw new ProjectMemberException('Project does not exist');
            }
            return ProjectMemberRepository.getMembersByProject(projectId);
        } catch (ProjectMemberException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectMemberException('Error loading project members: ' + ex.getMessage());
        }
    }
}

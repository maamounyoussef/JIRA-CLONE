/**
 * @description UseCase for getting statuses for a project
 */
public class GetProjectStatusesUseCase {
    
    /**
     * @description Execute the use case to get statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c records
     * @throws ProjectException - If error occurs
     */
    public static List<Status__c> execute(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                throw new ProjectException('Project Id is required');
            }
            
            return ProjectRepository.getProjectStatuses(projectId);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error retrieving project statuses: ' + ex.getMessage());
        }
    }
}
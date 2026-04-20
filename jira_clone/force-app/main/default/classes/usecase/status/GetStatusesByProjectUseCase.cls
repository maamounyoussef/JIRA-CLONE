/**
 * @description UseCase for getting statuses for a project
 * Validates project existence before retrieving statuses
 */
public with sharing class GetStatusesByProjectUseCase {
    
    /**
     * @description Execute the use case to get statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c records
     * @throws ProjectException - If project not found or error occurs
     */
    public static List<Status__c> execute(String projectId) {
        try {
            // Check if project exists
            if (!ProjectValidator.exists(projectId)) {
                throw new ProjectException('Project not found');
            }
            
            return StatusRepository.getStatusesByProject(projectId);
        } catch (ProjectException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ProjectException('Error retrieving project statuses: ' + ex.getMessage());
        }
    }
}

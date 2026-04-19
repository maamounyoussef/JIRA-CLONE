/**
 * @description Use Case for loading all statuses for a project
 * Handles validation and retrieval of statuses
 */
public with sharing class LoadStatusesUseCase {
    
    /**
     * @description Load all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c objects
     * @throws StatusException - If projectId is blank or other errors occur
     */
    public static List<Status__c> execute(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                throw new StatusException('Project Id is required');
            }
            
            return StatusRepository.getStatusesByProject(projectId);
        } catch (StatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new StatusException('Error loading statuses: ' + ex.getMessage());
        }
    }
}

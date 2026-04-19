/**
 * @description Use Case for retrieving a status by name and project
 * Handles validation and retrieval of status
 */
public with sharing class GetStatusByNameUseCase {
    
    /**
     * @description Get status by name and project
     * @param statusName - The name of the status
     * @param projectId - The Project__c record Id
     * @return Status__c object
     * @throws StatusException - If statusName or projectId is blank, or status not found
     */
    public static Status__c execute(String statusName, String projectId) {
        try {
            if (String.isBlank(statusName)) {
                throw new StatusException('Status Name is required');
            }
            if (String.isBlank(projectId)) {
                throw new StatusException('Project Id is required');
            }
            
            return StatusRepository.getStatusByName(statusName, projectId);
        } catch (StatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new StatusException('Error retrieving status by name: ' + ex.getMessage());
        }
    }
}

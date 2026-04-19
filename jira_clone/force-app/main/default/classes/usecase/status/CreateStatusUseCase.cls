/**
 * @description Use Case for creating a new status
 * Handles validation and creation of status records
 */
public with sharing class CreateStatusUseCase {
    
    /**
     * @description Create a new status
     * @param name - The status name
     * @param projectId - The Project__c record Id
     * @return The created Status__c record
     * @throws StatusException - If validation fails or DML error occurs
     */
    public static Status__c execute(String name, String projectId) {
        try {
            if (String.isBlank(name)) {
                throw new StatusException('Status Name is required');
            }
            if (String.isBlank(projectId)) {
                throw new StatusException('Project Id is required');
            }
            
            // Verify project exists
            ProjectRepository.getProjectById(projectId);
            
            // Ensure status name is unique within the project
            if (StatusRepository.statusNameExists(projectId, name)) {
                throw new StatusException('Status name already exists in this project');
            }
            
            return StatusRepository.createStatus(name, projectId);
        } catch (StatusException ex) {
            throw ex;
        } catch (ProjectException ex) {
            throw new StatusException('Invalid project: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new StatusException('Error creating status: ' + ex.getMessage());
        }
    }
}

/**
 * @description Use Case for loading all epics for a project
 * Handles validation and retrieval of epics
 */
public with sharing class GetEpicsByProjectUseCase {
    
    /**
     * @description Load all epics for a project
     * @param projectId - The Project__c record Id
     * @return List of Epic__c objects
     * @throws EpicException - If projectId is blank or other errors occur
     */
    public static List<Epic__c> execute(String projectId) {
        try {
            if (String.isBlank(projectId)) {
                throw new EpicException('projectId is required');
            }
            ProjectValidator.exists(projectId);
            
            return EpicRepository.findEpicsByProject(projectId);
        } catch (EpicException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new EpicException('Error loading epics: ' + ex.getMessage());
        }
    }
}
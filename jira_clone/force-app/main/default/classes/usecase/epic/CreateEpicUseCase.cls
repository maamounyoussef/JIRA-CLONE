/**
 * @description Use Case for creating a new epic
 * Handles validation and creation of epic records
 */
public with sharing class CreateEpicUseCase {
    
    /**
     * @description Create a new epic
     * @param epic - The Epic__c domain object containing creation data
     * @return The created Epic__c record
     * @throws EpicException - If validation fails or DML error occurs
     */
    public static Epic__c execute(Epic__c epic) {
        try {
            if (epic == null) {
                throw new EpicException('Epic is required');
            }
            if (String.isBlank(epic.Name)) {
                throw new EpicException('name is required');
            }
            if (String.isBlank(epic.Summary__c)) {
                throw new EpicException('summary is required');
            }
            if (String.isBlank(epic.Project__c)) {
                throw new EpicException('projectId is required');
            }
            
            ProjectValidator.exists(epic.Project__c);
            
            // Call repo method with domain object
            return EpicRepository.createEpic(epic);
        } catch (ProjectException pex) {
            throw new EpicException('Invalid project: ' + pex.getMessage());
        } catch (EpicException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new EpicException('Error creating epic: ' + ex.getMessage());
        }
    }
}
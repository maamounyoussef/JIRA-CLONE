/**
 * @description Use Case for updating an epic
 * Handles validation and updating of epic records
 */
public with sharing class UpdateEpicUseCase {
    
    /**
     * @description Update an epic
     * @param epic - The Epic__c domain object containing update data
     * @return The updated Epic__c record
     * @throws EpicException - If validation fails or DML error occurs
     */
    public static Epic__c execute(Epic__c epic) {
        try {
            if (epic == null) {
                throw new EpicException('Epic is required');
            }
            if (String.isBlank(epic.Id)) {
                throw new EpicException('epicId is required');
            }
            if (String.isBlank(epic.Name)) {
                throw new EpicException('name is required');
            }
            
            // Retrieve the existing epic
            Epic__c existing = GetEpicByIdUseCase.execute(epic.Id);
            if (existing == null) {
                throw new EpicException('Epic not found: ' + epic.Id);
            }
            
            // Call repo method with updated domain object
            return EpicRepository.updateEpic(epic);
        } catch (EpicException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new EpicException('Error updating epic: ' + ex.getMessage());
        }
    }
}
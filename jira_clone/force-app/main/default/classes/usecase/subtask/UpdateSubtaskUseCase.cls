/**
 * @description Use Case for updating a subtask
 * Handles validation and update of subtask records
 */
public with sharing class UpdateSubtaskUseCase {
    
    /**
     * @description Update a subtask
     * @param subtask - The Subtask__c domain object containing update data
     * @return The updated Subtask__c record
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static Subtask__c execute(Subtask__c subtask) {
        try {
            if (subtask == null) throw new SubtaskException('subtask is required');
            if (String.isBlank(subtask.Id)) throw new SubtaskException('subtaskId is required');
            if (String.isBlank(subtask.Summary__c)) throw new SubtaskException('summary is required');

            // Retrieve the subtask
            Subtask__c existing = SubtaskRepository.findSubtaskById(subtask.Id);
            if (existing == null) throw new SubtaskException('Subtask not found: ' + subtask.Id);

            // Call repo method with updated domain object
            return SubtaskRepository.updateSubtask(subtask);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error updating subtask: ' + ex.getMessage());
        }
    }
}

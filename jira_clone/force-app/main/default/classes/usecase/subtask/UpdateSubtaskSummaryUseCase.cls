/**
 * @description Use Case for updating a subtask summary
 * Handles validation and update of subtask summary
 */
public with sharing class UpdateSubtaskSummaryUseCase {
    
    /**
     * @description Update a subtask summary
     * @param subtaskId - The subtask ID
     * @param summary - The new summary
     * @return The updated Subtask__c record
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static Subtask__c execute(String subtaskId, String summary) {
        try {
            if (String.isBlank(subtaskId)) throw new SubtaskException('subtaskId is required');
            if (summary == null) throw new SubtaskException('summary field is required');

            Subtask__c s = SubtaskRepository.findSubtaskById(subtaskId);
            if (s == null) throw new SubtaskException('Subtask not found: ' + subtaskId);

            s.Summary__c = summary;
            return SubtaskRepository.updateSubtask(s);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error updating subtask: ' + ex.getMessage());
        }
    }
}

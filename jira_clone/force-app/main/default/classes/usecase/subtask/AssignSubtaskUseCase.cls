/**
 * @description Use Case for assigning a subtask to a member
 * Handles validation and assignment of subtask
 */
public with sharing class AssignSubtaskUseCase {
    
    /**
     * @description Assign a subtask to a member
     * @param subtaskId - The subtask ID
     * @param memberId - The member ID to assign to
     * @return The updated Subtask__c record
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static Subtask__c execute(String subtaskId, String memberId) {
        try {
            if (String.isBlank(subtaskId)) throw new SubtaskException('subtaskId is required');
            if (String.isBlank(memberId)) throw new SubtaskException('memberId is required');

            // Retrieve the subtask
            Subtask__c existing = SubtaskRepository.findSubtaskById(subtaskId);
            if (existing == null) throw new SubtaskException('Subtask not found: ' + subtaskId);

            // Update the assignee field
            existing.Assignee__c = memberId;

            // Call repo method with updated domain object
            return SubtaskRepository.updateSubtask(existing);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error assigning subtask: ' + ex.getMessage());
        }
    }
}

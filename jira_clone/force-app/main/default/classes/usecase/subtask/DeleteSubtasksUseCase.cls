/**
 * @description Use Case for deleting subtasks
 * Handles validation and deletion of subtask records
 */
public with sharing class DeleteSubtasksUseCase {
    
    /**
     * @description Delete subtasks
     * @param subtaskIds - List of subtask IDs to delete
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static void execute(List<String> subtaskIds) {
        try {
            if (subtaskIds == null || subtaskIds.isEmpty()) throw new SubtaskException('subtaskIds are required');
            SubtaskRepository.deleteSubtasksByIds(subtaskIds);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error deleting subtasks: ' + ex.getMessage());
        }
    }
}

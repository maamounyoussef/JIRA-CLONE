/**
 * @description Use Case for updating a subtask
 * Handles validation and update of subtask records
 */
public with sharing class UpdateSubtaskUseCase {
    
    /**
     * @description Update a subtask
     * @param dto - The SubtaskUpdateDto containing update data
     * @return The updated Subtask__c record
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static Subtask__c execute(SubtaskUpdateDto dto) {
        try {
            if (dto == null) throw new SubtaskException('dto is required');
            if (String.isBlank(dto.subtaskId)) throw new SubtaskException('subtaskId is required');

            // Retrieve the subtask
            Subtask__c existing = SubtaskRepository.findSubtaskById(dto.subtaskId);
            if (existing == null) throw new SubtaskException('Subtask not found: ' + dto.subtaskId);

            // Update the fields using mapper
            Subtask__c toUpdate = SubtaskMapper.mapUpdateSubtaskDtoToDomain(dto, existing);

            // Call repo method with updated domain object
            return SubtaskRepository.updateSubtask(toUpdate);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error updating subtask: ' + ex.getMessage());
        }
    }
}

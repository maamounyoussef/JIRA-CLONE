/**
 * @description Use Case for creating a new subtask
 * Handles validation and creation of subtask records
 */
public with sharing class CreateSubtaskUseCase {
    
    /**
     * @description Create a new subtask
     * @param dto - The SubtaskCreateDto containing creation data
     * @return The created Subtask__c record
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static Subtask__c execute(SubtaskCreateDto dto) {
        try {
            if (dto == null) throw new SubtaskException('SubtaskCreateDto is required');
            if (String.isBlank(dto.summary)) throw new SubtaskException('summary is required');
            if (String.isBlank(dto.ticketId)) throw new SubtaskException('ticketId is required');

            // Map DTO to domain object
            Subtask__c subtask = SubtaskMapper.mapCreateSubtaskDtoToDomain(dto);

            // Call repo method with domain object
            return SubtaskRepository.createSubtask(subtask);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error creating subtask: ' + ex.getMessage());
        }
    }
}

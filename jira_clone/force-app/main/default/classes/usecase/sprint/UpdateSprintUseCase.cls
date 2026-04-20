/**
 * @description UseCase for updating an existing Sprint
 * Pattern: Retrieve → Map DTO to Domain → Repository Update
 */
public class UpdateSprintUseCase {
    
    /**
     * @description Update sprint with DTO
     * @param dto SprintUpdateDto containing update values
     * @return Updated Sprint__c object
     * @throws SprintException if validation fails or sprint not found
     */
    public static Sprint__c execute(SprintUpdateDto dto) {
        try {
            if (dto == null) throw new SprintException('SprintUpdateDto is required');
            if (String.isBlank(dto.sprintId)) throw new SprintException('sprintId is required');
            
            // Retrieve the existing sprint
            Sprint__c existing = SprintRepository.findSprintById(dto.sprintId);
            if (existing == null) throw new SprintException('Sprint not found');
            
            // Update fields via mapper
            Sprint__c updated = SprintMapper.mapUpdateSprintDtoToDomain(dto, existing);
            
            // Call repository to persist
            return SprintRepository.updateSprint(updated);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error updating sprint: ' + ex.getMessage());
        }
    }
}

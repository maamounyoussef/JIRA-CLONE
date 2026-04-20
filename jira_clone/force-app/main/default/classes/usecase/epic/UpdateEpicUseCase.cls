/**
 * @description Use Case for updating an epic
 * Handles validation and updating of epic records
 */
public with sharing class UpdateEpicUseCase {
    
    /**
     * @description Update an epic
     * @param dto - The EpicUpdateDto containing update data
     * @return The updated Epic__c record
     * @throws EpicException - If validation fails or DML error occurs
     */
    public static Epic__c execute(EpicUpdateDto dto) {
        try {
            if (dto == null) {
                throw new EpicException('EpicUpdateDto is required');
            }
            if (String.isBlank(dto.epicId)) {
                throw new EpicException('epicId is required');
            }
            
            // Retrieve the existing epic
            Epic__c existing = GetEpicByIdUseCase.execute(dto.epicId);
            if (existing == null) {
                throw new EpicException('Epic not found: ' + dto.epicId);
            }
            
            // Update the fields using mapper
            Epic__c toUpdate = EpicMapper.mapUpdateEpicDtoToDomain(dto, existing);
            
            // Call repo method with updated domain object
            return EpicRepository.updateEpic(toUpdate);
        } catch (EpicException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new EpicException('Error updating epic: ' + ex.getMessage());
        }
    }
}
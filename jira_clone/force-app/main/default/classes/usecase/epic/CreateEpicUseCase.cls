/**
 * @description Use Case for creating a new epic
 * Handles validation and creation of epic records
 */
public with sharing class CreateEpicUseCase {
    
    /**
     * @description Create a new epic
     * @param dto - The EpicCreateDto containing creation data
     * @return The created Epic__c record
     * @throws EpicException - If validation fails or DML error occurs
     */
    public static Epic__c execute(EpicCreateDto dto) {
        try {
            if (dto == null) {
                throw new EpicException('EpicCreateDto is required');
            }
            if (String.isBlank(dto.name)) {
                throw new EpicException('name is required');
            }
            if (String.isBlank(dto.summary)) {
                throw new EpicException('summary is required');
            }
            if (String.isBlank(dto.projectId)) {
                throw new EpicException('projectId is required');
            }
            
            ProjectValidator.exists(dto.projectId);

            // Map DTO to domain object
            Epic__c epic = EpicMapper.mapCreateEpicDtoToDomain(dto);
            
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
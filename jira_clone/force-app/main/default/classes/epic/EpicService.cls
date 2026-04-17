/**
 * @description Service for Epic business logic
 * Performs validation and delegates to EpicRepository
 */
public with sharing class EpicService {

    /**
     * @description Get epics by project ID
     * @param projectId The Project ID
     * @return List of Epic__c records
     */
    public static List<Epic__c> getEpicsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new EpicException('projectId is required');
            return EpicRepository.findEpicsByProject(projectId);
        } catch (EpicException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new EpicException('Error loading epics: ' + ex.getMessage());
        }
    }

    /**
     * @description Get epic by ID
     * @param epicId The Epic ID
     * @return The Epic__c object
     */
    public static Epic__c getEpicById(String epicId) {
        try {
            if (String.isBlank(epicId)) throw new EpicException('epicId is required');
            return EpicRepository.findEpicById(epicId);
        } catch (Exception ex) {
            throw new EpicException('Error retrieving epic: ' + ex.getMessage());
        }
    }

    /**
     * @description Create epic from DTO
     * Pattern: Map DTO → Create Domain → Call Repository
     * @param dto EpicCreateDto containing creation values
     * @return Created Epic__c object
     */
    public static Epic__c createEpic(EpicCreateDto dto) {
        try {
            if (dto == null) throw new EpicException('EpicCreateDto is required');
            if (String.isBlank(dto.name)) throw new EpicException('name is required');
            if (String.isBlank(dto.summary)) throw new EpicException('summary is required');
            if (String.isBlank(dto.projectId)) throw new EpicException('projectId is required');

            // Validate project exists
            ProjectRepository.getProjectById(dto.projectId);

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

    /**
     * @description Update epic with DTO
     * Pattern: Retrieve → Update via Mapper → Call Repository
     * @param dto EpicUpdateDto containing update values
     * @return Updated Epic__c object
     */
    public static Epic__c updateEpic(EpicUpdateDto dto) {
        try {
            if (dto == null) throw new EpicException('EpicUpdateDto is required');
            if (String.isBlank(dto.epicId)) throw new EpicException('epicId is required');

            // Retrieve the right object
            Epic__c existing = getEpicById(dto.epicId);
            if (existing == null) throw new EpicException('Epic not found: ' + dto.epicId);

            // Update the right fields using mapper
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
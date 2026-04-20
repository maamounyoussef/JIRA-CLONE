/**
 * @description UseCase for creating a new Sprint
 * Pattern: Validate DTO → Map to Domain → Repository Insert
 */
public class CreateSprintUseCase {
    
    /**
     * @description Create a new sprint
     * @param dto SprintCreateDto containing creation values
     * @return Created Sprint__c object with Id populated
     * @throws SprintException if validation fails
     */
    public static Sprint__c execute(SprintCreateDto dto) {
        try {
            if (dto == null) throw new SprintException('SprintCreateDto is required');
            if (String.isBlank(dto.name)) throw new SprintException('name is required');
            if (String.isBlank(dto.projectId)) throw new SprintException('projectId is required');
            
            // Ensure project exists
            ProjectRepository.getProjectById(dto.projectId);
            
            // Map DTO to domain object
            Sprint__c sprint = SprintMapper.mapCreateSprintDtoToDomain(dto);
            
            // Call repository to persist
            return SprintRepository.createSprint(sprint);
        } catch (ProjectException pex) {
            throw new SprintException('Invalid project: ' + pex.getMessage());
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error creating sprint: ' + ex.getMessage());
        }
    }
}

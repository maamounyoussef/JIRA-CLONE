/**
 * @description Service layer for Sprint business logic
 * Follows pattern: Retrieve → Update Fields → Call Repository
 */
public with sharing class SprintService {

    /**
     * @description Get sprint by Id
     * @param sprintId The sprint record Id
     * @return Sprint__c object
     */
    public static Sprint__c getSprintById(String sprintId) {
        try {
            if (String.isBlank(sprintId)) throw new SprintException('sprintId is required');
            Sprint__c sprint = SprintRepository.findSprintById(sprintId);
            if (sprint == null) throw new SprintException('Sprint not found');
            return sprint;
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error retrieving sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Load sprints for a project
     * @param projectId The project Id
     * @return List of Sprint__c objects
     */
    public static List<Sprint__c> loadSprints(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new SprintException('projectId is required');
            // Ensure project exists
            ProjectRepository.getProjectById(projectId);
            return SprintRepository.getSprintsByProject(projectId);
        } catch (ProjectException pex) {
            throw new SprintException('Invalid project: ' + pex.getMessage());
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error loading sprints: ' + ex.getMessage());
        }
    }

    /**
     * @description Create a new sprint
     * Pattern: Map DTO → Create Domain → Call Repository
     * @param dto SprintCreateDto containing creation values
     * @return Created Sprint__c object
     */
    public static Sprint__c createSprint(SprintCreateDto dto) {
        try {
            if (dto == null) throw new SprintException('SprintCreateDto is required');
            if (String.isBlank(dto.name)) throw new SprintException('name is required');
            if (String.isBlank(dto.projectId)) throw new SprintException('projectId is required');
            
            // Ensure project exists
            ProjectRepository.getProjectById(dto.projectId);
            
            // Map DTO to domain object
            Sprint__c sprint = SprintMapper.mapCreateSprintDtoToDomain(dto);
            
            return SprintRepository.createSprint(sprint);
        } catch (ProjectException pex) {
            throw new SprintException('Invalid project: ' + pex.getMessage());
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error creating sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Update sprint with DTO
     * Pattern: Retrieve → Update via Mapper → Call Repository
     * @param dto SprintUpdateDto containing update values
     * @return Updated Sprint__c object
     */
    public static Sprint__c updateSprint(SprintUpdateDto dto) {
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

    /**
     * @description Update sprint name
     * Pattern: Retrieve → Update → Call Repository
     * @param sprintId The sprint Id
     * @param name New sprint name
     * @return Updated Sprint__c object
     */
    public static Sprint__c updateSprintName(String sprintId, String name) {
        try {
            if (String.isBlank(sprintId)) throw new SprintException('sprintId is required');
            if (String.isBlank(name)) throw new SprintException('name is required');
            
            // Retrieve
            Sprint__c sprint = SprintRepository.findSprintById(sprintId);
            if (sprint == null) throw new SprintException('Sprint not found');
            
            // Update
            sprint.Name = name;
            
            // Call repo
            return SprintRepository.updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error updating sprint name: ' + ex.getMessage());
        }
    }

    /**
     * @description Complete sprint
     * Pattern: Retrieve → Update Status → Call Repository
     * @param sprintId The sprint Id
     */
    public static void completeSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) throw new SprintException('sprintId is required');
            
            // Retrieve
            Sprint__c sprint = SprintRepository.findSprintById(sprintId);
            if (sprint == null) throw new SprintException('Sprint not found');
            
            // Update
            sprint.RecordStatus__c = 'completed';
            
            // Call repo
            SprintRepository.updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error completing sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Delete sprint
     * @param sprintId The sprint Id
     */
    public static void deleteSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) throw new SprintException('sprintId is required');
            SprintRepository.deleteSprintById(sprintId);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error deleting sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Start sprint
     * Pattern: Retrieve → Update Status → Call Repository
     * @param sprintId The sprint Id
     */
    public static void startSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) throw new SprintException('sprintId is required');
            
            // Retrieve
            Sprint__c sprint = SprintRepository.findSprintById(sprintId);
            if (sprint == null) throw new SprintException('Sprint not found');
            
            // Update
            sprint.RecordStatus__c = 'in_progress';
            
            // Call repo
            SprintRepository.updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error starting sprint: ' + ex.getMessage());
        }
    }
}
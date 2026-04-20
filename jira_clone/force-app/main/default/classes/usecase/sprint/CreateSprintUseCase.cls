/**
 * @description UseCase for creating a new Sprint
 * Pattern: Validate Domain → Repository Insert
 */
public class CreateSprintUseCase {
    
    /**
     * @description Create a new sprint
     * @param sprint Sprint__c domain object containing creation values
     * @return Created Sprint__c object with Id populated
     * @throws SprintException if validation fails
     */
    public static Sprint__c execute(Sprint__c sprint) {
        try {
            if (sprint == null) {
                throw new SprintException('Sprint is required');
            }
            if (String.isBlank(sprint.Name)) {
                throw new SprintException('name is required');
            }
            if (String.isBlank(sprint.Project__c)) {
                throw new SprintException('projectId is required');
            }
            
            // Check project if exist using domain validator
            ProjectRepository.getProjectById(sprint.Project__c);
            
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

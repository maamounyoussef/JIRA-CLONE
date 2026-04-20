/**
 * @description UseCase for updating an existing Sprint
 * Pattern: Retrieve → Repository Update
 */
public class UpdateSprintUseCase {
    
    /**
     * @description Update sprint with domain object
     * @param sprint Sprint__c domain object containing update values
     * @return Updated Sprint__c object
     * @throws SprintException if validation fails or sprint not found
     */
    public static Sprint__c execute(Sprint__c sprint) {
        try {
            if (sprint == null) {
                throw new SprintException('Sprint is required');
            }
            if (String.isBlank(sprint.Id)) {
                throw new SprintException('sprintId is required');
            }
            if (String.isBlank(sprint.Name)) {
                throw new SprintException('name is required');
            }
            
            // Retrieve the existing sprint
            Sprint__c existing = SprintRepository.findSprintById(sprint.Id);
            if (existing == null) throw new SprintException('Sprint not found');
            
            // Call repository to persist
            return SprintRepository.updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error updating sprint: ' + ex.getMessage());
        }
    }
}

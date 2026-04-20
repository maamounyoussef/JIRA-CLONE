/**
 * @description UseCase for completing a Sprint
 * Pattern: Retrieve → Update Status to 'completed' → Repository Update
 */
public class CompleteSprintUseCase {
    
    /**
     * @description Complete sprint
     * @param sprintId The sprint Id
     * @throws SprintException if sprint not found
     */
    public static void execute(String sprintId) {
        try {

            // Todo validate sprint if exist using validator
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
}

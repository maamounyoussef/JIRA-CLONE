/**
 * @description UseCase for starting a Sprint
 * Pattern: Retrieve → Update Status to 'in_progress' → Repository Update
 */
public class StartSprintUseCase {
    
    /**
     * @description Start sprint
     * @param sprintId The sprint Id
     * @throws SprintException if sprint not found
     */
    public static void execute(String sprintId) {
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

/**
 * @description UseCase for deleting a Sprint
 */
public class DeleteSprintUseCase {
    
    /**
     * @description Delete sprint
     * @param sprintId The sprint Id
     * @throws SprintException if deletion fails
     */
    public static void execute(String sprintId) {
        try {
            if (String.isBlank(sprintId)) throw new SprintException('sprintId is required');
            SprintRepository.deleteSprintById(sprintId);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error deleting sprint: ' + ex.getMessage());
        }
    }
}

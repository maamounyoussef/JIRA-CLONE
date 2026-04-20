/**
 * @description UseCase for retrieving a Sprint by Id
 */
public class GetSprintByIdUseCase {
    
    /**
     * @description Get sprint by Id
     * @param sprintId The sprint record Id
     * @return Sprint__c object
     * @throws SprintException if sprint not found
     */
    public static Sprint__c execute(String sprintId) {
        try {
            Sprint__c sprint = SprintRepository.findSprintById(sprintId);
            if (sprint == null) throw new SprintException('Sprint not found');
            return sprint;
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SprintException('Error retrieving sprint: ' + ex.getMessage());
        }
    }
}

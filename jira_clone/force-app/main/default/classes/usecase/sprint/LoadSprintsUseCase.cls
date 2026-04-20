/**
 * @description UseCase for loading all Sprints for a project
 */
public class LoadSprintsUseCase {
    
    /**
     * @description Load sprints for a project
     * @param projectId The project Id
     * @return List of Sprint__c objects for the project
     * @throws SprintException if project not found
     */
    public static List<Sprint__c> execute(String projectId) {
        try {
            // Todo chek of project  exsit using project validator
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
}

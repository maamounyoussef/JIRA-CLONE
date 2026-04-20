/**
 * @description UseCase for loading all TicketTypes for a project
 */
public class LoadTicketTypesUseCase {
    
    /**
     * @description Load ticket types for a project
     * @param projectId The project Id
     * @return List of TicketType__c objects for the project
     * @throws TicketTypeException if project not found
     */
    public static List<TicketType__c> execute(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new TicketTypeException('projectId is required');
            // Ensure project exists
            ProjectRepository.getProjectById(projectId);
            return TicketTypeRepository.getTicketTypesByProject(projectId);
        } catch (ProjectException pex) {
            throw new TicketTypeException('Invalid project: ' + pex.getMessage());
        } catch (TicketTypeException ttex) {
            throw ttex;
        } catch (Exception ex) {
            throw new TicketTypeException('Error loading ticket types: ' + ex.getMessage());
        }
    }
}

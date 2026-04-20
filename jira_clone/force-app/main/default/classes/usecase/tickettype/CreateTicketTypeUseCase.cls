/**
 * @description UseCase for creating a new TicketType
 * Pattern: Validate Fields → Repository Insert
 */
public class CreateTicketTypeUseCase {
    
    /**
     * @description Create a new ticket type
     * @param name The ticket type name
     * @param description The ticket type description
     * @param iconUrl The ticket type icon URL
     * @param workflowId The workflow ID
     * @param projectId The project ID
     * @return Created TicketType__c object with Id populated
     * @throws TicketTypeException if validation fails
     */
    public static TicketType__c execute(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            if (String.isBlank(name)) throw new TicketTypeException('name is required');
            if (String.isBlank(workflowId)) throw new TicketTypeException('workflowId is required');
            if (String.isBlank(projectId)) throw new TicketTypeException('projectId is required');
            
            // Ensure project exists
            ProjectRepository.getProjectById(projectId);
            
            // Call repository to persist
            return TicketTypeRepository.createTicketType(
                name,
                description,
                iconUrl,
                workflowId,
                projectId
            );
        } catch (ProjectException pex) {
            throw new TicketTypeException('Invalid project: ' + pex.getMessage());
        } catch (TicketTypeException ttex) {
            throw ttex;
        } catch (Exception ex) {
            throw new TicketTypeException('Error creating ticket type: ' + ex.getMessage());
        }
    }
}

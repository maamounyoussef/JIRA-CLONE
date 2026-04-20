/**
 * @description UseCase for creating a new TicketType
 * Pattern: Validate DTO → Map to Domain → Repository Insert
 */
public class CreateTicketTypeUseCase {
    
    /**
     * @description Create a new ticket type
     * @param dto TicketTypeCreateDto containing creation values
     * @return Created TicketType__c object with Id populated
     * @throws TicketTypeException if validation fails
     */
    public static TicketType__c execute(TicketTypeCreateDto dto) {
        try {
            if (dto == null) throw new TicketTypeException('TicketTypeCreateDto is required');
            if (String.isBlank(dto.name)) throw new TicketTypeException('name is required');
            if (String.isBlank(dto.workflowId)) throw new TicketTypeException('workflowId is required');
            if (String.isBlank(dto.projectId)) throw new TicketTypeException('projectId is required');
            
            // Ensure project exists
            ProjectRepository.getProjectById(dto.projectId);
            
            // Call repository to persist
            return TicketTypeRepository.createTicketType(
                dto.name,
                dto.description,
                dto.iconUrl,
                dto.workflowId,
                dto.projectId
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

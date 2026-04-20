/**
 * @description Mapper for TicketType__c domain object
 * Handles conversion between DTOs and domain objects
 */
public class TicketTypeMapper {
    
    /**
     * @description Maps TicketTypeCreateDto to TicketType__c domain object
     * @param dto - The TicketTypeCreateDto with data
     * @return TicketType__c domain object
     */
    public static TicketType__c mapCreateDtoToDomainObject(TicketTypeCreateDto dto) {
        return new TicketType__c(
            Name = dto.name,
            Description__c = dto.description,
            IconUrl__c = dto.iconUrl,
            Workflow__c = dto.workflowId,
            Project__c = dto.projectId
        );
    }

    /**
     * @description Maps TicketType__c domain object to a Map for API responses
     * @param ticketType - The TicketType__c domain object
     * @return Map representation of the ticket type
     */
    public static Map<String, Object> toDomainObjectToMap(TicketType__c ticketType) {
        return new Map<String, Object>{
            'Id' => ticketType.Id,
            'Name' => ticketType.Name,
            'Description__c' => ticketType.Description__c,
            'IconUrl__c' => ticketType.IconUrl__c,
            'Workflow__c' => ticketType.Workflow__c,
            'Project__c' => ticketType.Project__c,
            'CreatedDate' => ticketType.CreatedDate
        };
    }
}

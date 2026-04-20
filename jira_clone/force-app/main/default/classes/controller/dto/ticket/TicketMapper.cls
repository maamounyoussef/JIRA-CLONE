/**
 * @description Mapper for converting Ticket DTOs to Ticket__c domain objects
 * Function naming convention: map<FunctionGoal><DomainName>DtoToDomain
 */
public with sharing class TicketMapper {

    /**
     * @description Maps TicketCreateDto to new Ticket__c object
     * @param dto The DTO containing creation values
     * @return New Ticket__c object
     */
    public static Ticket__c mapCreateTicketDtoToDomain(TicketCreateDto dto) {
        if (dto == null) throw new TicketException('dto is required');

        Ticket__c ticket = new Ticket__c();
        
        if (String.isNotBlank(dto.name)) {
            ticket.Name = dto.name;
        }
        if (String.isNotBlank(dto.summary)) {
            ticket.Summary__c = dto.summary;
        }
        if (String.isNotBlank(dto.description)) {
            ticket.Description__c = dto.description;
        }
        if (dto.storyPoint != null) {
            ticket.StoryPoint__c = dto.storyPoint;
        }
        if (String.isNotBlank(dto.ticketTypeId)) {
            ticket.Ticket_Type__c = dto.ticketTypeId;
        }
        if (String.isNotBlank(dto.assignedToId)) {
            ticket.AssignedTo__c = dto.assignedToId;
        }
        if (String.isNotBlank(dto.currentStateId)) {
            ticket.CurrentState__c = dto.currentStateId;
        }
        if (String.isNotBlank(dto.epicId)) {
            ticket.Epic__c = dto.epicId;
        }
        if (String.isNotBlank(dto.sprintId)) {
            ticket.Sprint__c = dto.sprintId;
        }
        if (String.isNotBlank(dto.priority)) {
            ticket.Priority__c = dto.priority;
        }

        return ticket;
    }

    /**
     * @description Maps TicketUpdateDto to existing Ticket__c object
     * Only updates non-blank fields to preserve existing values
     * @param dto The DTO containing update values
     * @param existing The existing Ticket__c object to update
     * @return Updated Ticket__c object
     */
    public static Ticket__c mapUpdateTicketDtoToDomain(TicketUpdateDto dto, Ticket__c existing) {
        if (dto == null) throw new TicketException('dto is required');
        if (existing == null) throw new TicketException('existing ticket is required');

        if (String.isNotBlank(dto.summary)) {
            existing.Summary__c = dto.summary;
        }
        if (String.isNotBlank(dto.description)) {
            existing.Description__c = dto.description;
        }
        if (dto.storyPoint != null) {
            existing.StoryPoint__c = dto.storyPoint;
        }
        if (String.isNotBlank(dto.priority)) {
            existing.Priority__c = dto.priority;
        }
        if (String.isNotBlank(dto.assignedToId)) {
            existing.AssignedTo__c = dto.assignedToId;
        }
        if (String.isNotBlank(dto.currentStateId)) {
            existing.CurrentState__c = dto.currentStateId;
        }

        return existing;
    }
}

/**
 * @description UseCase for creating a ticket from DTO
 * Validates required fields and references before creating
 */
public with sharing class CreateTicketUseCase {
    
    public static Ticket__c execute(TicketCreateDto dto) {
        try {
            if (dto == null) throw new TicketException('TicketCreateDto is required');
            if (String.isBlank(dto.ticketTypeId)) throw new TicketException('ticket_type is required');
            if (String.isBlank(dto.name)) throw new TicketException('name is required');
            if (String.isBlank(dto.currentStateId)) throw new TicketException('current_state is required');

            // Validate ticket type exists
            TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Id = :dto.ticketTypeId LIMIT 1];
            if (tt == null) throw new TicketException('Invalid ticket type');

            // Validate status exists
            Status__c status = [SELECT Id FROM Status__c WHERE Id = :dto.currentStateId LIMIT 1];
            if (status == null) throw new TicketException('Invalid status');

            // Map DTO to domain object
            Ticket__c ticket = TicketMapper.mapCreateTicketDtoToDomain(dto);

            // Call repo method with domain object
            return TicketRepository.createTicket(ticket);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error creating ticket: ' + ex.getMessage());
        }
    }
}

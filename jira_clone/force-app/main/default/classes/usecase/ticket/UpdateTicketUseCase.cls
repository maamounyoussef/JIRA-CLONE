/**
 * @description UseCase for updating a ticket with DTO
 * Pattern: Retrieve → Update via Mapper → Call Repository
 */
public with sharing class UpdateTicketUseCase {
    
    public static Ticket__c execute(TicketUpdateDto dto) {
        try {
            if (dto == null) throw new TicketException('dto is required');
            if (String.isBlank(dto.ticketId)) throw new TicketException('ticketId is required');

            // Retrieve the right object
            Ticket__c existing = GetTicketByIdUseCase.execute(dto.ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + dto.ticketId);

            // Update the right fields using mapper
            Ticket__c toUpdate = TicketMapper.mapUpdateTicketDtoToDomain(dto, existing);

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(toUpdate);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket: ' + ex.getMessage());
        }
    }
}

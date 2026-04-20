/**
 * @description UseCase for deleting tickets
 */
public with sharing class DeleteTicketsUseCase {
    
    public static void execute(List<String> ticketIds) {
        try {
            if (ticketIds == null || ticketIds.isEmpty()) throw new TicketException('ticketIds are required');
            TicketRepository.deleteTicketsByIds(ticketIds);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error deleting tickets: ' + ex.getMessage());
        }
    }
}

/**
 * @description UseCase for loading subtasks for a ticket
 */
public with sharing class LoadSubtasksByTicketUseCase {
    
    public static List<Subtask__c> execute(String ticketId) {
        try {
            if (String.isBlank(ticketId)) throw new SubtaskException('ticketId is required');
            return SubtaskRepository.findSubtasksByTicket(ticketId);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error loading subtasks: ' + ex.getMessage());
        }
    }
}

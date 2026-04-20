/**
 * @description Use Case for creating a new subtask
 * Handles validation and creation of subtask records
 */
public with sharing class CreateSubtaskUseCase {
    
    /**
     * @description Create a new subtask
     * @param subtask - The Subtask__c domain object containing creation data
     * @return The created Subtask__c record
     * @throws SubtaskException - If validation fails or DML error occurs
     */
    public static Subtask__c execute(Subtask__c subtask) {
        try {
            if (subtask == null) throw new SubtaskException('Subtask is required');
            if (String.isBlank(subtask.Summary__c)) throw new SubtaskException('summary is required');
            if (String.isBlank(subtask.Ticket__c)) throw new SubtaskException('ticketId is required');

            // Call repo method with domain object
            return SubtaskRepository.createSubtask(subtask);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error creating subtask: ' + ex.getMessage());
        }
    }
}

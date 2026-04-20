/**
 * @description Repository for Subtask__c database operations
 */
public with sharing class SubtaskRepository {

    public static List<Subtask__c> findSubtasksByTicket(String ticketId) {
        if (String.isBlank(ticketId)) return new List<Subtask__c>();
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, StartDate__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Ticket__c = :ticketId AND RecordStatus__c != 'delete'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw new SubtaskException('Error querying subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c findSubtaskById(String subtaskId) {
        if (String.isBlank(subtaskId)) return null;
        try {
            List<Subtask__c> res = [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Id = :subtaskId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new SubtaskException('Error retrieving subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c createSubtask(Subtask__c s) {
        if (s == null) throw new SubtaskException('subtask is required');
        try {
            insert s;
            return s;
        } catch (DmlException dex) {
            throw new SubtaskException('DML error creating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new SubtaskException('Error creating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtask(Subtask__c s) {
        if (s == null) throw new SubtaskException('subtask is required');
        if (s.Id == null) throw new SubtaskException('subtask Id is required');
        try {
            update s;
            return s;
        } catch (DmlException dex) {
            throw new SubtaskException('DML error updating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new SubtaskException('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasksByIds(List<String> ids) {
        if (ids == null || ids.isEmpty()) return;
        try {
            List<Subtask__c> found = [SELECT Id, RecordStatus__c FROM Subtask__c WHERE Id IN :ids];
            if (!found.isEmpty()) {
                for (Subtask__c s : found) s.RecordStatus__c = 'delete';
                update found;
            }
        } catch (DmlException dex) {
            throw new SubtaskException('DML error deleting subtasks: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new SubtaskException('Error deleting subtasks: ' + ex.getMessage());
        }
    }
}
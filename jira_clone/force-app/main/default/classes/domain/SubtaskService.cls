/**
 * @description Service class for Subtask operations
 * Consolidates all usecases and repository methods for Subtask domain
 */
public with sharing class SubtaskService {
    
    // Repository methods
    public static List<Subtask__c> findSubtasksByTicket(String ticketId) {
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, StartDate__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Ticket__c = :ticketId AND RecordStatus__c != 'delete'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw new Exception('Error querying subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c findSubtaskById(String subtaskId) {
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
            throw new Exception('Error retrieving subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c createSubtask(Subtask__c s) {
        try {
            insert s;
            return s;
        } catch (DmlException dex) {
            throw new Exception('DML error creating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error creating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtask(Subtask__c s) {
        try {
            update s;
            return s;
        } catch (DmlException dex) {
            throw new Exception('DML error updating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasksByIds(List<String> ids) {
        try {
            List<Subtask__c> found = [SELECT Id, RecordStatus__c FROM Subtask__c WHERE Id IN :ids];
            if (!found.isEmpty()) {
                for (Subtask__c s : found) s.RecordStatus__c = 'delete';
                update found;
            }
        } catch (DmlException dex) {
            throw new Exception('DML error deleting subtasks: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error deleting subtasks: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static Subtask__c assignSubtask(String subtaskId, String memberId) {
        try {
            if (String.isBlank(subtaskId)) throw new Exception('subtaskId is required');
            if (String.isBlank(memberId)) throw new Exception('memberId is required');

            Subtask__c existing = findSubtaskById(subtaskId);
            if (existing == null) throw new Exception('Subtask not found: ' + subtaskId);

            existing.Assignee__c = memberId;
            return updateSubtask(existing);
        } catch (Exception ex) {
            throw new Exception('Error assigning subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c createSubtaskWithValidation(Subtask__c subtask) {
        try {
            if (subtask == null) throw new Exception('Subtask is required');
            if (String.isBlank(subtask.Summary__c)) throw new Exception('summary is required');
            if (String.isBlank(subtask.Ticket__c)) throw new Exception('ticketId is required');

            return createSubtask(subtask);
        } catch (Exception ex) {
            throw new Exception('Error creating subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasks(List<String> subtaskIds) {
        try {
            if (subtaskIds == null || subtaskIds.isEmpty()) throw new Exception('subtaskIds are required');
            deleteSubtasksByIds(subtaskIds);
        } catch (Exception ex) {
            throw new Exception('Error deleting subtasks: ' + ex.getMessage());
        }
    }

    public static List<Subtask__c> getSubtasksByTicket(String ticketId) {
        try {
            if (String.isBlank(ticketId)) throw new Exception('ticketId is required');
            return findSubtasksByTicket(ticketId);
        } catch (Exception ex) {
            throw new Exception('Error loading subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskSummary(String subtaskId, String summary) {
        try {
            if (String.isBlank(subtaskId)) throw new Exception('subtaskId is required');
            if (summary == null) throw new Exception('summary field is required');

            Subtask__c s = findSubtaskById(subtaskId);
            if (s == null) throw new Exception('Subtask not found: ' + subtaskId);

            s.Summary__c = summary;
            return updateSubtask(s);
        } catch (Exception ex) {
            throw new Exception('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskWithValidation(Subtask__c subtask) {
        try {
            if (subtask == null) throw new Exception('subtask is required');
            if (String.isBlank(subtask.Id)) throw new Exception('subtaskId is required');
            if (String.isBlank(subtask.Summary__c)) throw new Exception('summary is required');

            Subtask__c existing = findSubtaskById(subtask.Id);
            if (existing == null) throw new Exception('Subtask not found: ' + subtask.Id);

            return updateSubtask(subtask);
        } catch (Exception ex) {
            throw new Exception('Error updating subtask: ' + ex.getMessage());
        }
    }
}

/**
 * @description Service class for Sprint operations
 * Consolidates all usecases and repository methods for Sprint domain
 */
public with sharing class SprintService {

    public static Sprint__c findSprintById(String sprintId) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c, TotalStoryPoint__c, TotalEndedStoryPoint__c, MaxScore__c FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        } catch (Exception ex) {
            throw new ServiceException('Error finding sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c createSprint(Sprint__c sprint) {
        try {
            sprint.TotalStoryPoint__c = 0;
            sprint.TotalEndedStoryPoint__c = 0;
            sprint.MaxScore__c = '000000';
            sprint.Name = NameSequenceService.nextSprintName(sprint.Project__c);
            insert sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c updateSprint(Sprint__c sprint) {
        try {
            update sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating sprint: ' + ex.getMessage());
        }
    }

    public static void completeSprint(Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireSprintIsCompletable(sprint);
            sprint.RecordStatus__c = 'completed';
            updateSprint(sprint);
        } catch (Exception ex) {
            throw new ServiceException('Error completing sprint: ' + ex.getMessage());
        }
    }

    public static void deleteSprint(Sprint__c sprint) {
        try {
            sprint.RecordStatus__c = 'delete';
            updateSprint(sprint);
            TicketService.clearSprintFromTickets(sprint.Id);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting sprint: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> loadUncompleteSprintsByProject(Project__c project) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c, TotalStoryPoint__c, TotalEndedStoryPoint__C, MaxScore__c FROM Sprint__c WHERE Project__c = :project.Id AND RecordStatus__c != 'completed' AND RecordStatus__c != 'delete'];
        } catch (Exception ex) {
            throw new ServiceException('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static Sprint__c loadActiveSprint(String projectId) {
        try {
            List<Sprint__c> sprints = [
                SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c, TotalStoryPoint__c, TotalEndedStoryPoint__c, MaxScore__c
                FROM Sprint__c
                WHERE Project__c = :projectId AND RecordStatus__c = 'in_progress'
                LIMIT 1
            ];
            return sprints.isEmpty() ? null : sprints[0];
        } catch (Exception ex) {
            throw new ServiceException('Error loading active sprint: ' + ex.getMessage());
        }
    }

    public static void startSprint(Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireSprintIsStartable(sprint);
            List<Sprint__c> activeSprint = [
                SELECT Id FROM Sprint__c
                WHERE Project__c = :sprint.Project__c AND RecordStatus__c = 'in_progress'
                LIMIT 1
            ];
            DomainCompleteValidator.requireNoActiveSprintInProject(activeSprint);

            sprint.RecordStatus__c = 'in_progress';
            updateSprint(sprint);
        } catch (Exception ex) {
            throw new ServiceException('Error starting sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c increaseTotalAndEndedStoryPoint(String sprintId, Decimal totalStoryPoints, Decimal totalEndedStoryPoints)
    {
        try {
            if (String.isBlank(sprintId) || totalStoryPoints == null || totalEndedStoryPoints == null) return null;
            Sprint__c sprint = findSprintById(sprintId);
            sprint.TotalStoryPoint__c += totalStoryPoints;
            sprint.TotalEndedStoryPoint__c += totalEndedStoryPoints;
            updateSprint(sprint);
            return sprint;
        } catch (Exception ex) {
            throw new ServiceException('Error updating  story point: ' + ex.getMessage());
        }
    }

    public static Sprint__c decreaseTotalAndEndedStoryPoints(String sprintId, Decimal totalStoryPoints, Decimal totalEndedStoryPoints)
    {
        try {
            if (String.isBlank(sprintId) || totalStoryPoints == null || totalEndedStoryPoints == null) return null;
            Sprint__c sprint = findSprintById(sprintId);
            sprint.TotalStoryPoint__c -= totalStoryPoints;
            sprint.TotalEndedStoryPoint__c -= totalEndedStoryPoints;
            updateSprint(sprint);
            return sprint;
        } catch (Exception ex) {
            throw new ServiceException('Error updating  story point: ' + ex.getMessage());
        }
    }
}

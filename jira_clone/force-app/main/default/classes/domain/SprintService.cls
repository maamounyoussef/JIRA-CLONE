/**
 * @description Service class for Sprint operations
 * Consolidates all usecases and repository methods for Sprint domain
 */
public with sharing class SprintService {

    // Repository methods
    public static Sprint__c findSprintById(String sprintId) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        } catch (Exception ex) {
            throw new ServiceException('Error finding sprint: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> getSprintsByProject(String projectId) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Project__c = :projectId];
        } catch (Exception ex) {
            throw new ServiceException('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> getFuturedSprintsByProject(String projectId) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Project__c = :projectId AND RecordStatus__c = 'future'];
        } catch (Exception ex) {
            throw new ServiceException('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static Sprint__c createSprint(Sprint__c sprint) {
        try {
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

    public static void deleteSprintById(String sprintId) {
        if (String.isBlank(sprintId)) return;
        try {
            delete new Sprint__c(Id = sprintId);
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting sprint: ' + ex.getMessage());
        }
    }

    // Use case methods
    public static void completeSprint(String sprintId) {
        try {
            Sprint__c sprint = DomainCompleteValidator.requireSprintExists(sprintId);
            // DomainCompleteValidator.requireSprintIsCompletable(sprint);

            sprint.RecordStatus__c = 'completed';
            updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new ServiceException('Error completing sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c createSprintWithValidation(Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireProjectExists(sprint.Project__c);
            return createSprint(sprint);
        } catch (Exception ex) {
            throw new ServiceException('Error creating sprint: ' + ex.getMessage());
        }
    }

    public static void deleteSprint(String sprintId) {
        try {
            deleteSprintById(sprintId);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new ServiceException('Error deleting sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c getSprintById(String sprintId) {
        try {
            Sprint__c sprint = findSprintById(sprintId);
            if (sprint == null) throw new ServiceException('Sprint not found');
            return sprint;
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving sprint: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> loadSprints(String projectId) {
        try {
            DomainCompleteValidator.requireProjectExists(projectId);
            return getSprintsByProject(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> loadFuturedSprints(String projectId) {
        try {
            DomainCompleteValidator.requireProjectExists(projectId);
            return getFuturedSprintsByProject(projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static void startSprint(String sprintId) {
        try {
            Sprint__c sprint = DomainCompleteValidator.requireSprintExists(sprintId);
            DomainCompleteValidator.requireSprintIsStartable(sprint);
            // DomainCompleteValidator.requireNoActiveSprintInProject(sprint.Project__c);

            sprint.RecordStatus__c = 'in_progress';
            updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new ServiceException('Error starting sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c updateSprintWithValidation(Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireSprintExists(sprint.Id);
            return updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new ServiceException('Error updating sprint: ' + ex.getMessage());
        }
    }
}

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
            throw new Exception('Error finding sprint: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> getSprintsByProject(String projectId) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Project__c = :projectId];
        } catch (Exception ex) {
            throw new Exception('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static Sprint__c createSprint(Sprint__c sprint) {
        try {
            insert sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new Exception('DML error creating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error creating sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c updateSprint(Sprint__c sprint) {
        try {
            update sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new Exception('DML error updating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error updating sprint: ' + ex.getMessage());
        }
    }

    public static void deleteSprintById(String sprintId) {
        if (String.isBlank(sprintId)) return;
        try {
            delete new Sprint__c(Id = sprintId);
        } catch (DmlException dex) {
            throw new Exception('DML error deleting sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new Exception('Error deleting sprint: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static void completeSprint(String sprintId) {
        try {
            Sprint__c sprint = findSprintById(sprintId);
            if (sprint == null) throw new Exception('Sprint not found');
            
            sprint.RecordStatus__c = 'completed';
            
            updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new Exception('Error completing sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c createSprintWithValidation(Sprint__c sprint) {
        try {
            if (sprint == null) {
                throw new Exception('Sprint is required');
            }
            if (String.isBlank(sprint.Name)) {
                throw new Exception('name is required');
            }
            if (String.isBlank(sprint.Project__c)) {
                throw new Exception('projectId is required');
            }
            
            ProjectService.getProjectById(sprint.Project__c);
            
            return createSprint(sprint);
        } catch (Exception ex) {
            throw new Exception('Error creating sprint: ' + ex.getMessage());
        }
    }

    public static void deleteSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) throw new Exception('sprintId is required');
            deleteSprintById(sprintId);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new Exception('Error deleting sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c getSprintById(String sprintId) {
        try {
            Sprint__c sprint = findSprintById(sprintId);
            if (sprint == null) throw new Exception('Sprint not found');
            return sprint;
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new Exception('Error retrieving sprint: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> loadSprints(String projectId) {
        try {
            ProjectService.getProjectById(projectId);
            return getSprintsByProject(projectId);
        } catch (Exception ex) {
            throw new Exception('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static void startSprint(String sprintId) {
        try {
            Sprint__c sprint = findSprintById(sprintId);
            if (sprint == null) throw new Exception('Sprint not found');
            
            sprint.RecordStatus__c = 'in_progress';
            
            updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new Exception('Error starting sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c updateSprintWithValidation(Sprint__c sprint) {
        try {
            if (sprint == null) {
                throw new Exception('Sprint is required');
            }
            if (String.isBlank(sprint.Id)) {
                throw new Exception('sprintId is required');
            }
            if (String.isBlank(sprint.Name)) {
                throw new Exception('name is required');
            }
            
            Sprint__c existing = findSprintById(sprint.Id);
            if (existing == null) throw new Exception('Sprint not found');
            
            return updateSprint(sprint);
        } catch (SprintException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new Exception('Error updating sprint: ' + ex.getMessage());
        }
    }
}

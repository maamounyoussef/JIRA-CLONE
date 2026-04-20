/**
 * @description Repository for Sprint__c database operations
 * Always accepts domain objects (except findById which takes String id)
 */
public with sharing class SprintRepository {

    /**
     * @description Find sprint by Id
     * @param sprintId The sprint record Id
     * @return Sprint__c object or null if not found
     */
    public static Sprint__c findSprintById(String sprintId) {
        if (String.isBlank(sprintId)) return null;
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        } catch (Exception ex) {
            throw new SprintException('Error finding sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Get sprints by project
     * @param projectId The project Id
     * @return List of Sprint__c objects for the project
     */
    public static List<Sprint__c> getSprintsByProject(String projectId) {
        if (String.isBlank(projectId)) return new List<Sprint__c>();
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Project__c = :projectId];
        } catch (Exception ex) {
            throw new SprintException('Error loading sprints: ' + ex.getMessage());
        }
    }

    /**
     * @description Create sprint from domain object
     * @param sprint The Sprint__c domain object to insert
     * @return The created sprint with Id populated
     */
    public static Sprint__c createSprint(Sprint__c sprint) {
        if (sprint == null) throw new SprintException('Sprint object required');
        try {
            insert sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new SprintException('DML error creating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new SprintException('Error creating sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Update sprint from domain object
     * @param sprint The Sprint__c domain object with updated fields
     * @return The updated sprint object
     */
    public static Sprint__c updateSprint(Sprint__c sprint) {
        if (sprint == null) throw new SprintException('Sprint object required');
        if (String.isBlank(sprint.Id)) throw new SprintException('Sprint Id is required for update');
        try {
            update sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new SprintException('DML error updating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new SprintException('Error updating sprint: ' + ex.getMessage());
        }
    }

    /**
     * @description Delete sprint by Id
     * @param sprintId The sprint record Id
     */
    public static void deleteSprintById(String sprintId) {
        if (String.isBlank(sprintId)) return;
        try {
            delete new Sprint__c(Id = sprintId);
        } catch (DmlException dex) {
            throw new SprintException('DML error deleting sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new SprintException('Error deleting sprint: ' + ex.getMessage());
        }
    }
}

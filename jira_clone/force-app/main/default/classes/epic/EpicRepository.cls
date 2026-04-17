/**
 * @description Repository for Epic__c DB operations
 */
public with sharing class EpicRepository {

    /**
     * @description Find epics by project ID
     * @param projectId The Project ID
     * @return List of Epic__c records
     */
    public static List<Epic__c> findEpicsByProject(String projectId) {
        if (String.isBlank(projectId)) return new List<Epic__c>();
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, StartDate__c, EndDate__c, Project__c
                FROM Epic__c
                WHERE Project__c = :projectId
                ORDER BY Name ASC
            ];
        } catch (Exception ex) {
            throw new EpicException('Error querying epics: ' + ex.getMessage());
        }
    }

    /**
     * @description Find epic by ID
     * @param epicId The Epic ID
     * @return Epic__c object or null if not found
     */
    public static Epic__c findEpicById(String epicId) {
        if (String.isBlank(epicId)) return null;
        try {
            List<Epic__c> res = [
                SELECT Id, Name, Summary__c, Description__c, StartDate__c, EndDate__c, Project__c
                FROM Epic__c
                WHERE Id = :epicId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new EpicException('Error retrieving epic: ' + ex.getMessage());
        }
    }

    /**
     * @description Create a new Epic__c record
     * @param epic The Epic__c domain object to insert
     * @return The created Epic__c object with Id
     */
    public static Epic__c createEpic(Epic__c epic) {
        if (epic == null) throw new EpicException('epic is required');
        try {
            insert epic;
            return epic;
        } catch (DmlException dex) {
            throw new EpicException('DML error creating epic: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new EpicException('Error creating epic: ' + ex.getMessage());
        }
    }

    /**
     * @description Update an Epic__c record
     * @param epic The updated Epic__c object
     * @return The updated Epic__c object
     */
    public static Epic__c updateEpic(Epic__c epic) {
        if (epic == null) throw new EpicException('epic is required');
        if (String.isBlank(epic.Id)) throw new EpicException('epic Id is required');
        try {
            update epic;
            return epic;
        } catch (DmlException dex) {
            throw new EpicException('DML error updating epic: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new EpicException('Error updating epic: ' + ex.getMessage());
        }
    }
}
/**
 * @description Controller for loading Sprint records for LWC components
 */
public with sharing class SprintController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadSprints(String projectId) {
        try {
            List<Sprint__c> sprints;
            if (String.isBlank(projectId)) {
                sprints = [
                    SELECT Id, Name, StartDate__c, Duration__c, Goal__c, RecordStatus__c, Project__c
                    FROM Sprint__c
                    ORDER BY StartDate__c
                ];
            } else {
                sprints = [
                    SELECT Id, Name, StartDate__c, Duration__c, Goal__c, RecordStatus__c, Project__c
                    FROM Sprint__c
                    WHERE Project__c = :projectId
                    ORDER BY StartDate__c
                ];
            }
            return new APIResponse(true, 'Sprints loaded successfully', sprints);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading sprints: ' + ex.getMessage());
        }
    }

}

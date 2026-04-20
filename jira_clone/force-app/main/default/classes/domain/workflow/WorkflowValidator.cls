/**
 * @description Validator for Workflow__c business rules
 */
public with sharing class WorkflowValidator {

    /**
     * @description Check if a Workflow exists by ID
     * @param workflowId The Workflow ID
     * @return true if the Workflow exists, false otherwise
     */
    public static Boolean exists(String workflowId) {
        if (String.isBlank(workflowId)) return false;
        try {
            List<Workflow__c> workflows = [
                SELECT Id
                FROM Workflow__c
                WHERE Id = :workflowId
                LIMIT 1
            ];
            return !workflows.isEmpty();
        } catch (Exception ex) {
            throw new WorkflowException('Error checking workflow existence: ' + ex.getMessage());
        }
    }
}

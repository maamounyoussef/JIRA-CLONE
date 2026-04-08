/**
 * @description Repository class for WorkflowTransition-related database operations
 * Handles all SOQL queries and DML operations for workflow transition objects
 */
public with sharing class WorkflowTransitionRepository {
    
    /**
     * @description Get all transitions for a workflow
     * @param workflowId - The Workflow__c record Id
     * @return List of WorkflowTransition__c records
     */
    public static List<WorkflowTransition__c> getTransitionsByWorkflow(String workflowId) {
        return [
            SELECT Id, Name, Workflow__c, FromStatus__c, ToStatus__c, RecordStatus__c, CreatedDate
            FROM WorkflowTransition__c
            WHERE Workflow__c = :workflowId
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Get transition by Id
     * @param transitionId - The WorkflowTransition__c record Id
     * @return WorkflowTransition__c record
     * @throws WorkflowException - If transition not found
     */
    public static WorkflowTransition__c getTransitionById(String transitionId) {
        List<WorkflowTransition__c> transitions = [
            SELECT Id, Name, Workflow__c, FromStatus__c, ToStatus__c, RecordStatus__c, CreatedDate
            FROM WorkflowTransition__c
            WHERE Id = :transitionId
            LIMIT 1
        ];
        
        if (transitions.isEmpty()) {
            throw new WorkflowException('Workflow Transition not found');
        }
        
        return transitions[0];
    }
    
    /**
     * @description Create a new workflow transition
     * @param name - The transition name
     * @param workflowId - The Workflow__c record Id
     * @param fromStatusId - The from Status__c record Id
     * @param toStatusId - The to Status__c record Id
     * @param recordStatus - The record status indicator (optional)
     * @return The created WorkflowTransition__c record
     * @throws WorkflowException - If DML exception occurs
     */
    public static WorkflowTransition__c createTransition(String name, String workflowId, String fromStatusId, String toStatusId, String recordStatus) {
        try {
            WorkflowTransition__c transition = new WorkflowTransition__c(
                Name = name,
                Workflow__c = workflowId,
                FromStatus__c = fromStatusId,
                ToStatus__c = toStatusId,
                RecordStatus__c = recordStatus
            );
            insert transition;
            return transition;
        } catch (DmlException ex) {
            throw new WorkflowException('Error creating workflow transition: ' + ex.getMessage());
        }
    }
}

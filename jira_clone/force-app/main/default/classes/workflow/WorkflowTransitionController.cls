/**
 * @description Controller for managing WorkflowTransition operations
 * Handles workflow transition retrieval and creation
 * Uses WorkflowTransitionService for business logic
 */
public with sharing class WorkflowTransitionController {
    
    /**
     * @description Load all transitions for a workflow
     * @param workflowId - The Workflow__c record Id
     * @return APIResponse containing List<WorkflowTransition__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadTransitions(String workflowId) {
        try {
            List<WorkflowTransition__c> transitions = WorkflowTransitionService.loadTransitions(workflowId);
            return new APIResponse(true, 'Workflow Transitions loaded successfully', transitions);
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading workflow transitions: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new workflow transition
     * @param name - The transition name
     * @param workflowId - The Workflow__c record Id
     * @param fromStatusId - The from Status__c record Id
     * @param toStatusId - The to Status__c record Id
     * @param recordStatus - The record status indicator (optional)
     * @return APIResponse containing created WorkflowTransition__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createTransition(String name, String workflowId, String fromStatusId, String toStatusId, String recordStatus) {
        try {
            WorkflowTransition__c transition = WorkflowTransitionService.createTransition(name, workflowId, fromStatusId, toStatusId, recordStatus);
            return new APIResponse(true, 'Workflow Transition created successfully', transition);
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating workflow transition: ' + ex.getMessage());
        }
    }
}

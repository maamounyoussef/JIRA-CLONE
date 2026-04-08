/**
 * @description Controller for managing Workflow configuration for Ticket Types
 * Handles workflow transitions, validation rules, and status management
 * Uses WorkflowService for business logic and WorkflowRepository for data access
 */
public with sharing class WorkflowController {
    
    /**
     * @description Get workflow with all transitions and validation rules
     * @param workflowId - The Workflow record Id
     * @return APIResponse containing WorkflowConfigDTO in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getWorkflow(String workflowId) {
        try {
            WorkflowConfigDTO config = WorkflowService.getWorkflow(workflowId);
            return new APIResponse(true, 'Workflow retrieved successfully', config);
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving workflow: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project record Id
     * @return APIResponse containing List of Status__c objects in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectStatuses(String projectId) {
        try {
            List<Status__c> statuses = WorkflowService.getProjectStatuses(projectId);
            return new APIResponse(true, 'Project statuses retrieved successfully', statuses);
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Load all workflows
     * @return APIResponse containing List<Workflow__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadWorkflows() {
        try {
            List<Workflow__c> workflows = WorkflowService.loadWorkflows();
            return new APIResponse(true, 'Workflows loaded successfully', workflows);
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading workflows: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new workflow
     * @param name - The workflow name
     * @param projectId - The Project__c record Id
     * @return APIResponse containing created Workflow__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createWorkflow(String name, String projectId) {
        try {
            Workflow__c workflow = WorkflowService.createWorkflow(name, projectId);
            return new APIResponse(true, 'Workflow created successfully', workflow);
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating workflow: ' + ex.getMessage());
        }
    }
    // TODO ADD APILAYER
    
    /**
     * @description Add a new Validation Rule to a Workflow Transition
     * Precondition: Workflow Transition must exist
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @param ticketField - The ticket field to validate
     * @param validationType - The type of validation (e.g., "not equals")
     * @return APIResponse with success status and created ValidationRule__c object
     */
    @AuraEnabled
    public static APIResponse addValidationRule(
        String workflowTransitionId, 
        String ticketField, 
        String validationType
    ) {
        try {
            ValidationRule__c rule = WorkflowService.addValidationRule(
                workflowTransitionId,
                ticketField,
                validationType
            );
            return new APIResponse(
                true, 
                'Validation Rule created successfully with pending status',
                rule
            );
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error adding validation rule: ' + ex.getMessage());
        }
    }
    
    
    /**
     * @description Delete a Validation Rule (soft delete by setting status to deleted)
     * @param validationRuleId - The ValidationRule__c record Id
     * @return APIResponse with success status
     */
    @AuraEnabled
    public static APIResponse deleteValidationRule(String validationRuleId) {
        try {
            WorkflowService.deleteValidationRule(validationRuleId);
            return new APIResponse(true, 'Validation Rule deleted successfully');
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting validation rule: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Add a new Workflow Transition to an existing Workflow
     * @param workflowId - The Workflow__c record Id
     * @param name - The name of the transition
     * @param fromStatusId - The Id of the from status
     * @param toStatusId - The Id of the to status
     * @return APIResponse with success status and created WorkflowTransition__c object
     */
    @AuraEnabled
    public static APIResponse addWorkflowTransition(
        String workflowId, 
        String name, 
        String fromStatusId, 
        String toStatusId
    ) {
        try {
            WorkflowTransition__c transition = WorkflowService.addWorkflowTransition(
                workflowId,
                name,
                fromStatusId,
                toStatusId
            );
            return new APIResponse(
                true, 
                'Workflow Transition created successfully with pending status',
                transition
            );
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error adding workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Activate a Validation Rule (change status from pending to active)
     * One-way operation: can only go from pending to active, not the reverse
     * @param validationRuleId - The ValidationRule__c record Id
     * @return APIResponse with success status
     */
    @AuraEnabled
    public static APIResponse activateValidationRule(String validationRuleId) {
        try {
            WorkflowService.activateValidationRule(validationRuleId);
            return new APIResponse(true, 'Validation Rule activated successfully');
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error activating validation rule: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Activate a Workflow Transition (change status from pending to active)
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @return APIResponse with success status
     */
    @AuraEnabled
    public static APIResponse activateWorkflowTransition(String workflowTransitionId) {
        try {
            WorkflowService.activateWorkflowTransition(workflowTransitionId);
            return new APIResponse(true, 'Workflow Transition activated successfully');
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error activating workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Final update workflow: activate all pending transitions and validation rules
     * This is called when the user clicks the Update Workflow button
     * Precondition: At least one new transition or validation rule must have been added
     * @param workflowId - The Workflow__c record Id
     * @return APIResponse with success status
     */
    @AuraEnabled
    public static APIResponse updateWorkflow(String workflowId) {
        try {
            WorkflowService.updateWorkflow(workflowId);
            return new APIResponse(
                true, 
                'Workflow updated successfully. All pending transitions and validation rules activated.'
            );
        } catch (WorkflowException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating workflow: ' + ex.getMessage());
        }
    }
}

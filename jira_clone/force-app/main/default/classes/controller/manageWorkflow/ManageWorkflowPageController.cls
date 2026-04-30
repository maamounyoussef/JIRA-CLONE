/**
 * @description Controller for managing Workflow operations from the Manage Workflow Page
 * Consolidates all workflow and workflow transition operations
 * Handles workflow transitions, validation rules, and status management
 * Uses individual Use Cases for each business action
 */
public with sharing class ManageWorkflowPageController {

    // ==================== WORKFLOW METHODS ====================

    /**
     * @description Get workflow with all transitions and validation rules
     * @param workflowId - The Workflow record Id
     * @return APIResponse containing WorkflowConfigDTO in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getWorkflow(String workflowId) {
        try {
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');
            Workflow__c workflow = DomainCorrectness.requireWorkflowExists(workflowId);
            WorkflowConfigDTO config = WorkflowService.getWorkflowConfig(workflow);
            return new APIResponse(true, 'Workflow retrieved successfully', config);
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
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<Status__c> statuses = StatusService.loadStatuses(project);
            return new APIResponse(true, 'Project statuses retrieved successfully', statuses);
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
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireProjectExists(projectId);

            Workflow__c workflow = WorkflowService.createWorkflowWithValidation(name, projectId);
            return new APIResponse(true, 'Workflow created successfully', workflow);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating workflow: ' + ex.getMessage());
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
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');

            Workflow__c workflow = DomainCorrectness.requireWorkflowExists(workflowId);

            WorkflowService.updateWorkflow(workflow);
            return new APIResponse(
                true,
                'Workflow updated successfully. All pending transitions and validation rules activated.'
            );
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating workflow: ' + ex.getMessage());
        }
    }

    // ==================== TICKET TYPE METHODS ====================

    /**
     * @description Get ticket type by Id
     * @param ticketTypeId - The TicketType__c record Id
     * @return APIResponse containing TicketType__c in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeById(String ticketTypeId) {
        try {
            if (String.isBlank(ticketTypeId)) return new APIResponse(false, 'ticketTypeId is required');
            TicketType__c ticketType = DomainCorrectness.requireTicketTypeExists(ticketTypeId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    // ==================== STATUS METHODS ====================

    /**
     * @description Load all statuses for a project
     * @param projectId - The Project__c record Id
     * @return APIResponse containing List<Status__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadStatuses(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<Status__c> statuses = StatusService.loadStatuses(project);
            return new APIResponse(true, 'Statuses loaded successfully', statuses);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading statuses: ' + ex.getMessage());
        }
    }

    /**
     * @description Create a new status
     * @param name - The status name
     * @param projectId - The Project__c record Id
     * @return APIResponse containing created Status__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createStatus(String name, String projectId) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireProjectExists(projectId);

            Status__c status = StatusService.createStatus(name, projectId);
            return new APIResponse(true, 'Status created successfully', status);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating status: ' + ex.getMessage());
        }
    }

    // ==================== WORKFLOW TRANSITION METHODS ====================

    /**
     * @description Load all transitions for a workflow
     * @param workflowId - The Workflow__c record Id
     * @return APIResponse containing List<WorkflowTransition__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadTransitions(String workflowId) {
        try {
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');
            Workflow__c workflow = DomainCorrectness.requireWorkflowExists(workflowId);
            List<WorkflowTransition__c> transitions = WorkflowService.loadWorkflowTransitions(workflow);
            return new APIResponse(true, 'Workflow Transitions loaded successfully', transitions);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading workflow transitions: ' + ex.getMessage());
        }
    }

    /**
     * @description Get workflow transition by ID
     * @param transitionId - The WorkflowTransition__c record Id
     * @return APIResponse containing WorkflowTransition__c in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse getWorkflowTransitionById(String transitionId) {
        try {
            if (String.isBlank(transitionId)) return new APIResponse(false, 'transitionId is required');
            WorkflowTransition__c transition = DomainCorrectness.requireTransitionExists(transitionId);
            return new APIResponse(true, 'Workflow Transition retrieved successfully', transition);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving workflow transition: ' + ex.getMessage());
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
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');
            if (String.isBlank(fromStatusId)) return new APIResponse(false, 'fromStatusId is required');
            if (String.isBlank(toStatusId)) return new APIResponse(false, 'toStatusId is required');

            Workflow__c workflow = DomainCorrectness.requireWorkflowExists(workflowId);
            Status__c fromStatus = DomainCorrectness.requireStatusExists(fromStatusId);
            Status__c toStatus = DomainCorrectness.requireStatusExists(toStatusId);

            WorkflowTransition__c transition = WorkflowService.createWorkflowTransition(name, workflow, fromStatus, toStatus, recordStatus);
            return new APIResponse(true, 'Workflow Transition created successfully', transition);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating workflow transition: ' + ex.getMessage());
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
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(fromStatusId)) return new APIResponse(false, 'fromStatusId is required');
            if (String.isBlank(toStatusId)) return new APIResponse(false, 'toStatusId is required');

            Workflow__c workflow = DomainCorrectness.requireWorkflowExists(workflowId);
            Status__c fromStatus = DomainCorrectness.requireStatusExists(fromStatusId);
            Status__c toStatus = DomainCorrectness.requireStatusExists(toStatusId);

            WorkflowTransition__c transition = WorkflowService.addWorkflowTransition(workflow, name, fromStatus, toStatus);
            return new APIResponse(
                true,
                'Workflow Transition created successfully with pending status',
                transition
            );
        } catch (Exception ex) {
            return new APIResponse(false, 'Error adding workflow transition: ' + ex.getMessage());
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
            if (String.isBlank(workflowTransitionId)) return new APIResponse(false, 'workflowTransitionId is required');
            WorkflowTransition__c transition = DomainCorrectness.requireTransitionExists(workflowTransitionId);
            WorkflowService.activateWorkflowTransition(transition);
            return new APIResponse(true, 'Workflow Transition activated successfully');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error activating workflow transition: ' + ex.getMessage());
        }
    }

    /**
     * @description Delete a Workflow Transition (soft delete by setting status to deleted)
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @return APIResponse with success status
     */
    @AuraEnabled
    public static APIResponse deleteWorkflowTransition(String workflowTransitionId) {
        try {
            if (String.isBlank(workflowTransitionId)) return new APIResponse(false, 'workflowTransitionId is required');
            WorkflowTransition__c transition = DomainCorrectness.requireTransitionExists(workflowTransitionId);
            WorkflowService.deleteWorkflowTransition(transition);
            return new APIResponse(true, 'Workflow Transition deleted successfully');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting workflow transition: ' + ex.getMessage());
        }
    }

    // ==================== VALIDATION RULE METHODS ====================

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
            if (String.isBlank(workflowTransitionId)) return new APIResponse(false, 'workflowTransitionId is required');
            if (String.isBlank(ticketField)) return new APIResponse(false, 'ticketField is required');
            if (String.isBlank(validationType)) return new APIResponse(false, 'validationType is required');

            WorkflowTransition__c transition = DomainCorrectness.requireTransitionExists(workflowTransitionId);

            ValidationRule__c rule = WorkflowService.addValidationRule(transition, ticketField, validationType);
            return new APIResponse(
                true,
                'Validation Rule created successfully with pending status',
                rule
            );
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
            if (String.isBlank(validationRuleId)) return new APIResponse(false, 'validationRuleId is required');
            ValidationRule__c rule = DomainCorrectness.requireValidationRuleExists(validationRuleId);
            WorkflowService.deleteValidationRule(rule);
            return new APIResponse(true, 'Validation Rule deleted successfully');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting validation rule: ' + ex.getMessage());
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
            if (String.isBlank(validationRuleId)) return new APIResponse(false, 'validationRuleId is required');
            ValidationRule__c rule = DomainCorrectness.requireValidationRuleExists(validationRuleId);
            WorkflowService.activateValidationRule(rule);
            return new APIResponse(true, 'Validation Rule activated successfully');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error activating validation rule: ' + ex.getMessage());
        }
    }
}

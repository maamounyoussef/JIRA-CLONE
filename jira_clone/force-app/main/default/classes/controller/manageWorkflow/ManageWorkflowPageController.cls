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
    @AuraEnabled(cacheable=false)
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
     * @description Load every (non-deleted) Workflow that belongs to a given
     * Project, with the basic info the manage-workflow list UI needs (name, id,
     * record status, audit fields). Drives the project → workflow list step
     * after a user picks a project on the manage workflow page.
     * @param projectId - The Project__c record Id
     * @return APIResponse containing List<Workflow__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadWorkflowsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            DomainCorrectness.requireProjectExists(projectId);
            List<Workflow__c> workflows = WorkflowService.loadWorkflowsByProject(projectId);
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

    /**
     * @description Activate every pending WorkflowTransition for the given
     * Workflow. Triggered by the Update Workflow button in step 3 of the
     * manage workflow page.
     * @param workflowId - The Workflow__c record Id
     * @return APIResponse with the number of activated transitions in data
     */
    @AuraEnabled
    public static APIResponse updateFullWorkflowTransition(String workflowId) {
        try {
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');

            DomainCorrectness.requireWorkflowExists(workflowId);

            Integer activatedCount = WorkflowService.updateFullWorkflowTransition(workflowId);
            return new APIResponse(
                true,
                activatedCount + ' pending transition(s) activated successfully',
                activatedCount
            );
        } catch (Exception ex) {
            return new APIResponse(false, 'Error activating pending workflow transitions: ' + ex.getMessage());
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

    // ==================== VALIDATION FIELD METHODS ====================

    /**
     * @description Create a new ValidateField__c (a Ticket-field validation rule)
     * @param fieldName - The Ticket field API name to validate (FieldName__c)
     * @param type - The validation type (Type__c)
     * @return APIResponse containing the created ValidateField__c in data attribute
     */
    /**
     * @description Load all (non-deleted) ValidateField__c for a workflow
     * transition, so the manage-workflow transition detail panel can expand and
     * list them. Read-only, so cacheable for @wire.
     * @param transitionId - The WorkflowTransition__c record Id
     * @return APIResponse containing List<ValidateField__c> in data attribute
     */
    @AuraEnabled(cacheable=true)
    public static APIResponse loadValidateFields(String transitionId) {
        try {
            if (String.isBlank(transitionId)) return new APIResponse(false, 'transitionId is required');
            DomainCorrectness.requireTransitionExists(transitionId);
            List<ValidateField__c> rules = ValidateFieldService.loadValidateFieldsByTransition(transitionId);
            return new APIResponse(true, 'Validation fields loaded successfully', rules);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading validation fields: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse addValidateField(String workflowTransitionId ,String fieldName, String type) {
        try {
            if (String.isBlank(fieldName)) return new APIResponse(false, 'fieldName is required');
            if (String.isBlank(type)) return new APIResponse(false, 'type is required');

            ValidateField__c rule = ValidateFieldService.createValidateField(workflowTransitionId, fieldName, type);
            return new APIResponse(true, 'Validation field created successfully', rule);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating validation field: ' + ex.getMessage());
        }
    }

}


public with sharing class ManageWorkflowPageController {

    // ==================== WORKFLOW METHODS ====================


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

    @AuraEnabled(cacheable=true)
    public static APIResponse loadWorkflows() {
        try {
            List<Workflow__c> workflows = WorkflowService.loadWorkflows();
            return new APIResponse(true, 'Workflows loaded successfully', workflows);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading workflows: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static APIResponse loadWorkflowsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            // InputSecurityValidator.validatePageAccessManageWorkflow(projectId);
            DomainCorrectness.requireProjectExists(projectId);
            List<Workflow__c> workflows = WorkflowService.loadWorkflowsByProject(projectId);
            return new APIResponse(true, 'Workflows loaded successfully', workflows);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading workflows: ' + ex.getMessage());
        }
    }


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

    // Cacheable: the show/hide validation panel reads this through a @wire, so the
    // Lightning Data Service caches the list per transition for instant re-expands.
    // Freshness after a rule is added is handled on the client via refreshApex(),
    // which busts this cache and re-provisions the wire with server-truth.
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

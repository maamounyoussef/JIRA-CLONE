/**
 * @description Service class for Workflow business logic
 * Handles validation and orchestration of workflow operations using WorkflowRepository
 */
public with sharing class WorkflowService {
    
    /**
     * @description Get workflow with all transitions and validation rules for UI display
     * @param workflowId - The Workflow__c record Id
     * @return WorkflowConfigDTO containing workflow configuration data
     * @throws WorkflowException - If workflow not found or other errors occur
     */
    public static WorkflowConfigDTO getWorkflow(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            // Fetch workflow with all related transitions and rules
            Workflow__c workflow = WorkflowRepository.getWorkflowWithTransitions(workflowId);
            
            WorkflowConfigDTO config = new WorkflowConfigDTO();
            
            // Build workflow info
            config.workflow.id = workflow.Id;
            config.workflow.name = workflow.Name;
            
            // Build transition infos with nested validation rules
            if (workflow.WorkflowTransitions__r != null) {
                for (WorkflowTransition__c transition : workflow.WorkflowTransitions__r) {
                    WorkflowConfigDTO.TransitionInfo transInfo = new WorkflowConfigDTO.TransitionInfo();
                    transInfo.id = transition.Id;
                    transInfo.name = transition.Name;
                    transInfo.fromStatus = transition.FromStatus__c;
                    transInfo.toStatus = transition.ToStatus__c;
                    transInfo.recordStatus = transition.RecordStatus__c;
                    
                    // Add validation rules
                    if (transition.ValidationRules__r != null) {
                        for (ValidationRule__c rule : transition.ValidationRules__r) {
                            WorkflowConfigDTO.ValidationRuleInfo ruleInfo = new WorkflowConfigDTO.ValidationRuleInfo();
                            ruleInfo.id = rule.Id;
                            ruleInfo.ticketField = rule.TicketField__c;
                            ruleInfo.type = rule.Type__c;
                            ruleInfo.recordStatus = rule.RecordStatus__c;
                            transInfo.validationRules.add(ruleInfo);
                        }
                    }
                    
                    config.workflow.transitions.add(transInfo);
                }
            }
            
            // Fetch Project Statuses
            if (workflow.Project__c != null) {
                List<Status__c> projectStatuses = WorkflowRepository.getProjectStatuses(workflow.Project__c);
                
                // Build status infos
                for (Status__c status : projectStatuses) {
                    WorkflowConfigDTO.StatusInfo statusInfo = new WorkflowConfigDTO.StatusInfo();
                    statusInfo.id = status.Id;
                    statusInfo.name = status.Name;
                    config.projectStatus.add(statusInfo);
                }
            }
            
            return config;
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error retrieving workflow: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c objects
     * @throws WorkflowException - If project not found or other errors occur
     */
    public static List<Status__c> getProjectStatuses(String projectId) {
        try {
            validateIdParameter(projectId, 'Project Id');
            
            // TODO ADD APILAYER
            return ProjectService.getProjectStatuses(projectId);
        } catch (Exception ex) {
            throw new WorkflowException('Error retrieving project statuses: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Add a new Validation Rule to a Workflow Transition
     * Validates inputs and ensures transition exists before creating rule
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @param ticketField - The ticket field to validate
     * @param validationType - The type of validation (e.g., "not equals")
     * @return Created ValidationRule__c with pending status
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static ValidationRule__c addValidationRule(
        String workflowTransitionId, 
        String ticketField, 
        String validationType
    ) {
        try {
            // Validate inputs
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            if (String.isBlank(ticketField)) {
                throw new WorkflowException('Ticket field is required');
            }
            
            if (String.isBlank(validationType)) {
                throw new WorkflowException('Validation type is required');
            }
            
            // Verify Workflow Transition exists
            WorkflowRepository.getWorkflowTransitionById(workflowTransitionId);
            
            // Create new Validation Rule with pending status
            ValidationRule__c newRule = new ValidationRule__c();
            newRule.WorkflowTransition__c = workflowTransitionId;
            newRule.TicketField__c = ticketField;
            newRule.Type__c = validationType;
            newRule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return WorkflowRepository.insertValidationRule(newRule);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error adding validation rule: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Delete a Validation Rule (soft delete by setting status to deleted)
     * @param validationRuleId - The ValidationRule__c record Id
     * @returns Empty string (success case) - consistent with error returns
     * @throws WorkflowException - If rule not found or other errors occur
     */
    public static void deleteValidationRule(String validationRuleId) {
        try {
            validateIdParameter(validationRuleId, 'Validation Rule Id');
            
            // Get the rule
            ValidationRule__c rule = WorkflowRepository.getValidationRuleById(validationRuleId);
            
            // Soft delete: set status to deleted
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            
            WorkflowRepository.updateRecord(rule);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error deleting validation rule: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Add a new Workflow Transition to an existing Workflow
     * Validates inputs and ensures workflow and statuses exist
     * @param workflowId - The Workflow__c record Id
     * @param name - The name of the transition
     * @param fromStatusId - The Id of the from status
     * @param toStatusId - The Id of the to status
     * @return Created WorkflowTransition__c with pending status
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static WorkflowTransition__c addWorkflowTransition(
        String workflowId, 
        String name, 
        String fromStatusId, 
        String toStatusId
    ) {
        try {
            // Validate inputs
            validateIdParameter(workflowId, 'Workflow Id');
            
            if (String.isBlank(name)) {
                throw new WorkflowException('Transition name is required');
            }
            
            validateIdParameter(fromStatusId, 'From Status Id');
            validateIdParameter(toStatusId, 'To Status Id');
            
            // Verify Workflow exists
            WorkflowRepository.getWorkflowById(workflowId);
            
            // Verify both statuses exist
            List<Status__c> statuses = WorkflowRepository.getStatusesById(
                new List<String> { fromStatusId, toStatusId }
            );
            
            if (statuses.size() != 2) {
                throw new WorkflowException('One or both statuses not found');
            }
            
            // Create new Workflow Transition with pending status
            WorkflowTransition__c newTransition = new WorkflowTransition__c();
            newTransition.Workflow__c = workflowId;
            newTransition.Name = name;
            newTransition.FromStatus__c = fromStatusId;
            newTransition.ToStatus__c = toStatusId;
            newTransition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return WorkflowRepository.insertWorkflowTransition(newTransition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error adding workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Activate a Validation Rule (change status from pending to active)
     * One-way operation: can only go from pending to active, not the reverse
     * @param validationRuleId - The ValidationRule__c record Id
     * @throws WorkflowException - If rule not pending or other errors occur
     */
    public static void activateValidationRule(String validationRuleId) {
        try {
            validateIdParameter(validationRuleId, 'Validation Rule Id');
            
            // Get the rule
            ValidationRule__c rule = WorkflowRepository.getValidationRuleById(validationRuleId);
            
            // Can only activate if currently pending
            if (rule.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
                throw new WorkflowException(
                    'Validation Rule can only be activated from pending status'
                );
            }
            
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            WorkflowRepository.updateRecord(rule);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error activating validation rule: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Activate a Workflow Transition (change status from pending to active)
     * One-way operation: can only go from pending to active, not the reverse
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @throws WorkflowException - If transition not pending or other errors occur
     */
    public static void activateWorkflowTransition(String workflowTransitionId) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            // Get the transition
            WorkflowTransition__c transition = new WorkflowTransition__c();
            List<WorkflowTransition__c> transitions = [
                SELECT Id, RecordStatus__c
                FROM WorkflowTransition__c
                WHERE Id = :workflowTransitionId
                LIMIT 1
            ];
            
            if (transitions.isEmpty()) {
                throw new WorkflowException('Workflow Transition not found');
            }
            
            transition = transitions[0];
            
            // Can only activate if currently pending
            if (transition.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
                throw new WorkflowException(
                    'Workflow Transition can only be activated from pending status'
                );
            }
            
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            WorkflowRepository.updateRecord(transition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error activating workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Final update workflow: activate all pending transitions and validation rules
     * This is called when the user clicks the Update Workflow button
     * Precondition: At least one new transition or validation rule must have been added
     * @param workflowId - The Workflow__c record Id
     * @throws WorkflowException - If workflow not found or other errors occur
     */
    public static void updateWorkflow(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            // Verify Workflow exists
            WorkflowRepository.getWorkflowById(workflowId);
            
            // Get all pending transitions and validation rules for this workflow
            List<WorkflowTransition__c> pendingTransitions = 
                WorkflowRepository.getPendingTransitions(workflowId);
            
            List<ValidationRule__c> pendingRules = 
                WorkflowRepository.getPendingRules(workflowId);
            
            // Activate all pending transitions
            for (WorkflowTransition__c transition : pendingTransitions) {
                transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            }
            
            // Activate all pending validation rules
            for (ValidationRule__c rule : pendingRules) {
                rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            }
            
            // Perform bulk update
            List<SObject> recordsToUpdate = new List<SObject>();
            recordsToUpdate.addAll(pendingTransitions);
            recordsToUpdate.addAll(pendingRules);
            
            WorkflowRepository.updateRecords(recordsToUpdate);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error updating workflow: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that a parameter is not blank (used for Ids)
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws WorkflowException - If value is blank
     */
    private static void validateIdParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new WorkflowException(paramName + ' is required');
        }
    }
}

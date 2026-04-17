/**
 * @description Service class for WorkflowTransition business logic
 * Handles validation and orchestration of workflow transition operations using WorkflowTransitionRepository
 */
public with sharing class WorkflowTransitionService {
    
    /**
     * @description Load all transitions for a workflow
     * @param workflowId - The Workflow__c record Id
     * @return List of WorkflowTransition__c objects
     * @throws WorkflowException - If error occurs
     */
    public static List<WorkflowTransition__c> loadTransitions(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            return WorkflowTransitionRepository.getTransitionsByWorkflow(workflowId);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error loading workflow transitions: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get transition by Id
     * @param transitionId - The WorkflowTransition__c record Id
     * @return WorkflowTransition__c object
     * @throws WorkflowException - If transition not found or other errors occur
     */
    public static WorkflowTransition__c getTransitionById(String transitionId) {
        try {
            validateIdParameter(transitionId, 'Transition Id');
            
            return WorkflowTransitionRepository.getTransitionById(transitionId);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error retrieving workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Create a new workflow transition
     * @param name - The transition name
     * @param workflowId - The Workflow__c record Id
     * @param fromStatusId - The from Status__c record Id
     * @param toStatusId - The to Status__c record Id
     * @param recordStatus - The record status indicator (optional)
     * @return The created WorkflowTransition__c record
     * @throws WorkflowException - If validation fails or DML error occurs
     */
    public static WorkflowTransition__c createTransition(String name, String workflowId, String fromStatusId, String toStatusId, String recordStatus) {
        try {
            validateNameParameter(name, 'Transition Name');
            validateIdParameter(workflowId, 'Workflow Id');
            validateIdParameter(fromStatusId, 'From Status Id');
            validateIdParameter(toStatusId, 'To Status Id');
            
            // Verify workflow exists
            WorkflowRepository.getWorkflowById(workflowId);
            
            // Verify statuses exist
            StatusRepository.getStatusById(fromStatusId);
            StatusRepository.getStatusById(toStatusId);
            
            // Ensure transition name is unique within the workflow
            if (WorkflowTransitionRepository.transitionNameExists(workflowId, name)) {
                throw new WorkflowException('Transition name already exists in this workflow');
            }
            
            return WorkflowTransitionRepository.createTransition(name, workflowId, fromStatusId, toStatusId, recordStatus);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (StatusException ex) {
            throw new WorkflowException('Invalid status: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new WorkflowException('Error creating workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Validate that a parameter is not blank
     * @param value - The value to validate
     * @param paramName - The parameter name for error message
     * @throws WorkflowException - If value is blank
     */
    private static void validateNameParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new WorkflowException(paramName + ' is required');
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
            
            // Ensure transition name is unique within the workflow
            if (WorkflowTransitionRepository.transitionNameExists(workflowId, name)) {
                throw new WorkflowException('Transition name already exists in this workflow');
            }
            
            // Create new Workflow Transition with pending status
            WorkflowTransition__c newTransition = new WorkflowTransition__c();
            newTransition.Workflow__c = workflowId;
            newTransition.Name = name;
            newTransition.FromStatus__c = fromStatusId;
            newTransition.ToStatus__c = toStatusId;
            newTransition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return WorkflowTransitionRepository.insertWorkflowTransition(newTransition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error adding workflow transition: ' + ex.getMessage());
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
            WorkflowTransition__c transition = WorkflowTransitionRepository.getTransitionById(workflowTransitionId);
            
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
     * @description Delete a Workflow Transition (soft delete by setting status to deleted)
     * @param workflowTransitionId - The WorkflowTransition__c record Id
     * @throws WorkflowException - If transition not found or other errors occur
     */
    public static void deleteWorkflowTransition(String workflowTransitionId) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            // Get the transition
            WorkflowTransition__c transition = WorkflowTransitionRepository.getTransitionById(workflowTransitionId);
            
            // Soft delete: set status to deleted
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            
            WorkflowRepository.updateRecord(transition);
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error deleting workflow transition: ' + ex.getMessage());
        }
    }

    /**
     * @description Validate that an Id parameter is not blank
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
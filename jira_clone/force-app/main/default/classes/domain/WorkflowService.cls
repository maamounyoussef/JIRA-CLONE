/**
 * @description Service class for Workflow operations
 * Consolidates all usecases and repository methods for Workflow domain
 */
public with sharing class WorkflowService {
    
    // Repository methods from WorkflowRepository
    public static Workflow__c getWorkflowWithTransitions(String workflowId) {
        List<Workflow__c> workflows = [
            SELECT 
                Id, 
                Name, 
                Project__c,
                (
                    SELECT 
                        Id, 
                        Name, 
                        FromStatus__c, 
                        ToStatus__c, 
                        RecordStatus__c, 
                        Workflow__c
                    FROM WorkflowTransitions__r 
                    WHERE RecordStatus__c != :WorkflowConstants.RECORD_STATUS_DELETED
                    ORDER BY RecordStatus__c DESC, CreatedDate ASC
                )
            FROM Workflow__c 
            WHERE Id = :workflowId 
            LIMIT 1
        ];
        return workflows[0];
    }
    
    public static Workflow__c getWorkflow(String workflowId) {
        List<Workflow__c> workflows = [
            SELECT Id, Name, Project__c
            FROM Workflow__c 
            WHERE Id = :workflowId 
            LIMIT 1
        ];
        
        if (workflows.isEmpty()) {
            throw new Exception('Workflow not found');
        }
        
        return workflows[0];
    }
    
    public static Workflow__c getWorkflowById(String workflowId) {
        List<Workflow__c> workflows = [
            SELECT Id, Name, Project__c
            FROM Workflow__c 
            WHERE Id = :workflowId 
            LIMIT 1
        ];
        
        if (workflows.isEmpty()) {
            throw new Exception('Workflow not found');
        }
        
        return workflows[0];
    }
    
    public static WorkflowTransition__c getWorkflowTransitionById(String transitionId) {
        List<WorkflowTransition__c> transitions = [
            SELECT Id, Workflow__c 
            FROM WorkflowTransition__c 
            WHERE Id = :transitionId
            AND RecordStatus__c != :WorkflowConstants.RECORD_STATUS_DELETED
            LIMIT 1
        ];
        
        if (transitions.isEmpty()) {
            throw new Exception('Workflow Transition not found');
        }
        
        return transitions[0];
    }
    
    public static ValidationRule__c getValidationRuleById(String ruleId) {
        List<ValidationRule__c> rules = [
            SELECT Id, RecordStatus__c, WorkflowTransition__c
            FROM ValidationRule__c 
            WHERE Id = :ruleId 
            LIMIT 1
        ];
        
        if (rules.isEmpty()) {
            throw new Exception('Validation Rule not found');
        }
        
        return rules[0];
    }
    
    public static List<Status__c> getStatusesById(List<String> statusIds) {
        return [
            SELECT Id 
            FROM Status__c 
            WHERE Id IN :statusIds
        ];
    }
    
    public static List<Status__c> getProjectStatuses(String projectId) {
        return [
            SELECT Id, Name, Project__c
            FROM Status__c 
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    
    public static List<Workflow__c> getAllWorkflows() {
        return [
            SELECT Id, Name, Project__c
            FROM Workflow__c
            ORDER BY Name ASC
        ];
    }
    
    public static Workflow__c createWorkflow(String name, String projectId) {
        try {
            Workflow__c workflow = new Workflow__c(
                Name = name,
                Project__c = projectId
            );
            insert workflow;
            return workflow;
        } catch (DmlException ex) {
            throw new Exception('Error creating workflow: ' + ex.getMessage());
        }
    }
    
    public static List<WorkflowTransition__c> getPendingTransitions(String workflowId) {
        return [
            SELECT Id, RecordStatus__c 
            FROM WorkflowTransition__c 
            WHERE Workflow__c = :workflowId 
              AND RecordStatus__c = :WorkflowConstants.RECORD_STATUS_PENDING
        ];
    }
    
    public static List<ValidationRule__c> getPendingRules(String workflowId) {
        return [
            SELECT Id, RecordStatus__c 
            FROM ValidationRule__c 
            WHERE WorkflowTransition__c IN (
                SELECT Id FROM WorkflowTransition__c WHERE Workflow__c = :workflowId AND RecordStatus__c != :WorkflowConstants.RECORD_STATUS_DELETED
            )
              AND RecordStatus__c = :WorkflowConstants.RECORD_STATUS_PENDING
        ];
    }
    
    public static ValidationRule__c insertValidationRule(ValidationRule__c rule) {
        try {
            insert rule;
            return rule;
        } catch (DmlException ex) {
            throw new Exception('Error inserting validation rule: ' + ex.getMessage());
        }
    }
    
    public static WorkflowTransition__c insertWorkflowTransition(WorkflowTransition__c transition) {
        try {
            insert transition;
            return transition;
        } catch (DmlException ex) {
            throw new Exception('Error inserting workflow transition: ' + ex.getMessage());
        }
    }
    
    public static void updateRecord(SObject record) {
        try {
            update record;
        } catch (DmlException ex) {
            throw new Exception('Error updating record: ' + ex.getMessage());
        }
    }
    
    public static void updateRecords(List<SObject> records) {
        try {
            update records;
        } catch (DmlException ex) {
            throw new Exception('Error updating records: ' + ex.getMessage());
        }
    }
    
    // Repository methods from WorkflowTransitionRepository
    public static List<WorkflowTransition__c> getTransitionsByWorkflow(String workflowId) {
        return [
            SELECT Id, Name, Workflow__c, FromStatus__c, ToStatus__c, 
                   FromStatus__r.Name, ToStatus__r.Name, RecordStatus__c, CreatedDate
            FROM WorkflowTransition__c
            WHERE Workflow__c = :workflowId
            AND RecordStatus__c != 'deleted'
            ORDER BY Name ASC
        ];
    }
    
    public static WorkflowTransition__c getTransitionById(String transitionId) {
        List<WorkflowTransition__c> transitions = [
            SELECT Id, Name, Workflow__c, FromStatus__c, ToStatus__c, 
                   FromStatus__r.Name, ToStatus__r.Name, RecordStatus__c, CreatedDate
            FROM WorkflowTransition__c
            WHERE Id = :transitionId
            AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        
        if (transitions.isEmpty()) {
            throw new Exception('Workflow Transition not found');
        }
        
        return transitions[0];
    }
    
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
            throw new Exception('Error creating workflow transition: ' + ex.getMessage());
        }
    }
    
    public static Boolean transitionNameExists(String workflowId, String name) {
        if (String.isBlank(workflowId) || String.isBlank(name)) {
            return false;
        }
        List<WorkflowTransition__c> found = [
            SELECT Id
            FROM WorkflowTransition__c
            WHERE Workflow__c = :workflowId
            AND Name = :name
            AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        return !found.isEmpty();
    }
    
    // Use case methods
    public static void activateValidationRule(String validationRuleId) {
        try {
            validateIdParameter(validationRuleId, 'Validation Rule Id');
            
            ValidationRule__c rule = getValidationRuleById(validationRuleId);
            
            if (rule.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
                throw new Exception(
                    'Validation Rule can only be activated from pending status'
                );
            }
            
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            updateRecord(rule);
        } catch (Exception ex) {
            throw new Exception('Error activating validation rule: ' + ex.getMessage());
        }
    }
    
    public static void activateWorkflowTransition(String workflowTransitionId) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            WorkflowTransition__c transition = getTransitionById(workflowTransitionId);
            
            if (transition.RecordStatus__c != WorkflowConstants.RECORD_STATUS_PENDING) {
                throw new Exception(
                    'Workflow Transition can only be activated from pending status'
                );
            }
            
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            updateRecord(transition);
        } catch (Exception ex) {
            throw new Exception('Error activating workflow transition: ' + ex.getMessage());
        }
    }
    
    public static ValidationRule__c addValidationRule(String workflowTransitionId, String ticketField, String validationType) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            if (String.isBlank(ticketField)) {
                throw new Exception('Ticket field is required');
            }
            
            if (String.isBlank(validationType)) {
                throw new Exception('Validation type is required');
            }
            
            getWorkflowTransitionById(workflowTransitionId);
            
            ValidationRule__c newRule = new ValidationRule__c();
            newRule.WorkflowTransition__c = workflowTransitionId;
            newRule.TicketField__c = ticketField;
            newRule.Type__c = validationType;
            newRule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return insertValidationRule(newRule);
        } catch (Exception ex) {
            throw new Exception('Error adding validation rule: ' + ex.getMessage());
        }
    }
    
    public static WorkflowTransition__c addWorkflowTransition(String workflowId, String name, String fromStatusId, String toStatusId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            if (String.isBlank(name)) {
                throw new Exception('Transition name is required');
            }
            
            validateIdParameter(fromStatusId, 'From Status Id');
            validateIdParameter(toStatusId, 'To Status Id');
            
            getWorkflowById(workflowId);
            
            List<Status__c> statuses = getStatusesById(
                new List<String> { fromStatusId, toStatusId }
            );
            
            if (statuses.size() != 2) {
                throw new Exception('One or both statuses not found');
            }
            
            if (transitionNameExists(workflowId, name)) {
                throw new Exception('Transition name already exists in this workflow');
            }
            
            WorkflowTransition__c newTransition = new WorkflowTransition__c();
            newTransition.Workflow__c = workflowId;
            newTransition.Name = name;
            newTransition.FromStatus__c = fromStatusId;
            newTransition.ToStatus__c = toStatusId;
            newTransition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;
            
            return insertWorkflowTransition(newTransition);
        } catch (Exception ex) {
            throw new Exception('Error adding workflow transition: ' + ex.getMessage());
        }
    }
    
    public static WorkflowTransition__c createWorkflowTransition(String name, String workflowId, String fromStatusId, String toStatusId, String recordStatus) {
        try {
            validateNameParameter(name, 'Transition Name');
            validateIdParameter(workflowId, 'Workflow Id');
            validateIdParameter(fromStatusId, 'From Status Id');
            validateIdParameter(toStatusId, 'To Status Id');
            
            getWorkflowById(workflowId);
            
            StatusService.getStatusById(fromStatusId);
            StatusService.getStatusById(toStatusId);
            
            if (transitionNameExists(workflowId, name)) {
                throw new Exception('Transition name already exists in this workflow');
            }
            
            return createTransition(name, workflowId, fromStatusId, toStatusId, recordStatus);
        } catch (Exception ex) {
            throw new Exception('Error creating workflow transition: ' + ex.getMessage());
        }
    }
    
    public static Workflow__c createWorkflowWithValidation(String name, String projectId) {
        try {
            validateNameParameter(name, 'Workflow Name');
            validateIdParameter(projectId, 'Project Id');
            
            return createWorkflow(name, projectId);
        } catch (Exception ex) {
            throw new Exception('Error creating workflow: ' + ex.getMessage());
        }
    }
    
    public static void deleteValidationRule(String validationRuleId) {
        try {
            validateIdParameter(validationRuleId, 'Validation Rule Id');
            
            ValidationRule__c rule = getValidationRuleById(validationRuleId);
            
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            
            updateRecord(rule);
        } catch (Exception ex) {
            throw new Exception('Error deleting validation rule: ' + ex.getMessage());
        }
    }
    
    public static void deleteWorkflowTransition(String workflowTransitionId) {
        try {
            validateIdParameter(workflowTransitionId, 'Workflow Transition Id');
            
            WorkflowTransition__c transition = getTransitionById(workflowTransitionId);
            
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            
            updateRecord(transition);
        } catch (Exception ex) {
            throw new Exception('Error deleting workflow transition: ' + ex.getMessage());
        }
    }
    
    public static List<Status__c> getProjectStatusesWithValidation(String projectId) {
        try {
            validateIdParameter(projectId, 'Project Id');
            
            return getProjectStatuses(projectId);
        } catch (Exception ex) {
            throw new Exception('Error retrieving project statuses: ' + ex.getMessage());
        }
    }
    
    public static WorkflowTransition__c getWorkflowTransitionByIdWithValidation(String transitionId) {
        try {
            validateIdParameter(transitionId, 'Transition Id');
            
            return getTransitionById(transitionId);
        } catch (Exception ex) {
            throw new Exception('Error retrieving workflow transition: ' + ex.getMessage());
        }
    }
    
    public static WorkflowConfigDTO getWorkflow(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            Workflow__c workflow = getWorkflowWithTransitions(workflowId);
            
            WorkflowConfigDTO config = new WorkflowConfigDTO();
            
            config.workflow.id = workflow.Id;
            config.workflow.name = workflow.Name;
            
            if (workflow.WorkflowTransitions__r != null) {
                for (WorkflowTransition__c transition : workflow.WorkflowTransitions__r) {
                    WorkflowConfigDTO.TransitionInfo transInfo = new WorkflowConfigDTO.TransitionInfo();
                    transInfo.id = transition.Id;
                    transInfo.name = transition.Name;
                    transInfo.fromStatus = transition.FromStatus__c;
                    transInfo.toStatus = transition.ToStatus__c;
                    transInfo.recordStatus = transition.RecordStatus__c;
                    
                    config.workflow.transitions.add(transInfo);
                }
            }
            
            if (workflow.Project__c != null) {
                List<Status__c> projectStatuses = getProjectStatuses(workflow.Project__c);
                
                for (Status__c status : projectStatuses) {
                    WorkflowConfigDTO.StatusInfo statusInfo = new WorkflowConfigDTO.StatusInfo();
                    statusInfo.id = status.Id;
                    statusInfo.name = status.Name;
                    config.projectStatus.add(statusInfo);
                }
            }
            
            return config;
        } catch (Exception ex) {
            throw new Exception('Error retrieving workflow: ' + ex.getMessage());
        }
    }
    
    public static List<WorkflowTransition__c> loadWorkflowTransitions(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            return getTransitionsByWorkflow(workflowId);
        } catch (Exception ex) {
            throw new Exception('Error loading workflow transitions: ' + ex.getMessage());
        }
    }
    
    public static List<Workflow__c> loadWorkflows() {
        try {
            return getAllWorkflows();
        } catch (Exception ex) {
            throw new Exception('Error loading workflows: ' + ex.getMessage());
        }
    }
    
    public static void updateWorkflow(String workflowId) {
        try {
            validateIdParameter(workflowId, 'Workflow Id');
            
            getWorkflowById(workflowId);
            
            List<WorkflowTransition__c> pendingTransitions = getPendingTransitions(workflowId);
            
            List<ValidationRule__c> pendingRules = getPendingRules(workflowId);
            
            for (WorkflowTransition__c transition : pendingTransitions) {
                transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            }
            
            for (ValidationRule__c rule : pendingRules) {
                rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            }
            
            List<SObject> recordsToUpdate = new List<SObject>();
            recordsToUpdate.addAll(pendingTransitions);
            recordsToUpdate.addAll(pendingRules);
            
            updateRecords(recordsToUpdate);
        } catch (Exception ex) {
            throw new Exception('Error updating workflow: ' + ex.getMessage());
        }
    }
    
    // Private helper methods
    private static void validateIdParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new Exception(paramName + ' is required');
        }
    }
    
    private static void validateNameParameter(String value, String paramName) {
        if (String.isBlank(value)) {
            throw new Exception(paramName + ' is required');
        }
    }
}

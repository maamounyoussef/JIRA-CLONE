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
            throw new ServiceException('Workflow not found');
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
            throw new ServiceException('Workflow Transition not found');
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
            throw new ServiceException('Validation Rule not found');
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
            throw new ServiceException('Error creating workflow: ' + ex.getMessage());
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
            throw new ServiceException('Error inserting validation rule: ' + ex.getMessage());
        }
    }

    public static WorkflowTransition__c insertWorkflowTransition(WorkflowTransition__c transition) {
        try {
            insert transition;
            return transition;
        } catch (DmlException ex) {
            throw new ServiceException('Error inserting workflow transition: ' + ex.getMessage());
        }
    }

    public static void updateRecord(SObject record) {
        try {
            update record;
        } catch (DmlException ex) {
            throw new ServiceException('Error updating record: ' + ex.getMessage());
        }
    }

    public static void updateRecords(List<SObject> records) {
        try {
            update records;
        } catch (DmlException ex) {
            throw new ServiceException('Error updating records: ' + ex.getMessage());
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
            throw new ServiceException('Workflow Transition not found');
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
            throw new ServiceException('Error creating workflow transition: ' + ex.getMessage());
        }
    }

    // Use case methods
    public static void activateValidationRule(ValidationRule__c rule) {
        try {
            DomainCompleteValidator.requireValidationRuleIsPending(rule);
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            updateRecord(rule);
        } catch (Exception ex) {
            throw new ServiceException('Error activating validation rule: ' + ex.getMessage());
        }
    }

    public static void activateWorkflowTransition(WorkflowTransition__c transition) {
        try {
            DomainCompleteValidator.requireTransitionIsPending(transition);
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
            updateRecord(transition);
        } catch (Exception ex) {
            throw new ServiceException('Error activating workflow transition: ' + ex.getMessage());
        }
    }

    public static ValidationRule__c addValidationRule(WorkflowTransition__c transition, String ticketField, String validationType) {
        try {
            ValidationRule__c newRule = new ValidationRule__c();
            newRule.WorkflowTransition__c = transition.Id;
            newRule.TicketField__c = ticketField;
            newRule.Type__c = validationType;
            newRule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;

            return insertValidationRule(newRule);
        } catch (Exception ex) {
            throw new ServiceException('Error adding validation rule: ' + ex.getMessage());
        }
    }

    public static WorkflowTransition__c addWorkflowTransition(Workflow__c workflow, String name, Status__c fromStatus, Status__c toStatus) {
        try {
            DomainCompleteValidator.requireTransitionStatusesDifferent(fromStatus.Id, toStatus.Id);

            WorkflowTransition__c newTransition = new WorkflowTransition__c();
            newTransition.Workflow__c = workflow.Id;
            newTransition.Name = name;
            newTransition.FromStatus__c = fromStatus.Id;
            newTransition.ToStatus__c = toStatus.Id;
            newTransition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING;

            return insertWorkflowTransition(newTransition);
        } catch (Exception ex) {
            throw new ServiceException('Error adding workflow transition: ' + ex.getMessage());
        }
    }

    public static WorkflowTransition__c createWorkflowTransition(String name, Workflow__c workflow, Status__c fromStatus, Status__c toStatus, String recordStatus) {
        try {
            DomainCompleteValidator.requireTransitionStatusesDifferent(fromStatus.Id, toStatus.Id);

            return createTransition(name, workflow.Id, fromStatus.Id, toStatus.Id, recordStatus);
        } catch (Exception ex) {
            throw new ServiceException('Error creating workflow transition: ' + ex.getMessage());
        }
    }

    public static Workflow__c createWorkflowWithValidation(String name, String projectId) {
        try {
            return createWorkflow(name, projectId);
        } catch (Exception ex) {
            throw new ServiceException('Error creating workflow: ' + ex.getMessage());
        }
    }

    public static void deleteValidationRule(ValidationRule__c rule) {
        try {
            rule.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            updateRecord(rule);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting validation rule: ' + ex.getMessage());
        }
    }

    public static void deleteWorkflowTransition(WorkflowTransition__c transition) {
        try {
            transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_DELETED;
            updateRecord(transition);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting workflow transition: ' + ex.getMessage());
        }
    }

    public static WorkflowTransition__c getWorkflowTransitionByIdWithValidation(String transitionId) {
        try {
            return getTransitionById(transitionId);
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving workflow transition: ' + ex.getMessage());
        }
    }

    public static WorkflowConfigDTO getWorkflowConfig(Workflow__c workflow) {
        try {

            Workflow__c full = getWorkflowWithTransitions(workflow.Id);

            WorkflowConfigDTO config = new WorkflowConfigDTO();

            config.workflow.id = full.Id;
            config.workflow.name = full.Name;

            if (full.WorkflowTransitions__r != null) {
                for (WorkflowTransition__c transition : full.WorkflowTransitions__r) {
                    WorkflowConfigDTO.TransitionInfo transInfo = new WorkflowConfigDTO.TransitionInfo();
                    transInfo.id = transition.Id;
                    transInfo.name = transition.Name;
                    transInfo.fromStatus = transition.FromStatus__c;
                    transInfo.toStatus = transition.ToStatus__c;
                    transInfo.recordStatus = transition.RecordStatus__c;

                    config.workflow.transitions.add(transInfo);
                }
            }

            if (full.Project__c != null) {
                List<Status__c> projectStatuses = getProjectStatuses(full.Project__c);

                for (Status__c status : projectStatuses) {
                    WorkflowConfigDTO.StatusInfo statusInfo = new WorkflowConfigDTO.StatusInfo();
                    statusInfo.id = status.Id;
                    statusInfo.name = status.Name;
                    config.projectStatus.add(statusInfo);
                }
            }

            return config;
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving workflow: ' + ex.getMessage());
        }
    }

    public static List<WorkflowTransition__c> loadWorkflowTransitions(Workflow__c workflow) {
        try {
            return getTransitionsByWorkflow(workflow.Id);
        } catch (Exception ex) {
            throw new ServiceException('Error loading workflow transitions: ' + ex.getMessage());
        }
    }

    public static List<Workflow__c> loadWorkflows() {
        try {
            return getAllWorkflows();
        } catch (Exception ex) {
            throw new ServiceException('Error loading workflows: ' + ex.getMessage());
        }
    }

    public static void updateWorkflow(Workflow__c workflow) {
        try {
            List<WorkflowTransition__c> pendingTransitions = getPendingTransitions(workflow.Id);

            List<ValidationRule__c> pendingRules = getPendingRules(workflow.Id);

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
            throw new ServiceException('Error updating workflow: ' + ex.getMessage());
        }
    }

}

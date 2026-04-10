/**
 * @description Repository class for Workflow-related database operations
 * Handles all SOQL queries and DML operations for workflow objects
 */
public with sharing class WorkflowRepository {
    
    /**
     * @description Get workflow with all transitions and validation rules
     * @param workflowId - The Workflow__c record Id
     * @return Workflow__c with related transitions and their validation rules
     * @throws WorkflowException - If workflow not found
     */
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
                WHERE RecordStatus__c != 'Deleted'
                ORDER BY RecordStatus__c DESC, CreatedDate ASC
            )
        FROM Workflow__c 
        WHERE Id = :workflowId 
        LIMIT 1
    ];
    
    if (workflows.isEmpty()) {
        throw new WorkflowException('Workflow not found');
    }

    return workflows[0];
    // for now commit validation rules
//     Workflow__c workflow = workflows[0];

//     Set<Id> transitionIds = new Set<Id>();

//     for (WorkflowTransition__c transition : workflow.WorkflowTransitions__r) {
//         transitionIds.add(transition.Id);
//     }

//     Map<Id, List<ValidationRule__c>> validationRulesByTransitionId = new Map<Id, List<ValidationRule__c>>();

//     if (!transitionIds.isEmpty()) {
//         List<ValidationRule__c> validationRules = [
//             SELECT 
//                 Id, 
//                 TicketField__c, 
//                 Type__c, 
//                 RecordStatus__c,
//                 WorkflowTransition__c
//             FROM ValidationRule__c
//             WHERE WorkflowTransition__c IN :transitionIds
//             ORDER BY RecordStatus__c DESC, CreatedDate ASC
//         ];

//         for (ValidationRule__c rule : validationRules) {
//             if (!validationRulesByTransitionId.containsKey(rule.WorkflowTransition__c)) {
//                 validationRulesByTransitionId.put(rule.WorkflowTransition__c, new List<ValidationRule__c>());
//             }

//             validationRulesByTransitionId.get(rule.WorkflowTransition__c).add(rule);
//         }
//     }

// for (WorkflowTransition__c transition : workflow.WorkflowTransitions__r) {
//     if (validationRulesByTransitionId.containsKey(transition.Id)) {
//         transition.put(
//             'ValidationRules__r',
//             validationRulesByTransitionId.get(transition.Id)
//         );
//     } else {
//         transition.put(
//             'ValidationRules__r',
//             new List<ValidationRule__c>()
//         );
//     }
// }

//     return workflow;
}
    
    /**
     * @description Get workflow by Id
     * @param workflowId - The Workflow__c record Id
     * @return Workflow__c record
     * @throws WorkflowException - If workflow not found
     */
    public static Workflow__c getWorkflow(String workflowId) {
        List<Workflow__c> workflows = [
            SELECT Id, Name, Project__c
            FROM Workflow__c 
            WHERE Id = :workflowId 
            LIMIT 1
        ];
        
        if (workflows.isEmpty()) {
            throw new WorkflowException('Workflow not found');
        }
        
        return workflows[0];
    }
    
    /**
     * @description Get workflow by Id
     * @param workflowId - The Workflow__c record Id
     * @return Workflow__c record
     * @throws WorkflowException - If workflow not found
     */
    public static Workflow__c getWorkflowById(String workflowId) {
        List<Workflow__c> workflows = [
            SELECT Id, Name, Project__c
            FROM Workflow__c 
            WHERE Id = :workflowId 
            LIMIT 1
        ];
        
        if (workflows.isEmpty()) {
            throw new WorkflowException('Workflow not found');
        }
        
        return workflows[0];
    }
    
    /**
     * @description Get workflow transition by Id
     * @param transitionId - The WorkflowTransition__c record Id
     * @return WorkflowTransition__c record
     * @throws WorkflowException - If transition not found
     */
    public static WorkflowTransition__c getWorkflowTransitionById(String transitionId) {
        List<WorkflowTransition__c> transitions = [
            SELECT Id, Workflow__c 
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
     * @description Get validation rule by Id
     * @param ruleId - The ValidationRule__c record Id
     * @return ValidationRule__c record
     * @throws WorkflowException - If rule not found
     */
    public static ValidationRule__c getValidationRuleById(String ruleId) {
        List<ValidationRule__c> rules = [
            SELECT Id, RecordStatus__c, WorkflowTransition__c
            FROM ValidationRule__c 
            WHERE Id = :ruleId 
            LIMIT 1
        ];
        
        if (rules.isEmpty()) {
            throw new WorkflowException('Validation Rule not found');
        }
        
        return rules[0];
    }
    
    /**
     * @description Get statuses by Ids
     * @param statusIds - List of Status__c record Ids
     * @return List of Status__c records
     */
    public static List<Status__c> getStatusesById(List<String> statusIds) {
        return [
            SELECT Id 
            FROM Status__c 
            WHERE Id IN :statusIds
        ];
    }
    
    /**
     * @description Get all statuses for a project
     * @param projectId - The Project__c record Id
     * @return List of Status__c records for the project
     */
    public static List<Status__c> getProjectStatuses(String projectId) {
        return [
            SELECT Id, Name, Project__c
            FROM Status__c 
            WHERE Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Get all workflows
     * @return List of all Workflow__c records
     */
    public static List<Workflow__c> getAllWorkflows() {
        return [
            SELECT Id, Name, Project__c
            FROM Workflow__c
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Create a new workflow
     * @param name - The workflow name
     * @param projectId - The Project__c record Id
     * @return The created Workflow__c record
     * @throws WorkflowException - If DML exception occurs
     */
    public static Workflow__c createWorkflow(String name, String projectId) {
        try {
            Workflow__c workflow = new Workflow__c(
                Name = name,
                Project__c = projectId
            );
            insert workflow;
            return workflow;
        } catch (DmlException ex) {
            throw new WorkflowException('Error creating workflow: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Get all pending transitions for a workflow
     * @param workflowId - The Workflow__c record Id
     * @return List of pending WorkflowTransition__c records
     */
    public static List<WorkflowTransition__c> getPendingTransitions(String workflowId) {
        return [
            SELECT Id, RecordStatus__c 
            FROM WorkflowTransition__c 
            WHERE Workflow__c = :workflowId 
              AND RecordStatus__c = :WorkflowConstants.RECORD_STATUS_PENDING
        ];
    }
    
    /**
     * @description Get all pending validation rules for a workflow's transitions
     * @param workflowId - The Workflow__c record Id
     * @return List of pending ValidationRule__c records
     */
    public static List<ValidationRule__c> getPendingRules(String workflowId) {
        return [
            SELECT Id, RecordStatus__c 
            FROM ValidationRule__c 
            WHERE WorkflowTransition__c IN (
                SELECT Id FROM WorkflowTransition__c WHERE Workflow__c = :workflowId
            )
              AND RecordStatus__c = :WorkflowConstants.RECORD_STATUS_PENDING
        ];
    }
    
    /**
     * @description Insert a new validation rule
     * @param rule - The ValidationRule__c record to insert
     * @return The inserted ValidationRule__c record
     * @throws WorkflowException - If DML exception occurs
     */
    public static ValidationRule__c insertValidationRule(ValidationRule__c rule) {
        try {
            insert rule;
            return rule;
        } catch (DmlException ex) {
            throw new WorkflowException('Error inserting validation rule: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Insert a new workflow transition
     * @param transition - The WorkflowTransition__c record to insert
     * @return The inserted WorkflowTransition__c record
     * @throws WorkflowException - If DML exception occurs
     */
    public static WorkflowTransition__c insertWorkflowTransition(WorkflowTransition__c transition) {
        try {
            insert transition;
            return transition;
        } catch (DmlException ex) {
            throw new WorkflowException('Error inserting workflow transition: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Update a single SObject
     * @param record - The SObject to update
     * @throws WorkflowException - If DML exception occurs
     */
    public static void updateRecord(SObject record) {
        try {
            update record;
        } catch (DmlException ex) {
            throw new WorkflowException('Error updating record: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Bulk update multiple SObjects
     * @param records - List of SObjects to update
     * @throws WorkflowException - If DML exception occurs
     */
    public static void updateRecords(List<SObject> records) {
        if (records.isEmpty()) {
            return;
        }
        
        try {
            update records;
        } catch (DmlException ex) {
            throw new WorkflowException('Error updating records: ' + ex.getMessage());
        }
    }
}

/**
 * @description Use Case for retrieving a Workflow with all transitions and validation rules
 * Single responsibility: Retrieve workflow configuration
 */
public with sharing class GetWorkflowUseCase {
    
    /**
     * @description Execute the use case to get workflow configuration
     * @param workflowId - The Workflow__c record Id
     * @return WorkflowConfigDTO containing workflow configuration data
     * @throws WorkflowException - If workflow not found or other errors occur
     */
    public static WorkflowConfigDTO execute(String workflowId) {
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

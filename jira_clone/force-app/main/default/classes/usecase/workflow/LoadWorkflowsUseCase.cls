/**
 * @description Use Case for loading all workflows
 * Single responsibility: Retrieve all workflow records
 */
public with sharing class LoadWorkflowsUseCase {
    
    /**
     * @description Execute the use case to load all workflows
     * @return List of Workflow__c objects
     * @throws WorkflowException - If error occurs
     */
    public static List<Workflow__c> execute() {
        try {
            return WorkflowRepository.getAllWorkflows();
        } catch (WorkflowException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new WorkflowException('Error loading workflows: ' + ex.getMessage());
        }
    }
}

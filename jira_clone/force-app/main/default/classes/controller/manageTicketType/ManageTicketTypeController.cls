/**
 * @description Controller for the ticketType LWC.
 * Thin AuraEnabled methods that delegate to TicketService / WorkflowService
 * and return APIResponse.
 */
public with sharing class ManageTicketTypeController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadAllProjects() {
        try {
            List<Project__c> projects = ProjectService.loadProjects();
            return new APIResponse(true, 'Projects loaded', projects);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading projects: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketTypesByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<TicketType__c> types = TicketService.loadTicketTypes(project);
            return new APIResponse(true, 'Ticket types loaded', types);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading ticket types: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadWorkflowsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            DomainCorrectness.requireProjectExists(projectId);
            List<Workflow__c> workflows = WorkflowService.loadWorkflowsByProject(projectId);
            return new APIResponse(true, 'Workflows loaded', workflows);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading workflows: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            if (String.isBlank(name))        return new APIResponse(false, 'name is required');
            if (String.isBlank(workflowId))  return new APIResponse(false, 'workflowId is required');
            if (String.isBlank(projectId))   return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireProjectExists(projectId);
            DomainCorrectness.requireWorkflowExists(workflowId);
            DomainCorrectness.requireWorkflowBelongsToProject(workflowId, projectId);

            TicketType__c created = TicketService.createTicketType(name, description, iconUrl, workflowId, projectId);
            List<TicketType__c> rows = [
                SELECT Id, Name, Description__c, IconUrl__c, Project__c, RecordStatus__c,
                       Workflow__c, Workflow__r.Name
                FROM TicketType__c
                WHERE Id = :created.Id
                  AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            return new APIResponse(true, 'Ticket type created', rows.isEmpty() ? created : rows[0]);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketType(String ticketTypeId, String name, String iconUrl, String workflowId) {
        try {
            if (String.isBlank(ticketTypeId)) return new APIResponse(false, 'ticketTypeId is required');
            if (String.isBlank(name))         return new APIResponse(false, 'name is required');
            if (String.isBlank(workflowId))   return new APIResponse(false, 'workflowId is required');

            TicketType__c existing = DomainCorrectness.requireTicketTypeExists(ticketTypeId);
            DomainCorrectness.requireWorkflowExists(workflowId);
            DomainCorrectness.requireWorkflowBelongsToProject(workflowId, existing.Project__c);

            TicketType__c updated = TicketService.updateTicketType(ticketTypeId, name, iconUrl, workflowId);
            return new APIResponse(true, 'Ticket type updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTicketType(String ticketTypeId) {
        try {
            if (String.isBlank(ticketTypeId)) return new APIResponse(false, 'ticketTypeId is required');

            TicketType__c existing = DomainCorrectness.requireTicketTypeExists(ticketTypeId);
            TicketService.deleteTicketType(existing);
            return new APIResponse(true, 'Ticket type deleted', existing.Id);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting ticket type: ' + ex.getMessage());
        }
    }
}

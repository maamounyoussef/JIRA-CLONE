/**
 * @description Aggregation endpoint for Manage Ticket Tracking (Board) page
 */
public with sharing class ManageTicketTrackingController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadManageTicketTrackingPage(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            Project__c project = DomainCorrectness.requireProjectExists(projectId);

            List<Status__c>             statuses     = StatusService.loadStatuses(project);
            List<WorkflowTransition__c> workflows    = WorkflowService.loadWorkflowDfa(projectId);
            List<ProjectMember__c>      members      = ProjectService.loadProjectMembers(project);
            List<TicketType__c>         ticketTypes  = TicketService.loadTicketTypes(project);
            Sprint__c                   sprint       = SprintService.loadActiveSprint(projectId);

            List<Ticket__c> sprintTickets = sprint != null
                ? TicketService.loadActiveTicketsBySprint(sprint)
                : new List<Ticket__c>();

            Map<String, Object> data = new Map<String, Object>{
                'status'         => statuses,
                'workflows'      => workflows,
                'sprint_tickets' => sprintTickets,
                'members'        => members,
                'ticketTypes'    => ticketTypes,
                'sprint'         => sprint
            };

            return new APIResponse(true, 'Manage ticket tracking page loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading page: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse changeTicketState(String ticketId, String toStatusId, String workflowId, String workflowTransitionId) {
        try {
            if (String.isBlank(ticketId))   return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(toStatusId)) return new APIResponse(false, 'toStatusId is required');

            Ticket__c             ticket     = DomainCorrectness.requireTicketExists(ticketId);
            TicketType__c         ticketType = DomainCorrectness.requireTicketTypeExists(ticket.Ticket_Type__c);
            WorkflowTransition__c transition = DomainCorrectness.requireTransitionExists(workflowTransitionId);

            WorkflowService.changeTicketState(ticket, ticketType, toStatusId, workflowId, transition);

            return new APIResponse(true, 'Ticket state changed successfully');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error changing ticket state: ' + ex.getMessage());
        }
    }
}

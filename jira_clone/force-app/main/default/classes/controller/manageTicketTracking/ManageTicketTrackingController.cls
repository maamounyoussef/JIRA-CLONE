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
                'status'              => statuses,
                'workflows'           => workflows,
                'sprint_tickets'      => sprintTickets,
                'members'             => members,
                'ticketTypes'         => ticketTypes,
                'sprint'              => sprint
            };

            return new APIResponse(true, 'Manage ticket tracking page loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading page: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketLinkedTo(String ticketId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');

            DomainCorrectness.requireTicketExists(ticketId);

            List<TicketLinkToDto> links = TicketService.getTicketLinkedTo(ticketId);

            Map<String, Object> data = new Map<String, Object>{
                'ticketLinkTo' => links
            };

            return new APIResponse(true, 'Linked tickets loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading linked tickets: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketLinkTypes(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireProjectExists(projectId);

            List<Map<String, String>> ticketLinkTypes = TicketService.getTicketLinkTypes();

            Map<String, Object> data = new Map<String, Object>{
                'ticketLinkTypes' => ticketLinkTypes
            };

            return new APIResponse(true, 'Ticket link types loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading ticket link types: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicketLink(String fromTicketId, String toTicketId, String linkType) {
        try {
            if (String.isBlank(fromTicketId)) return new APIResponse(false, 'fromTicketId is required');
            if (String.isBlank(toTicketId))   return new APIResponse(false, 'toTicketId is required');
            if (String.isBlank(linkType))     return new APIResponse(false, 'linkType is required');

            DomainCorrectness.requireTicketExists(fromTicketId);
            DomainCorrectness.requireTicketExists(toTicketId);

            TicketService.createTicketLink(fromTicketId, toTicketId, linkType);

            return new APIResponse(true, 'Ticket link created');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket link: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse changeTicketState(String ticketId, String fromStatusId, String toStatusId) {
        try {
            if (String.isBlank(ticketId))     return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(fromStatusId)) return new APIResponse(false, 'fromStatusId is required');
            if (String.isBlank(toStatusId))   return new APIResponse(false, 'toStatusId is required');

            Ticket__c     ticket     = DomainCorrectness.requireTicketExists(ticketId);
            TicketType__c ticketType = DomainCorrectness.requireTicketTypeExists(ticket.Ticket_Type__c);
            Workflow__c   workflow   = DomainCorrectness.requireWorkflowExists(ticketType.Workflow__c);
            Status__c     fromStatus = DomainCorrectness.requireStatusExists(fromStatusId);
            Status__c     toStatus   = DomainCorrectness.requireStatusExists(toStatusId);

            List<WorkflowTransition__c> transitions = WorkflowService.getTransitionsByWorkflow(workflow.Id);

            Boolean isEndStatus = TicketService.changeTicketState(ticket, fromStatus, toStatus, transitions);

            Map<String, Object> data = new Map<String, Object>{
                'isEndStatus' => isEndStatus
            };

            return new APIResponse(true, 'Ticket state changed successfully', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error changing ticket state: ' + ex.getMessage());
        }
    }
}

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

            // Group already-loaded workflow transitions by workflow ID
            Map<String, List<WorkflowTransition__c>> transitionsByWorkflow = new Map<String, List<WorkflowTransition__c>>();
            for (WorkflowTransition__c wt : workflows) {
                if (!transitionsByWorkflow.containsKey(wt.Workflow__c)) {
                    transitionsByWorkflow.put(wt.Workflow__c, new List<WorkflowTransition__c>());
                }
                transitionsByWorkflow.get(wt.Workflow__c).add(wt);
            }

            // Build ticketTypeId -> workflowId map from already-loaded ticketTypes
            Map<String, String> ticketTypeWorkflowMap = new Map<String, String>();
            for (TicketType__c tt : ticketTypes) {
                if (tt.Workflow__c != null) {
                    ticketTypeWorkflowMap.put(tt.Id, tt.Workflow__c);
                }
            }

            // Find the end status for each workflow
            Map<String, String> workflowEndStatusMap = new Map<String, String>();
            for (String wfId : transitionsByWorkflow.keySet()) {
                String endStatusId = WorkflowService.foundEndStatus(transitionsByWorkflow.get(wfId));
                if (endStatusId != null) {
                    workflowEndStatusMap.put(wfId, endStatusId);
                }
            }

            // Collect IDs of sprint tickets currently at their workflow's end status
            Set<String> ticketsAtEndStatus = new Set<String>();
            for (Ticket__c t : sprintTickets) {
                String wfId      = ticketTypeWorkflowMap.get(t.Ticket_Type__c);
                String endStatus = wfId != null ? workflowEndStatusMap.get(wfId) : null;
                if (endStatus != null && endStatus == t.CurrentState__c) {
                    ticketsAtEndStatus.add(t.Id);
                }
            }

            Map<String, Object> data = new Map<String, Object>{
                'status'              => statuses,
                'workflows'           => workflows,
                'sprint_tickets'      => sprintTickets,
                'members'             => members,
                'ticketTypes'         => ticketTypes,
                'sprint'              => sprint,
                'ticketsAtEndStatus'  => ticketsAtEndStatus
            };

            return new APIResponse(true, 'Manage ticket tracking page loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading page: ' + ex.getMessage());
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

            List<WorkflowTransition__c> transitions = WorkflowService.getTransitionsByWorkflow(workflow.Id);

            Boolean isEndStatus = TicketService.changeTicketState(ticket, fromStatusId, toStatusId, transitions);

            Map<String, Object> data = new Map<String, Object>{
                'isEndStatus' => isEndStatus
            };

            return new APIResponse(true, 'Ticket state changed successfully', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error changing ticket state: ' + ex.getMessage());
        }
    }
}

/**
 * @description Aggregation endpoint for Manage Ticket Tracking (Board) page
 */
public with sharing class ManageTicketTrackingController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadManageTicketTrackingPage(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            // InputSecurityValidator.validatePageAccessManageTicketTracking(projectId);

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
    public static APIResponse linkToTicket(String fromTicketId, String toTicketId, String linkType) {
        try {
            if (String.isBlank(fromTicketId)) return new APIResponse(false, 'fromTicketId is required');
            if (String.isBlank(toTicketId))   return new APIResponse(false, 'toTicketId is required');
            if (String.isBlank(linkType))     return new APIResponse(false, 'linkType is required');

            Ticket__c     fromTicket     = DomainCorrectness.requireTicketExists(fromTicketId);
            Ticket__c     toTicket       = DomainCorrectness.requireTicketExists(toTicketId);
            TicketType__c fromTicketType = DomainCorrectness.requireTicketTypeExists(fromTicket.Ticket_Type__c);
            TicketType__c toTicketType   = DomainCorrectness.requireTicketTypeExists(toTicket.Ticket_Type__c);

            TicketLinkToDto link = TicketService.linkToTicket(fromTicket, toTicket, fromTicketType, toTicketType, linkType);

            Map<String, Object> data = new Map<String, Object>{
                'ticketLink' => link
            };

            return new APIResponse(true, 'Ticket linked successfully', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error linking ticket: ' + ex.getMessage());
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

            ChangeTicketStateDto result = TicketService.changeTicketState(ticket, fromStatus, toStatus, transitions);

            Map<String, Object> data = new Map<String, Object>{
                'isEndStatus' => result.isEndStatus,
                'updatedSprint' => result.updatedSprint
            };

            return new APIResponse(true, 'Ticket state changed successfully', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error changing ticket state: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketSummary(String ticketId, String summary) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(summary))  return new APIResponse(false, 'summary is required');

            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            Ticket__c updated  = TicketService.updateTicketSummary(existing, summary);

            return new APIResponse(true, 'Ticket summary updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketDescription(String ticketId, String description) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');

            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            Ticket__c updated  = TicketService.updateTicketDescription(existing, description);

            return new APIResponse(true, 'Ticket description updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket description: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketBySearchTerm(String projectId, String searchTerm) {
        try {
            if (String.isBlank(projectId))  return new APIResponse(false, 'projectId is required');
            if (String.isBlank(searchTerm)) return new APIResponse(false, 'searchTerm is required');

            Project__c project = DomainCorrectness.requireProjectExists(projectId);

            List<TicketType__c> types = [SELECT Id FROM TicketType__c WHERE Project__c = :project.Id];
            if (types.isEmpty()) {
                return new APIResponse(true, 'Tickets loaded', new List<Ticket__c>());
            }
            List<Id> typeIds = new List<Id>();
            for (TicketType__c t : types) typeIds.add(t.Id);

            // Escape special SOSL characters
            String sanitized = searchTerm
                .replace('\\', '\\\\')
                .replace('"', '\\"')
                .replace('?', '\\?')
                .replace('&', '\\&')
                .replace('|', '\\|')
                .replace('!', '\\!')
                .replace('{', '\\{')
                .replace('}', '\\}')
                .replace('[', '\\[')
                .replace(']', '\\]')
                .replace('(', '\\(')
                .replace(')', '\\)')
                .replace('^', '\\^')
                .replace('~', '\\~')
                .replace('*', '\\*')
                .replace(':', '\\:')
                .replace('\'', '\\\'');

            // SOSL search across Name and Summary fields
            String typeIdSet = '(\'' + String.join(typeIds, '\',\'') + '\')';

            String soslQuery = 'FIND {*' + sanitized + '*} IN ALL FIELDS ' +
                            'RETURNING Ticket__c(' +
                            'Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c, ' +
                            'AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c, ' +
                            'StartDate__c, EndDate__c ' +
                            'WHERE (Name LIKE \'%' + sanitized + '%\' OR Summary__c LIKE \'%' + sanitized + '%\') ' +
                            'AND Ticket_Type__c IN ' + typeIdSet + ' ' +
                            'AND RecordStatus__c = \'active\' ' +
                            'ORDER BY Name ASC LIMIT 2000)';

            List<List<SObject>> searchResults = Search.query(soslQuery);
            List<Ticket__c> tickets = (List<Ticket__c>) searchResults[0];

            return new APIResponse(true, 'Tickets loaded', tickets);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading tickets: ' + ex.getMessage());
        }
    }

    // ========== Subtask Controller Actions ==========
    // Mirrored from ManageBacklogController so the ticket-tracking page has its
    // own subtask endpoints (load on expand, create from the detail panel).

    @AuraEnabled(cacheable=true)
    public static APIResponse loadSubtasks(String ticketId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            Ticket__c ticket = DomainCorrectness.requireTicketExists(ticketId);
            List<Subtask__c> subs = TicketService.getSubtasksByTicket(ticket);
            return new APIResponse(true, 'Subtasks loaded', subs);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading subtasks: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createSubtask(String summary, String ticketId, String description, String assigneeId, String currentStateId, Integer storyPoint, DateTime startDate) {
        try {
            if (String.isBlank(summary))  return new APIResponse(false, 'summary is required');
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');

            Ticket__c ticket = DomainCorrectness.requireTicketExists(ticketId);
            DomainCorrectness.requireOptionalProjectMemberActive(assigneeId);
            DomainCorrectness.requireOptionalStatusExists(currentStateId);

            Subtask__c subtask = new Subtask__c();
            subtask.Summary__c = summary;
            subtask.Ticket__c = ticket.Id;
            if (String.isNotBlank(description))    subtask.Description__c  = description;
            if (String.isNotBlank(assigneeId))     subtask.Assignee__c     = assigneeId;
            if (String.isNotBlank(currentStateId)) subtask.CurrentState__c = currentStateId;
            if (storyPoint != null)                subtask.StoryPoint__c   = storyPoint;
            if (startDate != null)                 subtask.StartDate__c    = startDate;

            Subtask__c created = TicketService.createSubtask(subtask);
            return new APIResponse(true, 'Subtask created', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating subtask: ' + ex.getMessage());
        }
    }
}

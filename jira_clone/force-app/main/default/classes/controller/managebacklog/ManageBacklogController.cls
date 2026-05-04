/**
 * @description Aggregation endpoint for Manage Backlog page
 * Returns tickets, sprints, statuses, members and epics for a given project
 */
public with sharing class ManageBacklogController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadBacklogData(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            Project__c project = DomainCorrectness.requireProjectExists(projectId);

            List<Sprint__c> sprints = SprintService.loadUncompleteSprintsByProject(project);

            List<Status__c> statuses = StatusService.loadStatuses(project);
            List<TicketType__c> ticketTypes = TicketService.loadTicketTypes(project);
            List<ProjectMember__c> members = ProjectService.loadProjectMembers(project);
            List<Epic__c> epics = EpicService.getEpicsByProject(project);
            List<Ticket__c> backlogTickets = TicketService.loadBacklogTickets(project, 0, null);

            List<Map<String, String>> priorityOptions = new List<Map<String, String>>();
            priorityOptions.add(new Map<String, String>{ 'label' => '—', 'value' => '' });
            for (Schema.PicklistEntry e : Ticket__c.Priority__c.getDescribe().getPicklistValues()) {
                if (e.isActive()) {
                    priorityOptions.add(new Map<String, String>{ 'label' => e.getLabel(), 'value' => e.getValue() });
                }
            }

            Map<String, Object> data = new Map<String, Object>{
                'sprints'         => sprints,
                'status'          => statuses,
                'ticketTypes'     => ticketTypes,
                'members'         => members,
                'epics'           => epics,
                'backlogTickets'  => backlogTickets,
                'priorityOptions' => priorityOptions
            };

            return new APIResponse(true, 'Backlog data loaded', data);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading backlog data: ' + ex.getMessage());
        }
    }

    // ========== Project Actions ==========

    @AuraEnabled(cacheable=true)
    public static APIResponse loadProjects() {
        try {
            List<Project__c> projects = ProjectService.loadProjects();
            return new APIResponse(true, 'Projects loaded successfully', projects);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading projects: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectStatuses(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<Status__c> statuses = StatusService.loadStatuses(project);
            return new APIResponse(true, 'Project statuses retrieved successfully', statuses);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project statuses: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createProject(String name) {
        try {
            if (String.isBlank(name)) {
                return new APIResponse(false, 'name is required');
            }
            Project__c created = ProjectService.createProject(name);
            return new APIResponse(true, 'Project created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project: ' + ex.getMessage());
        }
    }

    // ========== Epic Actions ==========

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<Epic__c> epics = EpicService.getEpicsByProject(project);
            return new APIResponse(true, 'Epics retrieved successfully', epics);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epics: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicById(String epicId) {
        try {
            if (String.isBlank(epicId)) return new APIResponse(false, 'epicId is required');
            Epic__c epic = DomainCorrectness.requireEpicExists(epicId);
            return new APIResponse(true, 'Epic retrieved successfully', epic);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createEpic(String name, String summary, String projectId, String description, DateTime startDate, DateTime endDate) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(summary)) return new APIResponse(false, 'summary is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireProjectExists(projectId);

            Epic__c epic = new Epic__c();
            epic.Name = name;
            epic.Summary__c = summary;
            epic.Project__c = projectId;
            if (String.isNotBlank(description)) epic.Description__c = description;
            if (startDate != null) epic.StartDate__c = startDate;
            if (endDate != null) epic.EndDate__c = endDate;

            Epic__c created = EpicService.createEpicWithValidation(epic);
            return new APIResponse(true, 'Epic created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateEpic(String epicId, String name, String summary, String description, DateTime startDate, DateTime endDate) {
        try {
            if (String.isBlank(epicId)) return new APIResponse(false, 'epicId is required');

            Epic__c existing = DomainCorrectness.requireEpicExists(epicId);

            if (String.isNotBlank(name)) existing.Name = name;
            if (String.isNotBlank(summary)) existing.Summary__c = summary;
            if (String.isNotBlank(description)) existing.Description__c = description;
            if (startDate != null) existing.StartDate__c = startDate;
            if (endDate != null) existing.EndDate__c = endDate;

            Epic__c updated = EpicService.updateEpic(existing);
            return new APIResponse(true, 'Epic updated successfully', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createSprint(String name, Integer duration, Date startDate, String goal, String projectId) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            if (duration == null) return new APIResponse(false, 'duration is required');
            if (String.isBlank(goal)) return new APIResponse(false, 'goal is required');

            DomainCorrectness.requireProjectExists(projectId);

            Sprint__c sprint = new Sprint__c();
            sprint.Name = name;
            sprint.Project__c = projectId;
            sprint.Duration__c = duration;
            sprint.StartDate__c = startDate;
            sprint.Goal__c = goal;
            sprint.RecordStatus__c = 'future';

            Sprint__c created = SprintService.createSprint(sprint);
            return new APIResponse(true, 'Sprint created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSprint(String sprintId, String name, Integer duration, Date startDate, String goal) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');

            Sprint__c existing = DomainCorrectness.requireSprintExists(sprintId);

            if (String.isNotBlank(name)) existing.Name = name;
            if (duration != null) existing.Duration__c = duration;
            if (startDate != null) existing.StartDate__c = startDate;
            if (String.isNotBlank(goal)) existing.Goal__c = goal;

            Sprint__c updated = SprintService.updateSprint(existing);
            return new APIResponse(true, 'Sprint updated successfully', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse completeSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            Sprint__c sprint = DomainCorrectness.requireSprintExists(sprintId);
            SprintService.completeSprint(sprint);
            return new APIResponse(true, 'Sprint completed');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error completing sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            Sprint__c sprint = DomainCorrectness.requireSprintExists(sprintId);
            SprintService.deleteSprint(sprint);
            return new APIResponse(true, 'Sprint deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse startSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            Sprint__c sprint = DomainCorrectness.requireSprintExists(sprintId);
            SprintService.startSprint(sprint);
            return new APIResponse(true, 'Sprint started');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error starting sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadBacklogTickets(String projectId, Integer offset, Integer pageSize) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<Ticket__c> tickets = TicketService.loadBacklogTickets(project, offset, pageSize);
            return new APIResponse(true, 'Backlog tickets loaded', tickets);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading backlog tickets: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketsBySprint(String sprintId, Integer offset, Integer pageSize) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            Sprint__c sprint = DomainCorrectness.requireSprintExists(sprintId);
            List<Ticket__c> tickets = TicketService.getActiveTicketsBySprintOrderByPriorityAsc(sprint, offset, pageSize);
            return new APIResponse(true, 'Tickets loaded', tickets);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading tickets by sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketTypes(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<TicketType__c> ticketTypes = TicketService.loadTicketTypes(project);
            return new APIResponse(true, 'Ticket Types loaded successfully', ticketTypes);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading ticket types: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeById(String ticketTypeId) {
        try {
            if (String.isBlank(ticketTypeId)) return new APIResponse(false, 'ticketTypeId is required');
            TicketType__c ticketType = DomainCorrectness.requireTicketTypeExists(ticketTypeId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(description)) return new APIResponse(false, 'description is required');
            if (String.isBlank(iconUrl)) return new APIResponse(false, 'iconUrl is required');
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireProjectExists(projectId);
            DomainCorrectness.requireWorkflowBelongsToProject(workflowId, projectId);

            TicketType__c created = TicketService.createTicketType(name, description, iconUrl, workflowId, projectId);
            return new APIResponse(true, 'Ticket Type created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicket(String name, String summary, String ticketTypeId, String currentStateId, String description, Integer storyPoint, String assignedToId, String epicId, String sprintId, String priority) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(summary)) return new APIResponse(false, 'summary is required');
            if (String.isBlank(ticketTypeId)) return new APIResponse(false, 'ticketTypeId is required');

            DomainCorrectness.requireTicketTypeExists(ticketTypeId);
            DomainCorrectness.requireOptionalProjectMemberActive(assignedToId);
            DomainCorrectness.requireOptionalEpicActive(epicId);
            DomainCorrectness.requireOptionalSprintExists(sprintId);

            Ticket__c ticket = new Ticket__c();
            ticket.Name = name;
            ticket.Summary__c = summary;
            ticket.Ticket_Type__c = ticketTypeId;
            if (description != null) ticket.Description__c = description;
            if (storyPoint != null) ticket.StoryPoint__c = storyPoint;
            if (String.isNotBlank(assignedToId)) ticket.AssignedTo__c = assignedToId;
            if (String.isNotBlank(epicId)) ticket.Epic__c = epicId;
            if (String.isNotBlank(sprintId)) ticket.Sprint__c = sprintId;
            if (String.isNotBlank(priority)) ticket.Priority__c = priority;

            Ticket__c created = TicketService.createTicket(ticket);
            return new APIResponse(true, 'Ticket created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicket(String ticketId, String summary, String description, Integer storyPoint, String priority, String assignedToId, String currentStateId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');

            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);

            if (String.isNotBlank(summary)) existing.Summary__c = summary;
            if (String.isNotBlank(description)) existing.Description__c = description;
            if (storyPoint != null) existing.StoryPoint__c = storyPoint;
            if (String.isNotBlank(priority)) existing.Priority__c = priority;
            if (String.isNotBlank(assignedToId)) existing.AssignedTo__c = assignedToId;
            if (String.isNotBlank(currentStateId)) existing.CurrentState__c = currentStateId;

            Ticket__c updated = TicketService.updateTicket(existing);
            return new APIResponse(true, 'Ticket updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketSummary(String ticketId, String summary) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(summary)) return new APIResponse(false, 'summary is required');
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            Ticket__c updated = TicketService.updateTicketSummary(existing, summary);
            return new APIResponse(true, 'Ticket summary updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketPriority(String ticketId, String priority) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(priority)) return new APIResponse(false, 'priority is required');
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            Ticket__c updated = TicketService.updateTicketPriority(existing, priority);
            return new APIResponse(true, 'Ticket priority updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket priority: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse assignTicket(String ticketId, String memberId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(memberId)) return new APIResponse(false, 'memberId is required');
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            DomainCorrectness.requireProjectMemberActive(memberId);
            Ticket__c updated = TicketService.assignTicket(existing, memberId);
            return new APIResponse(true, 'Ticket assignee updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning ticket: ' + ex.getMessage());
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

    @AuraEnabled
    public static APIResponse moveTicketToSprint(String ticketId, String sprintId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            if (String.isBlank(sprintId))  return new APIResponse(false, 'sprintId is required');
            DomainCorrectness.requireSprintExists(sprintId);
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            existing.Sprint__c = sprintId;
            Ticket__c updated = TicketService.updateTicket(existing);
            return new APIResponse(true, 'Ticket moved to sprint', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error moving ticket to sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse moveTicketToBacklog(String ticketId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            existing.Sprint__c = null;
            Ticket__c updated = TicketService.updateTicket(existing);
            return new APIResponse(true, 'Ticket moved to backlog', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error moving ticket to backlog: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTicket(String ticketId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);
            TicketService.deleteTicket(existing);
            return new APIResponse(true, 'Ticket deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTickets(List<String> ticketIds) {
        try {
            if (ticketIds == null || ticketIds.isEmpty()) return new APIResponse(false, 'ticketIds are required');
            TicketService.deleteTickets(ticketIds);
            return new APIResponse(true, 'Tickets deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting tickets: ' + ex.getMessage());
        }
    }

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

    // ========== Subtask Controller Actions ==========

    @AuraEnabled
    public static APIResponse createSubtask(String summary, String ticketId, String description, String assigneeId, String currentStateId, Integer storyPoint, DateTime startDate) {
        try {
            if (String.isBlank(summary)) return new APIResponse(false, 'summary is required');
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');

            Ticket__c ticket = DomainCorrectness.requireTicketExists(ticketId);
            DomainCorrectness.requireOptionalProjectMemberActive(assigneeId);
            DomainCorrectness.requireOptionalStatusExists(currentStateId);

            Subtask__c subtask = new Subtask__c();
            subtask.Summary__c = summary;
            subtask.Ticket__c = ticket.Id;
            if (String.isNotBlank(description)) subtask.Description__c = description;
            if (String.isNotBlank(assigneeId)) subtask.Assignee__c = assigneeId;
            if (String.isNotBlank(currentStateId)) subtask.CurrentState__c = currentStateId;
            if (storyPoint != null) subtask.StoryPoint__c = storyPoint;
            if (startDate != null) subtask.StartDate__c = startDate;

            Subtask__c created = TicketService.createSubtask(subtask);
            return new APIResponse(true, 'Subtask created', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSubtaskSummary(String subtaskId, String summary) {
        try {
            if (String.isBlank(subtaskId)) return new APIResponse(false, 'subtaskId is required');
            if (String.isBlank(summary)) return new APIResponse(false, 'summary is required');
            Subtask__c existing = DomainCorrectness.requireSubtaskExists(subtaskId);
            Subtask__c updated = TicketService.updateSubtaskSummary(existing, summary);
            return new APIResponse(true, 'Subtask summary updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating subtask summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSubtask(String subtaskId, String summary, String description, String assigneeId, String currentStateId, Integer storyPoint) {
        try {
            if (String.isBlank(subtaskId)) return new APIResponse(false, 'subtaskId is required');

            Subtask__c existing = DomainCorrectness.requireSubtaskExists(subtaskId);

            if (String.isNotBlank(summary)) existing.Summary__c = summary;
            if (String.isNotBlank(description)) existing.Description__c = description;
            if (String.isNotBlank(assigneeId)) existing.Assignee__c = assigneeId;
            if (String.isNotBlank(currentStateId)) existing.CurrentState__c = currentStateId;
            if (storyPoint != null) existing.StoryPoint__c = storyPoint;

            Subtask__c updated = TicketService.updateSubtask(existing);
            return new APIResponse(true, 'Subtask updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse assignSubtask(String subtaskId, String memberId) {
        try {
            if (String.isBlank(subtaskId)) return new APIResponse(false, 'subtaskId is required');
            if (String.isBlank(memberId)) return new APIResponse(false, 'memberId is required');
            Subtask__c existing = DomainCorrectness.requireSubtaskExists(subtaskId);
            DomainCorrectness.requireProjectMemberActive(memberId);
            Subtask__c updated = TicketService.assignSubtask(existing, memberId);
            return new APIResponse(true, 'Subtask assignee updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtask(String subtaskId) {
        try {
            if (String.isBlank(subtaskId)) return new APIResponse(false, 'subtaskId is required');
            Subtask__c existing = DomainCorrectness.requireSubtaskExists(subtaskId);
            TicketService.deleteSubtask(existing);
            return new APIResponse(true, 'Subtask deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtasks(List<String> subtaskIds) {
        try {
            if (subtaskIds == null || subtaskIds.isEmpty()) return new APIResponse(false, 'subtaskIds are required');
            TicketService.deleteSubtasks(subtaskIds);
            return new APIResponse(true, 'Subtasks deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtasks: ' + ex.getMessage());
        }
    }

    // ========== Project Member Actions ==========

    @AuraEnabled
    public static APIResponse createMember(String userId, String projectId, String recordStatus) {
        try {
            if (String.isBlank(userId)) return new APIResponse(false, 'userId is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            DomainCorrectness.requireUserExists(userId);
            DomainCorrectness.requireProjectExists(projectId);

            ProjectMember__c created = ProjectService.createProjectMember(userId, projectId, recordStatus);
            return new APIResponse(true, 'Project member created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project member: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadMembers(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');
            Project__c project = DomainCorrectness.requireProjectExists(projectId);
            List<ProjectMember__c> members = ProjectService.loadProjectMembers(project);
            return new APIResponse(true, 'Project members loaded successfully', members);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading project members: ' + ex.getMessage());
        }
    }

    // ========== Epic Parent Update Actions ==========

    @AuraEnabled
    public static APIResponse updateTicketEpic(String ticketId, String epicId) {
        try {
            if (String.isBlank(ticketId)) return new APIResponse(false, 'ticketId is required');

            DomainCorrectness.requireOptionalEpicActive(epicId);
            Ticket__c existing = DomainCorrectness.requireTicketExists(ticketId);

            existing.Epic__c = epicId;
            Ticket__c updated = TicketService.updateTicket(existing);
            return new APIResponse(true, 'Ticket epic updated successfully', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket epic: ' + ex.getMessage());
        }
    }

    // ========== User Actions ==========

    @AuraEnabled(cacheable=true)
    public static APIResponse loadUsers() {
        try {
            List<User> users = UserService.loadUsers();
            return new APIResponse(true, 'Users loaded successfully', users);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading users: ' + ex.getMessage());
        }
    }
}

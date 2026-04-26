/**
 * @description Aggregation endpoint for Manage Backlog page
 * Returns tickets, sprints, statuses, members and epics for a given project
 */
public with sharing class ManageBacklogController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadBacklogData(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            ProjectService.getProjectById(projectId);

            // Saga step 1: load future sprints
            List<Sprint__c> sprints = SprintService.loadFuturedSprints(projectId);

            List<Status__c> statuses = StatusService.loadStatuses(projectId);
            List<TicketType__c> ticketTypes = TicketService.loadTicketTypes(projectId);
            List<ProjectMember__c> members = ProjectService.loadProjectMembers(projectId);
            List<Epic__c> epics = EpicService.getEpicsByProject(projectId);

            Map<String, Object> data = new Map<String, Object>{
                'sprints' => sprints,
                'status' => statuses,
                'ticketTypes' => ticketTypes,
                'members' => members,
                'epics' => epics
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
    public static APIResponse getProjectByName(String projectName) {
        try {
            Project__c project = ProjectService.getProjectByNameWithValidation(projectName);
            return new APIResponse(true, 'Project retrieved successfully', project);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectStatuses(String projectId) {
        try {
            List<Status__c> statuses = StatusService.getStatusesByProjectWithValidation(projectId);
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
            List<Epic__c> epics = EpicService.getEpicsByProject(projectId);
            return new APIResponse(true, 'Epics retrieved successfully', epics);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epics: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicById(String epicId) {
        try {
            Epic__c epic = EpicService.getEpicById(epicId);
            return new APIResponse(true, 'Epic retrieved successfully', epic);
        }  catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createEpic(String name, String summary, String projectId, String description, DateTime startDate, DateTime endDate) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(summary)) return new APIResponse(false, 'summary is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            Epic__c epic = new Epic__c();
            epic.Name = name;
            epic.Summary__c = summary;
            epic.Project__c = projectId;
            if (String.isNotBlank(description)) epic.Description__c = description;
            if (startDate != null) epic.StartDate__c = startDate;
            if (endDate != null) epic.EndDate__c = endDate;

            Epic__c created = EpicService.createEpic(epic);
            return new APIResponse(true, 'Epic created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateEpic(String epicId, String name, String summary, String description, DateTime startDate, DateTime endDate) {
        try {
            if (String.isBlank(epicId)) return new APIResponse(false, 'epicId is required');

            Epic__c existing = EpicService.findEpicById(epicId);
            if (existing == null) return new APIResponse(false, 'Epic not found: ' + epicId);

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

            Sprint__c existing = SprintService.findSprintById(sprintId);
            if (existing == null) return new APIResponse(false, 'Sprint not found');

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
            SprintService.completeSprint(sprintId);
            return new APIResponse(true, 'Sprint completed');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error completing sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            SprintService.deleteSprint(sprintId);
            return new APIResponse(true, 'Sprint deleted');
        } catch (SprintException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse startSprint(String sprintId) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            SprintService.startSprint(sprintId);
            return new APIResponse(true, 'Sprint started');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error starting sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketsBySprint(String sprintId, Integer offset, Integer pageSize) {
        try {
            if (String.isBlank(sprintId)) return new APIResponse(false, 'sprintId is required');
            List<Ticket__c> tickets = TicketService.getActiveTicketsBySprintOrderByPriorityAsc(sprintId, offset, pageSize);
            return new APIResponse(true, 'Tickets loaded', tickets);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading tickets by sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketTypes(String projectId) {
        try {
            List<TicketType__c> ticketTypes = TicketService.loadTicketTypes(projectId);
            return new APIResponse(true, 'Ticket Types loaded successfully', ticketTypes);
        }catch (Exception ex) {
            return new APIResponse(false, 'Error loading ticket types: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeById(String ticketTypeId) {
        try {
            TicketType__c ticketType = TicketService.getTicketTypeByIdWithValidation(ticketTypeId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        }  catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeByName(String ticketTypeName, String projectId) {
        try {
            TicketType__c ticketType = TicketService.getTicketTypeByNameWithValidation(ticketTypeName, projectId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        }catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            if (String.isBlank(name)) return new APIResponse(false, 'name is required');
            if (String.isBlank(workflowId)) return new APIResponse(false, 'workflowId is required');
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

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
            if (String.isBlank(ticketTypeId)) return new APIResponse(false, 'ticketTypeId is required');
            // if (String.isBlank(currentStateId)) return new APIResponse(false, 'currentStateId is required');

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

            Ticket__c existing = TicketService.findTicketById(ticketId);
            if (existing == null) return new APIResponse(false, 'Ticket not found: ' + ticketId);

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
            Ticket__c updated = TicketService.updateTicketSummary(ticketId, summary);
            return new APIResponse(true, 'Ticket summary updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketPriority(String ticketId, String priority) {
        try {
            Ticket__c updated = TicketService.updateTicketPriority(ticketId, priority);
            return new APIResponse(true, 'Ticket priority updated', updated);
        }catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket priority: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse assignTicket(String ticketId, String memberId) {
        try {
            Ticket__c updated = TicketService.assignTicket(ticketId, memberId);
            return new APIResponse(true, 'Ticket assignee updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketState(String ticketId, String stateId) {
        try {
            Ticket__c updated = TicketService.updateTicketState(ticketId, stateId);
            return new APIResponse(true, 'Ticket state updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket state: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTicket(String ticketId) {
        try {
            TicketService.deleteTickets(new List<String>{ticketId});
            return new APIResponse(true, 'Ticket deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTickets(List<String> ticketIds) {
        try {
            TicketService.deleteTickets(ticketIds);
            return new APIResponse(true, 'Tickets deleted');
        }  catch (Exception ex) {
            return new APIResponse(false, 'Error deleting tickets: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadSubtasks(String ticketId) {
        try {
            List<Subtask__c> subs = TicketService.getSubtasksByTicket(ticketId);
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

            Subtask__c subtask = new Subtask__c();
            subtask.Summary__c = summary;
            subtask.Ticket__c = ticketId;
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
            Subtask__c updated = TicketService.updateSubtaskSummary(subtaskId, summary);
            return new APIResponse(true, 'Subtask summary updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating subtask summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSubtask(String subtaskId, String summary, String description, String assigneeId, String currentStateId, Integer storyPoint) {
        try {
            if (String.isBlank(subtaskId)) return new APIResponse(false, 'subtaskId is required');

            Subtask__c existing = TicketService.findSubtaskById(subtaskId);
            if (existing == null) return new APIResponse(false, 'Subtask not found: ' + subtaskId);

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
            Subtask__c updated = TicketService.assignSubtask(subtaskId, memberId);
            return new APIResponse(true, 'Subtask assignee updated', updated);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtask(String subtaskId) {
        try {
            TicketService.deleteSubtasks(new List<String>{subtaskId});
            return new APIResponse(true, 'Subtask deleted');
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtasks(List<String> subtaskIds) {
        try {
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

            ProjectMember__c created = ProjectService.createProjectMember(userId, projectId, recordStatus);
            return new APIResponse(true, 'Project member created successfully', created);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project member: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadMembers(String projectId) {
        try {
            List<ProjectMember__c> members = ProjectService.loadProjectMembers(projectId);
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

            Ticket__c existing = TicketService.findTicketById(ticketId);
            if (existing == null) return new APIResponse(false, 'Ticket not found: ' + ticketId);

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

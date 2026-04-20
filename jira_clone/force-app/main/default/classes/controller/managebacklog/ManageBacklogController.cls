/**
 * @description Aggregation endpoint for Manage Backlog page
 * Returns tickets, sprints, statuses, members and epics for a given project
 */
public with sharing class ManageBacklogController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadBacklogData(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            // Ensure project exists
            ProjectRepository.getProjectById(projectId);

            List<Ticket__c> tickets = LoadTicketsUseCase.execute(projectId);
            List<Sprint__c> sprints = LoadSprintsUseCase.execute(projectId);
            List<Status__c> statuses = LoadStatusesUseCase.execute(projectId);
            List<TicketType__c> ticketTypes = LoadTicketTypesUseCase.execute(projectId);
            List<ProjectMember__c> members = LoadProjectMembersUseCase.execute(projectId);
            List<Epic__c> epics = GetEpicsByProjectUseCase.execute(projectId);

            Map<String, Object> data = new Map<String, Object>{
                'tickets' => tickets,
                'sprints' => sprints,
                'status' => statuses,
                'ticketTypes' => ticketTypes,
                'members' => members,
                'epics' => epics
            };

            return new APIResponse(true, 'Backlog data loaded', data);
        } catch (ProjectException pex) {
            return new APIResponse(false, 'Invalid project: ' + pex.getMessage());
        } catch (TicketException tex) {
            return new APIResponse(false, tex.getMessage());
        } catch (SprintException sex) {
            return new APIResponse(false, sex.getMessage());
        } catch (TicketTypeException ttex) {
            return new APIResponse(false, ttex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading backlog data: ' + ex.getMessage());
        }
    }

    // ========== Project Actions ==========

    @AuraEnabled(cacheable=true)
    public static APIResponse loadProjects() {
        try {
            List<Project__c> projects = LoadProjectsUseCase.execute();
            return new APIResponse(true, 'Projects loaded successfully', projects);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading projects: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectByName(String projectName) {
        try {
            Project__c project = GetProjectByNameUseCase.execute(projectName);
            return new APIResponse(true, 'Project retrieved successfully', project);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getProjectStatuses(String projectId) {
        try {
            List<Status__c> statuses = GetStatusesByProjectUseCase.execute(projectId);
            return new APIResponse(true, 'Project statuses retrieved successfully', statuses);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving project statuses: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createProject(String projectCreateDtoJson) {
        try {
            ProjectCreateDto dto = (ProjectCreateDto) JSON.deserialize(projectCreateDtoJson, ProjectCreateDto.class);
            Project__c created = CreateProjectUseCase.execute(dto);
            return new APIResponse(true, 'Project created successfully', created);
        } catch (ProjectException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project: ' + ex.getMessage());
        }
    }

    // ========== Epic Actions ==========

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicsByProject(String projectId) {
        try {
            List<Epic__c> epics = GetEpicsByProjectUseCase.execute(projectId);
            return new APIResponse(true, 'Epics retrieved successfully', epics);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epics: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicById(String epicId) {
        try {
            Epic__c epic = GetEpicByIdUseCase.execute(epicId);
            return new APIResponse(true, 'Epic retrieved successfully', epic);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createEpic(String epicCreateDtoJson) {
        try {
            EpicCreateDto dto = (EpicCreateDto) JSON.deserialize(epicCreateDtoJson, EpicCreateDto.class);
            Epic__c created = CreateEpicUseCase.execute(dto);
            return new APIResponse(true, 'Epic created successfully', created);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateEpic(String epicUpdateDtoJson) {
        try {
            EpicUpdateDto dto = (EpicUpdateDto) JSON.deserialize(epicUpdateDtoJson, EpicUpdateDto.class);
            Epic__c updated = UpdateEpicUseCase.execute(dto);
            return new APIResponse(true, 'Epic updated successfully', updated);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createSprint(String sprintCreateDtoJson) {
        try {
            SprintCreateDto dto = (SprintCreateDto) JSON.deserialize(sprintCreateDtoJson, SprintCreateDto.class);
            Sprint__c created = CreateSprintUseCase.execute(dto);
            return new APIResponse(true, 'Sprint created successfully', created);
        } catch (SprintException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSprint(String sprintUpdateDtoJson) {
        try {
            SprintUpdateDto dto = (SprintUpdateDto) JSON.deserialize(sprintUpdateDtoJson, SprintUpdateDto.class);
            Sprint__c updated = UpdateSprintUseCase.execute(dto);
            return new APIResponse(true, 'Sprint updated successfully', updated);
        } catch (SprintException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse completeSprint(String sprintId) {
        try {
            CompleteSprintUseCase.execute(sprintId);
            return new APIResponse(true, 'Sprint completed');
        } catch (SprintException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error completing sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSprint(String sprintId) {
        try {
            DeleteSprintUseCase.execute(sprintId);
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
            StartSprintUseCase.execute(sprintId);
            return new APIResponse(true, 'Sprint started');
        } catch (SprintException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error starting sprint: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketTypes(String projectId) {
        try {
            List<TicketType__c> ticketTypes = LoadTicketTypesUseCase.execute(projectId);
            return new APIResponse(true, 'Ticket Types loaded successfully', ticketTypes);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading ticket types: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeById(String ticketTypeId) {
        try {
            TicketType__c ticketType = GetTicketTypeByIdUseCase.execute(ticketTypeId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getTicketTypeByName(String ticketTypeName, String projectId) {
        try {
            TicketType__c ticketType = GetTicketTypeByNameUseCase.execute(ticketTypeName, projectId);
            return new APIResponse(true, 'Ticket Type retrieved successfully', ticketType);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicketType(String ticketTypeCreateDtoJson) {
        try {
            TicketTypeCreateDto dto = (TicketTypeCreateDto) JSON.deserialize(ticketTypeCreateDtoJson, TicketTypeCreateDto.class);
            TicketType__c created = CreateTicketTypeUseCase.execute(dto);
            return new APIResponse(true, 'Ticket Type created successfully', created);
        } catch (TicketTypeException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket type: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createTicket(String ticketCreateDtoJson) {
        try {
            TicketCreateDto dto = (TicketCreateDto) JSON.deserialize(ticketCreateDtoJson, TicketCreateDto.class);
            Ticket__c created = CreateTicketUseCase.execute(dto);
            return new APIResponse(true, 'Ticket created successfully', created);
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicket(String ticketUpdateDtoJson) {
        try {
            TicketUpdateDto dto = (TicketUpdateDto) JSON.deserialize(ticketUpdateDtoJson, TicketUpdateDto.class);
            if (dto == null) throw new TicketException('dto is required');
            Ticket__c updated = UpdateTicketUseCase.execute(dto);
            return new APIResponse(true, 'Ticket updated', updated);
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketSummary(String ticketId, String summary) {
        try {
            Ticket__c updated = UpdateTicketSummaryUseCase.execute(ticketId, summary);
            return new APIResponse(true, 'Ticket summary updated', updated);
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketPriority(String ticketId, String priority) {
        try {
            Ticket__c updated = UpdateTicketPriorityUseCase.execute(ticketId, priority);
            return new APIResponse(true, 'Ticket priority updated', updated);
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket priority: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse assignTicket(String ticketId, String memberId) {
        try {
            Ticket__c updated = AssignTicketUseCase.execute(ticketId, memberId);
            return new APIResponse(true, 'Ticket assignee updated', updated);
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateTicketState(String ticketId, String stateId) {
        try {
            Ticket__c updated = UpdateTicketStateUseCase.execute(ticketId, stateId);
            return new APIResponse(true, 'Ticket state updated', updated);
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating ticket state: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTicket(String ticketId) {
        try {
            DeleteTicketsUseCase.execute(new List<String>{ticketId});
            return new APIResponse(true, 'Ticket deleted');
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting ticket: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteTickets(List<String> ticketIds) {
        try {
            DeleteTicketsUseCase.execute(ticketIds);
            return new APIResponse(true, 'Tickets deleted');
        } catch (TicketException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting tickets: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadSubtasks(String ticketId) {
        try {
            List<Subtask__c> subs = LoadSubtasksByTicketUseCase.execute(ticketId);
            return new APIResponse(true, 'Subtasks loaded', subs);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading subtasks: ' + ex.getMessage());
        }
    }

    // ========== Subtask Controller Actions ==========

    @AuraEnabled
    public static APIResponse createSubtask(String subtaskCreateDtoJson) {
        try {
            SubtaskCreateDto dto = (SubtaskCreateDto) JSON.deserialize(subtaskCreateDtoJson, SubtaskCreateDto.class);
            Subtask__c created = CreateSubtaskUseCase.execute(dto);
            return new APIResponse(true, 'Subtask created', created);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSubtaskSummary(String subtaskId, String summary) {
        try {
            Subtask__c updated = UpdateSubtaskSummaryUseCase.execute(subtaskId, summary);
            return new APIResponse(true, 'Subtask summary updated', updated);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating subtask summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateSubtask(String subtaskUpdateDtoJson) {
        try {
            SubtaskUpdateDto dto = (SubtaskUpdateDto) JSON.deserialize(subtaskUpdateDtoJson, SubtaskUpdateDto.class);
            if (dto == null) throw new SubtaskException('dto is required');
            Subtask__c updated = UpdateSubtaskUseCase.execute(dto);
            return new APIResponse(true, 'Subtask updated', updated);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse assignSubtask(String subtaskId, String memberId) {
        try {
            Subtask__c updated = AssignSubtaskUseCase.execute(subtaskId, memberId);
            return new APIResponse(true, 'Subtask assignee updated', updated);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtask(String subtaskId) {
        try {
            DeleteSubtasksUseCase.execute(new List<String>{subtaskId});
            return new APIResponse(true, 'Subtask deleted');
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtasks(List<String> subtaskIds) {
        try {
            DeleteSubtasksUseCase.execute(subtaskIds);
            return new APIResponse(true, 'Subtasks deleted');
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtasks: ' + ex.getMessage());
        }
    }

    // ========== Project Member Actions ==========

    @AuraEnabled
    public static APIResponse createMember(String memberCreateDtoJson) {
        try {
            ProjectMemberCreateDto dto = (ProjectMemberCreateDto) JSON.deserialize(memberCreateDtoJson, ProjectMemberCreateDto.class);
            ProjectMember__c created = CreateProjectMemberUseCase.execute(dto);
            return new APIResponse(true, 'Project member created successfully', created);
        } catch (ProjectMemberException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating project member: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadMembers(String projectId) {
        try {
            List<ProjectMember__c> members = LoadProjectMembersUseCase.execute(projectId);
            return new APIResponse(true, 'Project members loaded successfully', members);
        } catch (ProjectMemberException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading project members: ' + ex.getMessage());
        }
    }

    // ========== User Actions ==========

    @AuraEnabled(cacheable=true)
    public static APIResponse loadUsers() {
        try {
            List<User> users = LoadUsersUseCase.execute();
            return new APIResponse(true, 'Users loaded successfully', users);
        } catch (UserException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading users: ' + ex.getMessage());
        }
    }
}
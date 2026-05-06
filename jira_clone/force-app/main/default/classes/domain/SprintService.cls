/**
 * @description Service class for Sprint operations
 * Consolidates all usecases and repository methods for Sprint domain
 */
public with sharing class SprintService {

    public static Sprint__c findSprintById(String sprintId) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Id = :sprintId LIMIT 1];
        } catch (Exception ex) {
            throw new ServiceException('Error finding sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c createSprint(Sprint__c sprint) {
        try {
            insert sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating sprint: ' + ex.getMessage());
        }
    }

    public static Sprint__c updateSprint(Sprint__c sprint) {
        try {
            update sprint;
            return sprint;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating sprint: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating sprint: ' + ex.getMessage());
        }
    }

    public static void completeSprint(Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireSprintIsCompletable(sprint);
            sprint.RecordStatus__c = 'completed';
            updateSprint(sprint);
        } catch (Exception ex) {
            throw new ServiceException('Error completing sprint: ' + ex.getMessage());
        }
    }

    public static void deleteSprint(Sprint__c sprint) {
        try {
            sprint.RecordStatus__c = 'delete';
            updateSprint(sprint);
        } catch (Exception ex) {
            throw new ServiceException('Error deleting sprint: ' + ex.getMessage());
        }
    }

    public static List<Sprint__c> loadUncompleteSprintsByProject(Project__c project) {
        try {
            return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Project__c = :project.Id AND RecordStatus__c != 'completed' AND RecordStatus__c != 'delete'];
        } catch (Exception ex) {
            throw new ServiceException('Error loading sprints: ' + ex.getMessage());
        }
    }

    public static Sprint__c loadActiveSprint(String projectId) {
        try {
            List<Sprint__c> sprints = [
                SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c
                FROM Sprint__c
                WHERE Project__c = :projectId AND RecordStatus__c = 'in_progress'
                LIMIT 1
            ];
            return sprints.isEmpty() ? null : sprints[0];
        } catch (Exception ex) {
            throw new ServiceException('Error loading active sprint: ' + ex.getMessage());
        }
    }

    public static Set<String> getTicketsAtEndStatus(
        List<WorkflowTransition__c> workflowTransitions,
        List<TicketType__c>         ticketTypes,
        List<Ticket__c>             tickets
    ) {
        Map<String, List<WorkflowTransition__c>> transitionsByWorkflow = new Map<String, List<WorkflowTransition__c>>();
        for (WorkflowTransition__c wt : workflowTransitions) {
            if (!transitionsByWorkflow.containsKey(wt.Workflow__c)) {
                transitionsByWorkflow.put(wt.Workflow__c, new List<WorkflowTransition__c>());
            }
            transitionsByWorkflow.get(wt.Workflow__c).add(wt);
        }

        Map<String, String> ticketTypeWorkflowMap = new Map<String, String>();
        for (TicketType__c tt : ticketTypes) {
            if (tt.Workflow__c != null) {
                ticketTypeWorkflowMap.put(tt.Id, tt.Workflow__c);
            }
        }

        Map<String, String> workflowEndStatusMap = new Map<String, String>();
        for (String wfId : transitionsByWorkflow.keySet()) {
            String endStatusId = WorkflowService.foundEndStatus(transitionsByWorkflow.get(wfId));
            if (endStatusId != null) {
                workflowEndStatusMap.put(wfId, endStatusId);
            }
        }

        Set<String> ticketsAtEndStatus = new Set<String>();
        for (Ticket__c t : tickets) {
            String wfId      = ticketTypeWorkflowMap.get(t.Ticket_Type__c);
            String endStatus = wfId != null ? workflowEndStatusMap.get(wfId) : null;
            if (endStatus != null && endStatus == t.CurrentState__c) {
                ticketsAtEndStatus.add(t.Id);
            }
        }

        return ticketsAtEndStatus;
    }

    public static void startSprint(Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireSprintIsStartable(sprint);
            List<Sprint__c> activeSprint = [
                SELECT Id FROM Sprint__c
                WHERE Project__c = :sprint.Project__c AND RecordStatus__c = 'in_progress'
                LIMIT 1
            ];
            DomainCompleteValidator.requireNoActiveSprintInProject(activeSprint);

            sprint.RecordStatus__c = 'in_progress';
            updateSprint(sprint);
        } catch (Exception ex) {
            throw new ServiceException('Error starting sprint: ' + ex.getMessage());
        }
    }
}

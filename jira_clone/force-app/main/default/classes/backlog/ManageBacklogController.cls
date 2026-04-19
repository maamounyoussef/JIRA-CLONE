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

            List<Ticket__c> tickets = TicketService.loadTickets(projectId);
            List<Sprint__c> sprints = SprintService.loadSprints(projectId);
            List<Status__c> statuses = LoadStatusesUseCase.execute(projectId);
            // load members directly
            List<ProjectMember__c> members = [SELECT Id, Name, User__c, User__r.Name FROM ProjectMember__c WHERE Project__c = :projectId ORDER BY Name];
            List<Epic__c> epics = EpicService.getEpicsByProject(projectId);

            Map<String, Object> data = new Map<String, Object>{
                'tickets' => tickets,
                'sprints' => sprints,
                'status' => statuses,
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
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading backlog data: ' + ex.getMessage());
        }
    }
}
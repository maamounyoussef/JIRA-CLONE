/**
 * @description UseCase for loading all tickets for a project
 * Validates project exists and retrieves tickets
 */
public with sharing class LoadTicketsUseCase {
    
    public static List<Ticket__c> execute(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new TicketException('projectId is required');
            // validate project exists
            ProjectRepository.getProjectById(projectId);
            return TicketRepository.getTicketsByProject(projectId);
        } catch (ProjectException pex) {
            throw new TicketException('Invalid project: ' + pex.getMessage());
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error loading tickets: ' + ex.getMessage());
        }
    }
}

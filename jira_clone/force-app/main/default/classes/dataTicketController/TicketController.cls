/**
 * @description Controller for loading Ticket records for LWC components
 */
public with sharing class TicketController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTickets() {
        try {
            List<Ticket__c> tickets = [
                SELECT Id, Summary__c, Ticket_Type__c, Ticket_Type__r.Id, Ticket_Type__r.Name, Ticket_Type__r.Project__c
                FROM Ticket__c
                ORDER BY CreatedDate DESC
                LIMIT 1000
            ];
            return new APIResponse(true, 'Tickets loaded successfully', tickets);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading tickets: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse loadTicketsByProject(String projectId) {
        try {
            List<Ticket__c> tickets = [
                SELECT Id, Summary__c, Ticket_Type__c, Ticket_Type__r.Id, Ticket_Type__r.Name, Ticket_Type__r.Project__c
                FROM Ticket__c
                WHERE Ticket_Type__r.Project__c = :projectId
                ORDER BY CreatedDate DESC
            ];
            return new APIResponse(true, 'Tickets loaded successfully', tickets);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading tickets: ' + ex.getMessage());
        }
    }

    /**
     * @description Create a new Ticket__c record from JSON payload
     * @param ticketJson - JSON string representing Ticket__c fields
     * @return APIResponse containing created Ticket__c in data attribute
     */
    @AuraEnabled
    public static APIResponse createTicket(String ticketJson) {
        try {
            if (String.isBlank(ticketJson)) {
                return new APIResponse(false, 'No ticket data provided');
            }
            Ticket__c t = (Ticket__c) JSON.deserialize(ticketJson, Ticket__c.class);

            // If Creator__c not provided, try to set it to the ProjectMember for current user and ticket's project
            if (t.Creator__c == null && t.Ticket_Type__c != null) {
                try {
                    TicketType__c tt = [SELECT Id, Project__c FROM TicketType__c WHERE Id = :t.Ticket_Type__c LIMIT 1];
                    if (tt != null && tt.Project__c != null) {
                        List<ProjectMember__c> pmList = [SELECT Id FROM ProjectMember__c WHERE Project__c = :tt.Project__c AND User__c = :UserInfo.getUserId() LIMIT 1];
                        if (!pmList.isEmpty()) t.Creator__c = pmList[0].Id;
                    }
                } catch (Exception e) {
                    // ignore lookup failures and proceed without Creator__c
                }
            }

            insert t;
            return new APIResponse(true, 'Ticket created successfully', t);
        } catch (DmlException dmlEx) {
            return new APIResponse(false, 'Error creating ticket: ' + dmlEx.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating ticket: ' + ex.getMessage());
        }
    }

}

/**
 * @description One Ticket__History entry, shaped for the ticket-view activity log.
 * Carries the editor's project-member name, when the change happened,
 * and a human-readable message derived from the changed field.
 */
public class TicketHistoryDto {
    @AuraEnabled public String   id;          // Ticket__History.Id (list key)
    @AuraEnabled public String   field;       // changed field API name (or 'created')
    @AuraEnabled public String   memberName;  // ProjectMember__c.Name (falls back to user name)
    @AuraEnabled public Datetime createdDate; // when the change happened
    @AuraEnabled public String   message;     // rendered log message
}

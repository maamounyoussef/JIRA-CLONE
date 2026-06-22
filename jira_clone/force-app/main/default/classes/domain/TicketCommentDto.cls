/**
 * @description One TicketComment__c entry, shaped for the ticket-view comment section.
 * Carries the author's project-member name, when the comment was posted,
 * and the comment body.
 */
public class TicketCommentDto {
    @AuraEnabled public String   id;          // TicketComment__c.Id (list key)
    @AuraEnabled public String   memberName;  // ProjectMember__c.Name (comment author)
    @AuraEnabled public Datetime createdDate; // when the comment was posted
    @AuraEnabled public String   message;     // the comment body
}

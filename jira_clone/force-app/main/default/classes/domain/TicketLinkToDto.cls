public class TicketLinkToDto {
    @AuraEnabled public String linkId;          // TicketLink__c.Id
    @AuraEnabled public String type;            // TicketLink__c.Type__c
    @AuraEnabled public String recordStatus;    // TicketLink__c.RecordStatus__c
    @AuraEnabled public String ticketFromId;    // TicketLink__c.LinkedFromTicket__c
    @AuraEnabled public Ticket__c linkedToTicket; // TicketLink__c.LinkedToTicket__c
}

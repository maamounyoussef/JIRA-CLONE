/**
 * @description DTO for createTicket response containing both the created ticket and updated sprint
 */
public with sharing class CreateTicketResponse {
    public Ticket__c createdTicket { get; set; }
    public Sprint__c updatedSprint { get; set; }

    public CreateTicketResponse(Ticket__c createdTicket, Sprint__c updatedSprint) {
        this.createdTicket = createdTicket;
        this.updatedSprint = updatedSprint;
    }
        public CreateTicketResponse(Ticket__c createdTicket) {
        this.createdTicket = createdTicket;
    }
}

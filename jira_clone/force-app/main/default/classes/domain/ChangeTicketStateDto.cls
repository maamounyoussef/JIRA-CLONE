/**
 * @description DTO for changeTicketState response containing ticket state change info and updated sprint
 */
public with sharing class ChangeTicketStateDto {
    public Boolean isEndStatus { get; set; }
    public Sprint__c updatedSprint { get; set; }

    public ChangeTicketStateDto(Boolean isEndStatus, Sprint__c updatedSprint) {
        this.isEndStatus = isEndStatus;
        this.updatedSprint = updatedSprint;
    }

    public ChangeTicketStateDto(Boolean isEndStatus) {
        this.isEndStatus = isEndStatus;
        this.updatedSprint = null;
    }
}

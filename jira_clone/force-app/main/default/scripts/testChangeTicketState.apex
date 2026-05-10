// Test script for changeTicketState methods in both controllers
// This script demonstrates calling ManageBacklogController and ManageTicketTrackingController changeTicketState methods

// Get a sample ticket from the database
List<Ticket__c> tickets = [
    SELECT Id, Name, CurrentState__c, Ticket_Type__c, Sprint__c, StoryPoint__c
    FROM Ticket__c
    WHERE RecordStatus__c = 'active'
    LIMIT 1
];

if (tickets.isEmpty()) {
    System.debug('No active tickets found. Please create a ticket first.');
    return;
}

Ticket__c ticket = tickets[0];
System.debug('Selected Ticket: ' + ticket.Name + ' (ID: ' + ticket.Id + ')');

// Get the ticket type and its workflow
TicketType__c ticketType = [
    SELECT Id, Workflow__c
    FROM TicketType__c
    WHERE Id = :ticket.Ticket_Type__c
    LIMIT 1
];

// Get available statuses for the workflow
List<Status__c> statuses = [
    SELECT Id, Name
    FROM Status__c
    WHERE Project__c IN (
        SELECT Project__c FROM TicketType__c WHERE Id = :ticketType.Id
    )
    LIMIT 2
];

if (statuses.size() < 2) {
    System.debug('Not enough statuses found for transition. Please set up workflow statuses.');
    return;
}

String fromStatusId = statuses[0].Id;
String toStatusId = statuses[1].Id;

System.debug('From Status: ' + statuses[0].Name + ' (ID: ' + fromStatusId + ')');
System.debug('To Status: ' + statuses[1].Name + ' (ID: ' + toStatusId + ')');
System.debug('');

// ===== TEST 1: ManageBacklogController.changeTicketState =====
System.debug('===== TEST 1: ManageBacklogController.changeTicketState =====');
try {
    APIResponse backlogResponse = ManageBacklogController.changeTicketState(ticket.Id, fromStatusId, toStatusId);
    System.debug('backlogResponse: ' + backlogResponse);
} catch (Exception ex) {
    System.debug('ERROR: ' + ex.getMessage());
    System.debug('Stack: ' + ex.getStackTraceString());
    System.debug('');
}

// ===== TEST 2: ManageTicketTrackingController.changeTicketState =====
System.debug('===== TEST 2: ManageTicketTrackingController.changeTicketState =====');
try {
    // Need to refresh the ticket state after first call
    Ticket__c refreshedTicket = [SELECT Id, CurrentState__c FROM Ticket__c WHERE Id = :ticket.Id];
    String currentStatusId = refreshedTicket.CurrentState__c;

    // Use current status as fromStatus for the second test
    APIResponse trackingResponse = ManageTicketTrackingController.changeTicketState(ticket.Id, currentStatusId, toStatusId);
    System.debug('Success: ' + trackingResponse.success);
    System.debug('Message: ' + trackingResponse.message);
    System.debug('Data: ' + JSON.serializePretty(trackingResponse.data));
    System.debug('');
} catch (Exception ex) {
    System.debug('ERROR: ' + ex.getMessage());
    System.debug('Stack: ' + ex.getStackTraceString());
    System.debug('');
}

System.debug('===== TEST COMPLETE =====');

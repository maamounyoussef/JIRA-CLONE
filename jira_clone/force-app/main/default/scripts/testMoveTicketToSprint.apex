// Test for ManageBacklogController.moveTicketToSprint
// Mirrors Aura payload: {"ticketId":"a0Cd200001DDS9oEAH","sprintId":"a06d200000LNPkqAAH"}

String ticketId = 'a0Cd200001DDPS1EAP';
String sprintId = 'a06d200000LNPkqAAH';

APIResponse response = ManageBacklogController.moveTicketToSprint(ticketId, sprintId);

System.debug('Success: ' + response.success);
System.debug('Message: ' + response.message);
System.debug('Data: ' + JSON.serializePretty(response.data));

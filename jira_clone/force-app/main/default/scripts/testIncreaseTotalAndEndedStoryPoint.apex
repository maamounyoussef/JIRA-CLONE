// Calls ManageBacklogController.createTicket with the exact values from the request payload
// and prints the response.

String  name           = 'aadssadsa';
String  summary        = 'asddas';
String  description    = 'edasdas';
Integer storyPoint     = 10;
String  ticketTypeId   = 'a05d200000P51DBAAZ';
String  currentStateId = 'a02d200000YKyncAAD';
String  priority       = 'Critical';
String  sprintId       = 'a06d200000LNPkqAAH';
String  assignedToId   = null;
String  epicId         = null;

APIResponse response = ManageBacklogController.createTicket(
    name,
    summary,
    ticketTypeId,
    currentStateId,
    description,
    storyPoint,
    assignedToId,
    epicId,
    sprintId,
    priority
);

System.debug('===== RESPONSE =====');
System.debug(JSON.serializePretty(response));

APIResponse result = ManageBacklogController.createTicket(
    'dsad',                        // name
    'sadsa',                       // summary
    'a05d200000P51DBAAZ',          // ticketTypeId
    'a02d200000YKynbAAD',          // currentStateId
    'dsa',                         // description
    2,                             // storyPoint
    null,                          // assignedToId
    null,                          // epicId
    'a06d200000LDNCPAA5',          // sprintId
    'High'                         // priority
);

Map<String, Object> responseData = (Map<String, Object>) result.data;
System.debug('Created Ticket: ' + responseData.get('createdTicket'));
System.debug('Updated Sprint: ' + responseData.get('updatedSprint'));

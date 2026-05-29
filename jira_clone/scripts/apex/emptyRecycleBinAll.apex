// =============================================================================
// HARD DELETE: removes ALL TicketLinks, Subtasks, Tickets, and Sprints from the DB.
//
// Deletion order respects FK references (children before parents):
//   TicketLink__c  -> references Ticket__c (LinkedFromTicket__c / LinkedToTicket__c)
//   Subtask__c     -> references Ticket__c
//   Ticket__c      -> references Sprint__c
//   Sprint__c      -> (no dependents left at this point)
//
// Recycle Bin is emptied so records cannot be restored.
//
// Run with:
//   sf apex run --file scripts/apex/deleteAllSprintsTicketsSubtasks.apex --target-org <alias>
//
// Verify target first:
//   sf org display --target-org <alias>
// =============================================================================

Savepoint sp = Database.setSavepoint();
try {
    List<TicketLink__c> ticketLinks = [SELECT Id FROM TicketLink__c LIMIT 10000];
    List<Subtask__c>    subtasks    = [SELECT Id FROM Subtask__c    LIMIT 10000];
    List<Ticket__c>     tickets     = [SELECT Id FROM Ticket__c     LIMIT 10000];
    List<Sprint__c>     sprints     = [SELECT Id FROM Sprint__c     LIMIT 10000];

    System.debug('TicketLinks to delete: ' + ticketLinks.size());
    System.debug('Subtasks    to delete: ' + subtasks.size());
    System.debug('Tickets     to delete: ' + tickets.size());
    System.debug('Sprints     to delete: ' + sprints.size());

    if (!ticketLinks.isEmpty()) delete ticketLinks;
    if (!subtasks.isEmpty())    delete subtasks;
    if (!tickets.isEmpty())     delete tickets;
    if (!sprints.isEmpty())     delete sprints;

    if (!ticketLinks.isEmpty()) Database.emptyRecycleBin(ticketLinks);
    if (!subtasks.isEmpty())    Database.emptyRecycleBin(subtasks);
    if (!tickets.isEmpty())     Database.emptyRecycleBin(tickets);
    if (!sprints.isEmpty())     Database.emptyRecycleBin(sprints);

    System.debug('Hard delete complete.');
} catch (Exception ex) {
    Database.rollback(sp);
    System.debug('Rolled back due to: ' + ex.getMessage());
    throw ex;
}

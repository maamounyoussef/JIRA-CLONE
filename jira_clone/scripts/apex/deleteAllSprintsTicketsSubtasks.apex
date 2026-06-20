// =============================================================================
// HARD DELETE (CHUNKED): removes TicketLinks, Subtasks, Tickets, and Sprints.
//
// Why chunked: synchronous Apex caps DML at 10,000 rows per transaction.
// We delete up to CHUNK rows per object per run (4 * CHUNK total DML rows).
// CHUNK = 2000 -> 8000 DML rows per run, safely under the 10k limit.
//
// Recycle Bin is NOT emptied here (it counts toward the same 10k DML cap).
// Run scripts/apex/emptyRecycleBinAll.apex once at the end if you need the
// records gone for good.
//
// Re-run this script until "Remaining" counts are all 0.
//
// Deletion order respects FK references (children before parents):
//   TicketLink__c  -> Ticket__c (LinkedFromTicket__c / LinkedToTicket__c)
//   Subtask__c     -> Ticket__c
//   Ticket__c      -> Sprint__c
//   Sprint__c      -> (no dependents left)
//
// Run with:
//   sf apex run --file scripts/apex/deleteAllSprintsTicketsSubtasks.apex --target-org <alias>
// =============================================================================

final Integer CHUNK = 2000;

Savepoint sp = Database.setSavepoint();
try {
    List<TicketLink__c> ticketLinks = [SELECT Id FROM TicketLink__c LIMIT :CHUNK];
    List<Subtask__c>    subtasks    = [SELECT Id FROM Subtask__c    LIMIT :CHUNK];
    List<Ticket__c>     tickets     = [SELECT Id FROM Ticket__c     LIMIT :CHUNK];
    List<Sprint__c>     sprints     = [SELECT Id FROM Sprint__c     LIMIT :CHUNK];

    System.debug('TicketLinks to delete this run: ' + ticketLinks.size());
    System.debug('Subtasks    to delete this run: ' + subtasks.size());
    System.debug('Tickets     to delete this run: ' + tickets.size());
    System.debug('Sprints     to delete this run: ' + sprints.size());

    if (!ticketLinks.isEmpty()) delete ticketLinks;
    if (!subtasks.isEmpty())    delete subtasks;
    if (!tickets.isEmpty())     delete tickets;
    if (!sprints.isEmpty())     delete sprints;

    Integer remLinks    = [SELECT COUNT() FROM TicketLink__c];
    Integer remSubtasks = [SELECT COUNT() FROM Subtask__c];
    Integer remTickets  = [SELECT COUNT() FROM Ticket__c];
    Integer remSprints  = [SELECT COUNT() FROM Sprint__c];

    System.debug('Remaining TicketLinks: ' + remLinks);
    System.debug('Remaining Subtasks:    ' + remSubtasks);
    System.debug('Remaining Tickets:     ' + remTickets);
    System.debug('Remaining Sprints:     ' + remSprints);

    if (remLinks + remSubtasks + remTickets + remSprints == 0) {
        System.debug('Hard delete complete. (Run emptyRecycleBinAll.apex if needed.)');
    } else {
        System.debug('More rows remain — re-run this script.');
    }
} catch (Exception ex) {
    Database.rollback(sp);
    System.debug('Rolled back due to: ' + ex.getMessage());
    throw ex;
}

// =============================================================================
// HARD DELETE: removes ALL TicketLinks, Subtasks, Tickets, Sprints,
// ValidateFields, WorkflowTransitions, Statuses, TicketTypes, and Workflows from the DB.
//
// Deletion order respects FK references (children before parents):
//   TicketLink__c        -> references Ticket__c (LinkedFromTicket__c / LinkedToTicket__c)
//   Subtask__c           -> references Ticket__c, Status__c (CurrentState__c)
//   Ticket__c            -> references Sprint__c, Status__c (CurrentState__c), TicketType__c
//   Sprint__c            -> (no dependents left at this point)
//   ValidateField__c     -> references WorkflowTransition__c (Restrict delete -> must go first)
//   WorkflowTransition__c -> references Workflow__c, Status__c (FromStatus__c / ToStatus__c)
//   Status__c            -> references Project__c ("status of project")
//   TicketType__c        -> references Workflow__c (Restrict delete -> must go before Workflow)
//   Workflow__c          -> references Project__c
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
    List<TicketLink__c>         ticketLinks         = [SELECT Id FROM TicketLink__c         LIMIT 10000];
    List<Subtask__c>            subtasks            = [SELECT Id FROM Subtask__c            LIMIT 10000];
    List<Ticket__c>             tickets             = [SELECT Id FROM Ticket__c             LIMIT 10000];
    List<Sprint__c>             sprints             = [SELECT Id FROM Sprint__c             LIMIT 10000];
    List<ValidateField__c>      validateFields      = [SELECT Id FROM ValidateField__c      LIMIT 10000];
    List<WorkflowTransition__c> workflowTransitions = [SELECT Id FROM WorkflowTransition__c LIMIT 10000];
    List<Status__c>             statuses            = [SELECT Id FROM Status__c             LIMIT 10000];
    List<TicketType__c>         ticketTypes         = [SELECT Id FROM TicketType__c         LIMIT 10000];
    List<Workflow__c>           workflows           = [SELECT Id FROM Workflow__c           LIMIT 10000];

    System.debug('TicketLinks         to delete: ' + ticketLinks.size());
    System.debug('Subtasks            to delete: ' + subtasks.size());
    System.debug('Tickets             to delete: ' + tickets.size());
    System.debug('Sprints             to delete: ' + sprints.size());
    System.debug('ValidateFields      to delete: ' + validateFields.size());
    System.debug('WorkflowTransitions to delete: ' + workflowTransitions.size());
    System.debug('Statuses            to delete: ' + statuses.size());
    System.debug('TicketTypes         to delete: ' + ticketTypes.size());
    System.debug('Workflows           to delete: ' + workflows.size());

    if (!ticketLinks.isEmpty())         delete ticketLinks;
    if (!subtasks.isEmpty())            delete subtasks;
    if (!tickets.isEmpty())             delete tickets;
    if (!sprints.isEmpty())             delete sprints;
    if (!validateFields.isEmpty())      delete validateFields;
    if (!workflowTransitions.isEmpty()) delete workflowTransitions;
    if (!statuses.isEmpty())            delete statuses;
    if (!ticketTypes.isEmpty())         delete ticketTypes;
    if (!workflows.isEmpty())           delete workflows;

    if (!ticketLinks.isEmpty())         Database.emptyRecycleBin(ticketLinks);
    if (!subtasks.isEmpty())            Database.emptyRecycleBin(subtasks);
    if (!tickets.isEmpty())             Database.emptyRecycleBin(tickets);
    if (!sprints.isEmpty())             Database.emptyRecycleBin(sprints);
    if (!validateFields.isEmpty())      Database.emptyRecycleBin(validateFields);
    if (!workflowTransitions.isEmpty()) Database.emptyRecycleBin(workflowTransitions);
    if (!statuses.isEmpty())            Database.emptyRecycleBin(statuses);
    if (!ticketTypes.isEmpty())         Database.emptyRecycleBin(ticketTypes);
    if (!workflows.isEmpty())           Database.emptyRecycleBin(workflows);

    System.debug('Hard delete complete.');
} catch (Exception ex) {
    Database.rollback(sp);
    System.debug('Rolled back due to: ' + ex.getMessage());
    throw ex;
}

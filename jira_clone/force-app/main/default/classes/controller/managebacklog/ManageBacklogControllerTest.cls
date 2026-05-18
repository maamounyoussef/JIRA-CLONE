@isTest
public class ManageBacklogControllerTest {

    // ════════════════════════════════════════════════════════════════════════
    //  TEST DATA HELPERS
    //  Every helper inserts a record that satisfies the apex/store required
    //  fields documented in OBJECT_VALIDATION_LWC_APEX.md.
    // ════════════════════════════════════════════════════════════════════════

    private static Project__c createProject(String name) {
        Project__c p = new Project__c(Name = name);
        insert p;
        return p;
    }

    private static Workflow__c createWorkflow(Project__c project, String name) {
        Workflow__c w = new Workflow__c(Name = name, Project__c = project.Id, RecordStatus__c = 'active');
        insert w;
        return w;
    }

    private static Status__c createStatus(Project__c project, String name) {
        Status__c s = new Status__c(Name = name, Project__c = project.Id);
        insert s;
        return s;
    }

    private static TicketType__c createTicketType(Project__c project, Workflow__c workflow, String name) {
        TicketType__c tt = new TicketType__c(
            Name            = name,
            Description__c  = name + ' description',
            IconUrl__c      = 'https://example.com/icon.png',
            Workflow__c     = workflow.Id,
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert tt;
        return tt;
    }

    private static ProjectMember__c createCurrentUserMember(Project__c project) {
        ProjectMember__c pm = new ProjectMember__c(
            User__c         = UserInfo.getUserId(),
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert pm;
        return pm;
    }

    private static Sprint__c createSprint(Project__c project, String name) {
        Sprint__c s = new Sprint__c(
            Name            = name,
            Project__c      = project.Id,
            Duration__c     = 14,
            Goal__c         = 'Sprint goal',
            StartDate__c    = Date.today(),
            RecordStatus__c = 'future'
        );
        insert s;
        return s;
    }

    /**
     * Inserts a Ticket__c with every apex/store-required field per
     * OBJECT_VALIDATION_LWC_APEX.md (Ticket__c):
     *   CurrentState__c, Summary__c, Creator__c, Description__c,
     *   Priority__c, RecordStatus__c, Ticket_Type__c.
     */
    private static Ticket__c createValidTicket(Status__c status, TicketType__c ticketType, ProjectMember__c creator, String name) {
        Ticket__c t = new Ticket__c(
            Name            = name,
            Summary__c      = 'Summary for ' + name,
            Description__c  = 'Description for ' + name,
            Priority__c     = 'Medium',
            RecordStatus__c = 'active',
            CurrentState__c = status.Id,
            Ticket_Type__c  = ticketType.Id,
            Creator__c      = creator.Id
        );
        insert t;
        return t;
    }

    private static TicketContext buildTicketContext(String projectName, String ticketName) {
        TicketContext ctx = new TicketContext();
        ctx.project    = createProject(projectName);
        ctx.workflow   = createWorkflow(ctx.project, projectName + '-WF');
        ctx.status     = createStatus(ctx.project, 'Open');
        ctx.ticketType = createTicketType(ctx.project, ctx.workflow, 'Bug');
        ctx.creator    = createCurrentUserMember(ctx.project);
        ctx.ticket     = createValidTicket(ctx.status, ctx.ticketType, ctx.creator, ticketName);
        return ctx;
    }

    private class TicketContext {
        Project__c       project;
        Workflow__c      workflow;
        Status__c        status;
        TicketType__c    ticketType;
        ProjectMember__c creator;
        Ticket__c        ticket;
    }

    // ════════════════════════════════════════════════════════════════════════
    //  TESTS
    // ════════════════════════════════════════════════════════════════════════

    @isTest
    static void testUpdateTicketDescription() {
        TicketContext ctx = buildTicketContext('TestProject-UpdateDesc', 'TCK-DESC-001');
        String newDescription = 'Updated description text';

        Test.startTest();
        APIResponse res = ManageBacklogController.updateTicketDescription(ctx.ticket.Id, newDescription);
        Test.stopTest();

        Assert.isTrue(res.success, 'updateTicketDescription should succeed; got: ' + res.message);
        Ticket__c reloaded = [SELECT Description__c FROM Ticket__c WHERE Id = :ctx.ticket.Id LIMIT 1];
        Assert.areEqual(newDescription, reloaded.Description__c, 'Description should be persisted');
    }

    @isTest
    static void testMoveTicketToBacklog() {
        TicketContext ctx = buildTicketContext('TestProject-ToBacklog', 'TCK-MTB-001');
        Sprint__c sprint  = createSprint(ctx.project, 'Sprint-A');
        ctx.ticket.Sprint__c = sprint.Id;
        update ctx.ticket;

        Test.startTest();
        APIResponse res = ManageBacklogController.moveTicketToBacklog(ctx.ticket.Id);
        Test.stopTest();

        Assert.isTrue(res.success, 'moveTicketToBacklog should succeed; got: ' + res.message);
        Ticket__c reloaded = [SELECT Sprint__c FROM Ticket__c WHERE Id = :ctx.ticket.Id LIMIT 1];
        Assert.areEqual(null, reloaded.Sprint__c, 'Ticket should be detached from sprint');
    }

    @isTest
    static void testMoveTicketToSprint() {
        TicketContext ctx = buildTicketContext('TestProject-ToSprint', 'TCK-MTS-001');
        Sprint__c sprint  = createSprint(ctx.project, 'Sprint-B');

        Test.startTest();
        APIResponse res = ManageBacklogController.moveTicketToSprint(ctx.ticket.Id, sprint.Id);
        Test.stopTest();

        Assert.isTrue(res.success, 'moveTicketToSprint should succeed; got: ' + res.message);
        Ticket__c reloaded = [SELECT Sprint__c FROM Ticket__c WHERE Id = :ctx.ticket.Id LIMIT 1];
        Assert.areEqual(sprint.Id, reloaded.Sprint__c, 'Ticket should be attached to the target sprint');
    }

    @isTest
    static void testLoadTicketBySearchTerm() {
        TicketContext ctx = buildTicketContext('TestProject-Search', 'TCK-SEARCH-001');

        Test.setFixedSearchResults(new List<Id>{ ctx.ticket.Id });

        Test.startTest();
        APIResponse res = ManageBacklogController.loadTicketBySearchTerm(ctx.project.Id, 'TCK-SEARCH-001');
        Test.stopTest();

        Assert.isTrue(res.success, 'loadTicketBySearchTerm should succeed; got: ' + res.message);
        List<Ticket__c> tickets = (List<Ticket__c>) res.data;
        Assert.isNotNull(tickets, 'Tickets list should not be null');
        Assert.areEqual(1, tickets.size(), 'Should return exactly one matching ticket');
        Assert.areEqual(ctx.ticket.Id, tickets[0].Id, 'Returned ticket should match the seeded ticket');
    }

    @isTest
    static void testLoadTicketLinkedToType() {
        Test.startTest();
        APIResponse res = ManageBacklogController.loadTicketLinkedToType();
        Test.stopTest();

        Assert.isTrue(res.success, 'loadTicketLinkedToType should succeed');
        Assert.isNotNull(res.data, 'Link types data should not be null');

        List<Map<String, String>> linkTypes = (List<Map<String, String>>) res.data;
        Assert.isFalse(linkTypes.isEmpty(), 'Link types should not be empty');

        Set<String> values = new Set<String>();
        for (Map<String, String> entry : linkTypes) {
            values.add(entry.get('value'));
        }
        Assert.isTrue(values.contains('Blocks'),     'Link types should include Blocks');
        Assert.isTrue(values.contains('Relates To'), 'Link types should include Relates To');
        Assert.isTrue(values.contains('Duplicates'), 'Link types should include Duplicates');
        Assert.isTrue(values.contains('Depends On'), 'Link types should include Depends On');
    }
}

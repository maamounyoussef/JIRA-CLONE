/**
 * @description Test class for TicketController
 */
@isTest
public class TicketControllerTest {

    @testSetup
    static void setupTestData() {
        // Projects
        List<Project__c> projects = new List<Project__c>{
            new Project__c(Name = 'Proj A'),
            new Project__c(Name = 'Proj B')
        };
        insert projects;

        // Statuses for Proj A
        List<Status__c> statuses = new List<Status__c>{
            new Status__c(Name = 'Open', Project__c = projects[0].Id),
            new Status__c(Name = 'In Progress', Project__c = projects[0].Id)
        };
        insert statuses;

        // Ticket types for each project
        TicketType__c tt1 = new TicketType__c(Name = 'Bug', Project__c = projects[0].Id);
        TicketType__c tt2 = new TicketType__c(Name = 'Feature', Project__c = projects[1].Id);
        insert new List<TicketType__c>{ tt1, tt2 };

        // Sprint for Proj A
        Sprint__c sp1 = new Sprint__c(Name = 'Sprint 1', Project__c = projects[0].Id, StartDate__c = Date.today());
        insert sp1;

        // Tickets: one per project (linked via Ticket Type)
        List<Ticket__c> tickets = new List<Ticket__c>{
            new Ticket__c(Summary__c = 'Ticket for A', Ticket_Type__c = tt1.Id),
            new Ticket__c(Summary__c = 'Ticket for B', Ticket_Type__c = tt2.Id)
        };
        insert tickets;
    }

    @isTest
    static void testLoadTicketsByProject() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Proj A' LIMIT 1];

        Test.startTest();
        APIResponse result = TicketController.loadTicketsByProject(project.Id);
        Test.stopTest();

        Assert.isTrue(result.success, 'API response should be successful');
        List<Ticket__c> tickets = (List<Ticket__c>) result.data;
        // Only one ticket was created for Proj A in setup
        Assert.areEqual(1, tickets.size(), 'Should return only tickets for the given project');
        Assert.areEqual(project.Id, tickets[0].Ticket_Type__r.Project__c, 'Ticket type project should match requested project');
    }

    @isTest
    static void testCreateTicketViaApex() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Proj A' LIMIT 1];
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Project__c = :project.Id LIMIT 1];
        Sprint__c sp = [SELECT Id FROM Sprint__c WHERE Project__c = :project.Id LIMIT 1];

        // create a ProjectMember for the running test user so Creator__c can be set
        ProjectMember__c testPm = new ProjectMember__c(Project__c = project.Id, User__c = UserInfo.getUserId());
        insert testPm;

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Summary__c', 'Created via Apex');
        payload.put('Ticket_Type__c', tt.Id);
        // ISO8601 datetimes
        String startIso = Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String endIso = Datetime.now().addDays(2).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        payload.put('StartDate__c', startIso);
        payload.put('EndDate__c', endIso);
        payload.put('Sprint__c', sp.Id);

        String jsonPayload = JSON.serialize(payload);

        Test.startTest();
        APIResponse res = TicketController.createTicket(jsonPayload);
        Test.stopTest();

        Assert.isTrue(res.success, 'createTicket should succeed');
        Ticket__c created = (Ticket__c) res.data;
        Assert.isNotNull(created.Id, 'Created ticket should have Id');

        Ticket__c persisted = [SELECT Id, Summary__c, Ticket_Type__c, Sprint__c, StartDate__c, EndDate__c FROM Ticket__c WHERE Id = :created.Id LIMIT 1];
        Assert.areEqual('Created via Apex', persisted.Summary__c, 'Summary must match');
        Assert.areEqual(tt.Id, persisted.Ticket_Type__c, 'Ticket type must match');
        Assert.areEqual(sp.Id, persisted.Sprint__c, 'Sprint must match');
        // Creator__c should be set to the test project member
        Ticket__c withCreator = [SELECT Creator__c FROM Ticket__c WHERE Id = :created.Id LIMIT 1];
        Assert.isNotNull(withCreator.Creator__c, 'Creator__c should be set');
        Assert.areEqual(testPm.Id, withCreator.Creator__c, 'Creator__c should match the created project member');
    }

    @isTest
    static void testLoadTickets() {
        Test.startTest();
        APIResponse res = TicketController.loadTickets();
        Test.stopTest();

        Assert.isTrue(res.success, 'loadTickets should succeed');
        List<Ticket__c> tickets = (List<Ticket__c>) res.data;
        Assert.isTrue(tickets.size() >= 2, 'Should return at least the two setup tickets');
    }

    @isTest
    static void testLoadStatusesForProject() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Proj A' LIMIT 1];

        Test.startTest();
        APIResponse res = StatusController.loadStatuses(project.Id);
        Test.stopTest();

        Assert.isTrue(res.success, 'loadStatuses should succeed');
        List<Status__c> statuses = (List<Status__c>) res.data;
        Assert.areEqual(2, statuses.size(), 'Should return the two statuses created for the project');
    }
}

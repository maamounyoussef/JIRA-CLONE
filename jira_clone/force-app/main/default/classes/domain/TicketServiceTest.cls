@isTest
public class TicketServiceTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        List<Status__c> statuses = new List<Status__c>{
            new Status__c(Name = 'analyse1', Project__c = project.Id),
            new Status__c(Name = 'analyse2', Project__c = project.Id),
            new Status__c(Name = 'analyse3', Project__c = project.Id),
            new Status__c(Name = 'todo',     Project__c = project.Id)
        };
        insert statuses;
        Id defaultStateId = statuses[0].Id;

        Workflow__c workflow = new Workflow__c(Name = 'Default WF', Project__c = project.Id);
        insert workflow;

        TicketType__c tt = new TicketType__c(
            Name            = 'Feature Request',
            Project__c      = project.Id,
            Workflow__c     = workflow.Id,
            RecordStatus__c = 'active'
        );
        insert tt;

        Epic__c epic = new Epic__c(
            Name       = 'first epic',
            Summary__c = 'epic summary',
            Project__c = project.Id
        );
        insert epic;

        ProjectMember__c member = new ProjectMember__c(
            User__c         = UserInfo.getUserId(),
            Project__c      = project.Id,
            RecordStatus__c = 'Active'
        );
        insert member;

        List<Sprint__c> sprints = new List<Sprint__c>{
            new Sprint__c(Name = 'Sprint 3', Duration__c = 2, StartDate__c = Date.newInstance(2026, 4, 1),  Goal__c = 'dsadsadas', Project__c = project.Id, RecordStatus__c = 'future'),
            new Sprint__c(Name = 'sprint6',  Duration__c = 2, StartDate__c = Date.newInstance(2026, 4, 22), Goal__c = '2adsdas',   Project__c = project.Id, RecordStatus__c = 'future'),
            new Sprint__c(Name = 'dsf',      Duration__c = 3, StartDate__c = Date.newInstance(2026, 4, 30), Goal__c = 'd',         Project__c = project.Id, RecordStatus__c = 'future'),
            new Sprint__c(Name = 'dsad',     Duration__c = 2, StartDate__c = Date.newInstance(2026, 4, 22), Goal__c = '2',         Project__c = project.Id, RecordStatus__c = 'future')
        };
        insert sprints;
        Id sprint3Id = sprints[0].Id;
        Id sprint6Id = sprints[1].Id;

        List<Ticket__c> tickets = new List<Ticket__c>{
            new Ticket__c(Name = 'dddddddddd',      Summary__c = 'dddddddddddddddd', Description__c = 'ddddddddddddddddddd', CurrentState__c = defaultStateId, Priority__c = 'High',   StoryPoint__c = 3, AssignedTo__c = member.Id, Sprint__c = sprint3Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active'),
            new Ticket__c(Name = 'adfgfhhhhhhhhhh', Summary__c = 'sfdsf',            Description__c = 'dsfdsfds',            CurrentState__c = defaultStateId, Priority__c = 'High',   StoryPoint__c = 4, AssignedTo__c = member.Id, Sprint__c = sprint3Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active'),
            new Ticket__c(Name = 'saaaaaaa',         Summary__c = 'saaa',             Description__c = 'sa',                  CurrentState__c = defaultStateId, Priority__c = 'Medium', StoryPoint__c = 3, Epic__c = epic.Id,         Sprint__c = sprint6Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active')
        };
        insert tickets;
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private static Id getSprintId(String name) {
        return [SELECT Id FROM Sprint__c WHERE Name = :name LIMIT 1].Id;
    }

    private static Id getTicketId(String name) {
        return [SELECT Id FROM Ticket__c WHERE Name = :name LIMIT 1].Id;
    }

    // ── ticket tests ──────────────────────────────────────────────────────────

    // ── subtask tests ─────────────────────────────────────────────────────────

    @isTest
    static void testCreateAndFindSubtask() {
        Id ticketId = getTicketId('dddddddddd');

        Subtask__c sub = new Subtask__c();
        sub.Summary__c = 'Write unit tests';
        sub.Ticket__c  = ticketId;

        Test.startTest();
        Subtask__c created = TicketService.createSubtask(sub);
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Subtask should be inserted');
        System.assertEquals('active', created.RecordStatus__c, 'RecordStatus should default to active');

        Subtask__c found = TicketService.findSubtaskById(created.Id);
        System.assertNotEquals(null, found, 'findSubtaskById should return the record');
        System.assertEquals('Write unit tests', found.Summary__c);
    }

    @isTest
    static void testUpdateSubtaskSummary() {
        Id ticketId = getTicketId('dddddddddd');
        Subtask__c sub = new Subtask__c(Summary__c = 'Old summary', Ticket__c = ticketId);
        insert sub;

        Subtask__c fetched = TicketService.findSubtaskById(sub.Id);
        Test.startTest();
        Subtask__c updated = TicketService.updateSubtaskSummary(fetched, 'New summary');
        Test.stopTest();

        System.assertEquals('New summary', updated.Summary__c);
    }

    @isTest
    static void testDeleteSubtasks() {
        Id ticketId = getTicketId('dddddddddd');
        Subtask__c sub = new Subtask__c(Summary__c = 'To delete', Ticket__c = ticketId);
        insert sub;

        Test.startTest();
        TicketService.deleteSubtasks(new List<String>{ sub.Id });
        Test.stopTest();

        Subtask__c softDeleted = [SELECT RecordStatus__c FROM Subtask__c WHERE Id = :sub.Id];
        System.assertEquals('delete', softDeleted.RecordStatus__c, 'Should be soft-deleted');
    }

    @isTest
    static void testAssignSubtask() {
        Id ticketId = getTicketId('dddddddddd');
        Id memberId = [SELECT Id FROM ProjectMember__c LIMIT 1].Id;

        Subtask__c sub = new Subtask__c(Summary__c = 'Assign me', Ticket__c = ticketId);
        insert sub;

        Subtask__c fetched = TicketService.findSubtaskById(sub.Id);
        Test.startTest();
        Subtask__c updated = TicketService.assignSubtask(fetched, memberId);
        Test.stopTest();

        System.assertEquals(memberId, updated.Assignee__c, 'Assignee should be set');
    }

    // ── ticket type tests ─────────────────────────────────────────────────────

    @isTest
    static void testLoadTicketTypes() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        List<TicketType__c> types = TicketService.loadTicketTypes(project);
        Test.stopTest();

        System.assertNotEquals(0, types.size(), 'Should return at least one ticket type');
    }

    @isTest
    static void getTicketTypeById() {
        TicketType__c tt = [SELECT Id FROM TicketType__c LIMIT 1];

        Test.startTest();
        TicketType__c result = TicketService.getTicketTypeById(tt.Id);
        Test.stopTest();

        System.assertEquals(tt.Id, result.Id);
    }


    @isTest
    static void testCreateTicketType() {
        Id projectId  = [SELECT Id FROM Project__c LIMIT 1].Id;
        Id workflowId = [SELECT Id FROM Workflow__c LIMIT 1].Id;

        Test.startTest();
        TicketType__c created = TicketService.createTicketType('Story', 'A user story', null, workflowId, projectId);
        Test.stopTest();

        System.assertNotEquals(null, created.Id);
        System.assertEquals('active', created.RecordStatus__c);
    }

}

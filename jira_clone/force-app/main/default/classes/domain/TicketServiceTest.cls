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

        Workflow__c workflow = new Workflow__c(Name = 'Default WF', Project__c = project.Id, RecordStatus__c = 'active');
        insert workflow;

        TicketType__c tt = new TicketType__c(
            Name            = 'Feature Request',
            Description__c  = 'Feature Request description',
            IconUrl__c      = 'https://example.com/icon.png',
            Project__c      = project.Id,
            Workflow__c     = workflow.Id,
            RecordStatus__c = 'active'
        );
        insert tt;

        Epic__c epic = new Epic__c(
            Name        = 'first epic',
            Summary__c  = 'epic summary',
            Project__c  = project.Id,
            CreatedAt__c = Datetime.now(),
            UpdatedAt__c = Datetime.now()
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
            new Ticket__c(Name = 'dddddddddd',      Summary__c = 'dddddddddddddddd', Description__c = 'ddddddddddddddddddd', CurrentState__c = defaultStateId, Priority__c = 'High',   StoryPoint__c = 3, AssignedTo__c = member.Id, Creator__c = member.Id, Sprint__c = sprint3Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active'),
            new Ticket__c(Name = 'adfgfhhhhhhhhhh', Summary__c = 'sfdsf',            Description__c = 'dsfdsfds',            CurrentState__c = defaultStateId, Priority__c = 'High',   StoryPoint__c = 4, AssignedTo__c = member.Id, Creator__c = member.Id, Sprint__c = sprint3Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active'),
            new Ticket__c(Name = 'saaaaaaa',         Summary__c = 'saaa',             Description__c = 'sa',                  CurrentState__c = defaultStateId, Priority__c = 'Medium', StoryPoint__c = 3, Creator__c = member.Id, Epic__c = epic.Id,        Sprint__c = sprint6Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active')
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

    @isTest
    static void testCreateTicket() {
        Id ticketTypeId = [SELECT Id FROM TicketType__c WHERE Name = 'Feature Request' LIMIT 1].Id;
        Id sprintId     = getSprintId('Sprint 3');

        Ticket__c ticket = new Ticket__c(
            Name           = 'New Test Ticket',
            Summary__c     = 'New ticket summary',
            Description__c = 'New ticket description',
            Priority__c    = 'High',
            StoryPoint__c  = 5,
            Ticket_Type__c = ticketTypeId,
            Sprint__c      = sprintId
        );

        Test.startTest();
        CreateTicketResponse response = TicketService.createTicket(ticket);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.createdTicket, 'Created ticket should not be null');
        System.assertNotEquals(null, response.createdTicket.Id, 'Created ticket should have an Id');
        System.assertEquals('active', response.createdTicket.RecordStatus__c, 'RecordStatus should default to active');
        System.assertNotEquals(null, response.updatedSprint, 'Updated sprint should not be null when sprint is set');
    }

    // create status in sprint with choosing end status as current status >> should the total ended story point updated for the sprint
    @isTest
    static void testCreateTicketInSprintWithEndStatusUpdatesEndedStoryPoint() {
        Project__c project = new Project__c(Name = 'End Status Project');
        insert project;

        Status__c endStatus = [
            SELECT Id, isEnd__c
            FROM Status__c
            WHERE Project__c = :project.Id AND isEnd__c = true
            LIMIT 1
        ];

        Workflow__c workflow = new Workflow__c(
            Name            = 'End Status WF',
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert workflow;

        TicketType__c tt = new TicketType__c(
            Name            = 'Bug',
            Description__c  = 'Bug description',
            IconUrl__c      = 'https://example.com/icon.png',
            Project__c      = project.Id,
            Workflow__c     = workflow.Id,
            RecordStatus__c = 'active'
        );
        insert tt;

        ProjectMember__c member = new ProjectMember__c(
            User__c         = UserInfo.getUserId(),
            Project__c      = project.Id,
            RecordStatus__c = 'Active'
        );
        insert member;

        Sprint__c sprint = new Sprint__c(
            Name                    = 'EndStatusSprint',
            Duration__c             = 2,
            StartDate__c            = Date.newInstance(2026, 4, 1),
            Goal__c                 = 'goal',
            Project__c              = project.Id,
            RecordStatus__c         = 'future',
            TotalStoryPoint__c      = 0,
            TotalEndedStoryPoint__c = 0
        );
        insert sprint;

        Decimal storyPoints = 5;
        Ticket__c ticket = new Ticket__c(
            Name            = 'End Status Ticket',
            Summary__c      = 'Ticket starts in an end status',
            Description__c  = 'Story points should count as ended on creation',
            Priority__c     = 'High',
            StoryPoint__c   = storyPoints,
            Ticket_Type__c  = tt.Id,
            Sprint__c       = sprint.Id,
            CurrentState__c = endStatus.Id
        );

        Test.startTest();
        CreateTicketResponse response = TicketService.createTicket(ticket);
        Test.stopTest();

        System.assertNotEquals(null, response,                'Response should not be null');
        System.assertNotEquals(null, response.createdTicket,  'Created ticket should not be null');
        System.assertNotEquals(null, response.updatedSprint,  'Updated sprint should not be null when sprint is set');
        System.assertEquals(
            storyPoints,
            response.updatedSprint.TotalStoryPoint__c,
            'TotalStoryPoint should equal the ticket story points'
        );
        System.assertEquals(
            storyPoints,
            response.updatedSprint.TotalEndedStoryPoint__c,
            'TotalEndedStoryPoint should equal ticket story points when created in an end status'
        );
    }

}

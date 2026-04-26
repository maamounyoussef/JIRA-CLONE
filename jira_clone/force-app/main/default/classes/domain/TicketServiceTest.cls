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

    @isTest
    static void testGetActiveTicketsBySprintsOrderByPriorityAsc() {
        List<Sprint__c> futuredSprints = [SELECT Id FROM Sprint__c WHERE RecordStatus__c = 'future'];
        List<Id> sprintIds = new List<Id>();
        for (Sprint__c s : futuredSprints) sprintIds.add(s.Id);

        Test.startTest();
        Map<Id, List<Ticket__c>> result = TicketService.getActiveTicketsBySprintsOrderByPriorityAsc(sprintIds);
        Test.stopTest();

        Id sprint3Id = getSprintId('Sprint 3');
        Id sprint6Id = getSprintId('sprint6');
        Id dsfId     = getSprintId('dsf');
        Id dsadId    = getSprintId('dsad');

        System.assertEquals(futuredSprints.size(), result.size(), 'Map must contain one key per sprint');
        System.assertEquals(2, result.get(sprint3Id).size(), 'Sprint 3: 2 active tickets');
        System.assertEquals(1, result.get(sprint6Id).size(), 'sprint6: 1 active ticket');
        System.assertEquals(0, result.get(dsfId).size(),    'dsf: no tickets');
        System.assertEquals(0, result.get(dsadId).size(),   'dsad: no tickets');

        for (Id sid : result.keySet()) {
            for (Ticket__c t : result.get(sid)) {
                System.assertNotEquals('delete', t.RecordStatus__c, 'Deleted ticket must not appear: ' + t.Name);
            }
        }

        List<Ticket__c> s3 = result.get(sprint3Id);
        String   prevPriority = s3[0].Priority__c;
        DateTime prevEndDate  = s3[0].EndDate__c;
        for (Integer i = 1; i < s3.size(); i++) {
            String   currPriority = s3[i].Priority__c;
            DateTime currEndDate  = s3[i].EndDate__c;
            if (currPriority == prevPriority) {
                System.assert(currEndDate <= prevEndDate,
                    'Within same priority, EndDate__c must be DESC: ' + prevEndDate + ' -> ' + currEndDate);
            }
            prevPriority = currPriority;
            prevEndDate  = currEndDate;
        }
    }

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
    static void testGetSubtasksByTicket() {
        Id ticketId = getTicketId('dddddddddd');

        List<Subtask__c> subs = new List<Subtask__c>{
            new Subtask__c(Summary__c = 'Sub A', Ticket__c = ticketId),
            new Subtask__c(Summary__c = 'Sub B', Ticket__c = ticketId)
        };
        insert subs;

        Test.startTest();
        List<Subtask__c> result = TicketService.getSubtasksByTicket(ticketId);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 active subtasks');
    }

    @isTest
    static void testUpdateSubtaskSummary() {
        Id ticketId = getTicketId('dddddddddd');
        Subtask__c sub = new Subtask__c(Summary__c = 'Old summary', Ticket__c = ticketId);
        insert sub;

        Test.startTest();
        Subtask__c updated = TicketService.updateSubtaskSummary(sub.Id, 'New summary');
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

        Test.startTest();
        Subtask__c updated = TicketService.assignSubtask(sub.Id, memberId);
        Test.stopTest();

        System.assertEquals(memberId, updated.Assignee__c, 'Assignee should be set');
    }

    // ── ticket type tests ─────────────────────────────────────────────────────

    @isTest
    static void testLoadTicketTypes() {
        Id projectId = [SELECT Id FROM Project__c LIMIT 1].Id;

        Test.startTest();
        List<TicketType__c> types = TicketService.loadTicketTypes(projectId);
        Test.stopTest();

        System.assertNotEquals(0, types.size(), 'Should return at least one ticket type');
    }

    @isTest
    static void testGetTicketTypeByIdWithValidation() {
        TicketType__c tt = [SELECT Id FROM TicketType__c LIMIT 1];

        Test.startTest();
        TicketType__c result = TicketService.getTicketTypeByIdWithValidation(tt.Id);
        Test.stopTest();

        System.assertEquals(tt.Id, result.Id);
    }

    @isTest
    static void testGetTicketTypeByNameWithValidation() {
        TicketType__c tt = [SELECT Id, Name, Project__c FROM TicketType__c LIMIT 1];

        Test.startTest();
        TicketType__c result = TicketService.getTicketTypeByNameWithValidation(tt.Name, tt.Project__c);
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

    @isTest
    static void testGetTicketTypeByIdWithValidation_NotFound() {
        try {
            TicketService.getTicketTypeByIdWithValidation('001000000000000AAA');
            System.assert(false, 'Should have thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Ticket Type not found') || ex.getMessage().contains('Error'),
                'Expected not-found error');
        }
    }

    // ── subtask — excluded deleted ─────────────────────────────────────────────

    @isTest
    static void testGetSubtasksByTicket_ExcludesDeleted() {
        Id ticketId = getTicketId('dddddddddd');

        Subtask__c active  = new Subtask__c(Summary__c = 'Active',  Ticket__c = ticketId, RecordStatus__c = 'active');
        Subtask__c deleted = new Subtask__c(Summary__c = 'Deleted', Ticket__c = ticketId, RecordStatus__c = 'delete');
        insert new List<Subtask__c>{ active, deleted };

        Test.startTest();
        List<Subtask__c> result = TicketService.getSubtasksByTicket(ticketId);
        Test.stopTest();

        for (Subtask__c s : result) {
            System.assertNotEquals('delete', s.RecordStatus__c, 'Deleted subtask must not appear');
        }
    }
}

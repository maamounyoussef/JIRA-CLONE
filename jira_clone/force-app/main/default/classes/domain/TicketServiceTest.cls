@isTest
public class TicketServiceTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        // 4 statuses matching production shape
        List<Status__c> statuses = new List<Status__c>{
            new Status__c(Name = 'analyse1', Project__c = project.Id),
            new Status__c(Name = 'analyse2', Project__c = project.Id),
            new Status__c(Name = 'analyse3', Project__c = project.Id),
            new Status__c(Name = 'todo',     Project__c = project.Id)
        };
        insert statuses;
        Id defaultStateId = statuses[0].Id; // analyse1

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

        // 4 future sprints matching production shape
        List<Sprint__c> sprints = new List<Sprint__c>{
            new Sprint__c(Name = 'Sprint 3', Duration__c = 2, StartDate__c = Date.newInstance(2026, 4, 1),  Goal__c = 'dsadsadas', Project__c = project.Id, RecordStatus__c = 'future'),
            new Sprint__c(Name = 'sprint6',  Duration__c = 2, StartDate__c = Date.newInstance(2026, 4, 22), Goal__c = '2adsdas',   Project__c = project.Id, RecordStatus__c = 'future'),
            new Sprint__c(Name = 'dsf',      Duration__c = 3, StartDate__c = Date.newInstance(2026, 4, 30), Goal__c = 'd',         Project__c = project.Id, RecordStatus__c = 'future'),
            new Sprint__c(Name = 'dsad',     Duration__c = 2, StartDate__c = Date.newInstance(2026, 4, 22), Goal__c = '2',         Project__c = project.Id, RecordStatus__c = 'future')
        };
        insert sprints;
        Id sprint3Id = sprints[0].Id;
        Id sprint6Id = sprints[1].Id;
        // dsf and dsad intentionally have no tickets

        // Tickets: 2 in Sprint 3 (High), 1 in sprint6 (Medium) — matches production sprintTickets
        List<Ticket__c> tickets = new List<Ticket__c>{
            new Ticket__c(Name = 'dddddddddd',       Summary__c = 'dddddddddddddddd',  Description__c = 'ddddddddddddddddddd', CurrentState__c = defaultStateId, Priority__c = 'High',   StoryPoint__c = 3, AssignedTo__c = member.Id, Sprint__c = sprint3Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active'),
            new Ticket__c(Name = 'adfgfhhhhhhhhhh',  Summary__c = 'sfdsf',             Description__c = 'dsfdsfds',            CurrentState__c = defaultStateId, Priority__c = 'High',   StoryPoint__c = 4, AssignedTo__c = member.Id, Sprint__c = sprint3Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active'),
            new Ticket__c(Name = 'saaaaaaa',          Summary__c = 'saaa',              Description__c = 'sa',                  CurrentState__c = defaultStateId, Priority__c = 'Medium', StoryPoint__c = 3, Epic__c = epic.Id,         Sprint__c = sprint6Id, Ticket_Type__c = tt.Id, RecordStatus__c = 'active')
        };
        insert tickets;
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private static Id getSprintId(String name) {
        return [SELECT Id FROM Sprint__c WHERE Name = :name LIMIT 1].Id;
    }

    // ── tests ─────────────────────────────────────────────────────────────────

    @isTest
    static void testGetActiveTicketsBySprintsOrderByPriorityAsc() {
        //get all futured sprints
        List<Sprint__c> futuredSprints = [
            SELECT Id FROM Sprint__c WHERE RecordStatus__c = 'future'
        ];
        List<Id> sprintIds = new List<Id>();
        for (Sprint__c s : futuredSprints) sprintIds.add(s.Id);

        Test.startTest();
        //test getActiveTicketsBySprintsOrderByPriorityAsc
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

        // No deleted tickets anywhere in the result
        for (Id sid : result.keySet()) {
            for (Ticket__c t : result.get(sid)) {
                System.assertNotEquals('delete', t.RecordStatus__c, 'Deleted ticket must not appear: ' + t.Name);
            }
        }

        // Sprint 3 has 2 High-priority tickets — verify EndDate DESC within same priority
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
}

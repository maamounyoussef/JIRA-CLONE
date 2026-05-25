/**
 * @description Unit tests for TicketService
 */
@isTest
public class TicketServiceTest {

    @testSetup
    static void setupData() {
        Project__c project = new Project__c(Name = 'TestProject');
        insert project;

        ProjectMember__c member = new ProjectMember__c(
            Name            = 'Tester-' + UserInfo.getUserId(),
            User__c         = UserInfo.getUserId(),
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert member;

        Workflow__c workflow = new Workflow__c(Name = 'TestWorkflow', Project__c = project.Id, RecordStatus__c = 'active');
        insert workflow;

        Status__c todo = [SELECT Id FROM Status__c WHERE Project__c = :project.Id AND isStart__c = true LIMIT 1];
        Status__c done = [SELECT Id FROM Status__c WHERE Project__c = :project.Id AND isEnd__c   = true LIMIT 1];

        WorkflowTransition__c transition = new WorkflowTransition__c(
            Name            = 'todo to done',
            Workflow__c     = workflow.Id,
            FromStatus__c   = todo.Id,
            ToStatus__c     = done.Id,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE
        );
        insert transition;

        TicketType__c ticketType = new TicketType__c(
            Name            = 'Bug',
            Description__c  = 'Bug type',
            IconUrl__c      = 'icon',
            Workflow__c     = workflow.Id,
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert ticketType;
    }

    private static TicketType__c getTicketType() {
        return [SELECT Id, Name, Project__c, Workflow__c FROM TicketType__c LIMIT 1];
    }

    private static ProjectMember__c getMember() {
        return [SELECT Id FROM ProjectMember__c WHERE User__c = :UserInfo.getUserId() LIMIT 1];
    }

    private static Status__c startStatus() {
        TicketType__c tt = getTicketType();
        return [SELECT Id, isStart__c, isEnd__c FROM Status__c WHERE Project__c = :tt.Project__c AND isStart__c = true LIMIT 1];
    }

    private static Status__c endStatus() {
        TicketType__c tt = getTicketType();
        return [SELECT Id, isStart__c, isEnd__c FROM Status__c WHERE Project__c = :tt.Project__c AND isEnd__c = true LIMIT 1];
    }

    private static Sprint__c createSprint(String name) {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Sprint__c sprint = new Sprint__c(
            Name            = name,
            Project__c      = project.Id,
            Duration__c     = 14,
            StartDate__c    = Date.today(),
            Goal__c         = 'goal',
            RecordStatus__c = 'future'
        );
        return SprintService.createSprint(sprint);
    }

    private static Ticket__c buildTicket(String name, Integer storyPoint, Id stateId, Id sprintId) {
        TicketType__c tt = getTicketType();
        ProjectMember__c member = getMember();
        Ticket__c ticket = new Ticket__c();
        ticket.Name            = name;
        ticket.Summary__c      = name;
        ticket.Ticket_Type__c  = tt.Id;
        ticket.StoryPoint__c   = storyPoint;
        ticket.Creator__c      = member.Id;
        ticket.Description__c  = name + ' description';
        ticket.Priority__c     = 'Medium';
        ticket.RecordStatus__c = 'active';
        if (stateId != null)  ticket.CurrentState__c = stateId;
        if (sprintId != null) ticket.Sprint__c       = sprintId;
        return ticket;
    }

    // ─────────────────────────────────────────────────────────────
    // CREATE
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testCreateTicketInBacklog() {
        TicketType__c tt = getTicketType();
        Ticket__c ticket = buildTicket('TCK-001', 5, null, null);

        Test.startTest();
        CreateTicketResponse res = TicketService.createTicketWithoutSprint(ticket, tt);
        Test.stopTest();

        Assert.isNotNull(res.createdTicket.Id, 'Ticket should be created');
        Ticket__c saved = [SELECT Id, Sprint__c, RecordStatus__c FROM Ticket__c WHERE Id = :res.createdTicket.Id];
        Assert.areEqual(null, saved.Sprint__c, 'Backlog ticket should have no sprint');
        Assert.areEqual('active', saved.RecordStatus__c, 'Ticket should be active');
    }

    @isTest
    static void testCreateTicketInSprint() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-CreateInSprint');
        Ticket__c ticket = buildTicket('TCK-002', 5, null, sprint.Id);

        Test.startTest();
        CreateTicketResponse res = TicketService.createTicketWithSprint(ticket, tt);
        Test.stopTest();

        Assert.isNotNull(res.createdTicket.Id, 'Ticket should be created');
        Assert.areEqual(5, res.updatedSprint.TotalStoryPoint__c, 'Total story points should reflect ticket');
        Assert.areEqual(0, res.updatedSprint.TotalEndedStoryPoint__c, 'Ended story points should remain 0');
    }

    @isTest
    static void testCreateTicketInSprintWithEndStatus() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-CreateInSprintEnd');
        Ticket__c ticket = buildTicket('TCK-003', 8, endStatus().Id, sprint.Id);

        Test.startTest();
        CreateTicketResponse res = TicketService.createTicketWithSprint(ticket, tt);
        Test.stopTest();

        Assert.areEqual(8, res.updatedSprint.TotalStoryPoint__c, 'Total story points should reflect ticket');
        Assert.areEqual(8, res.updatedSprint.TotalEndedStoryPoint__c, 'Ended story points should equal ticket SP');
    }

    // ─────────────────────────────────────────────────────────────
    // CHANGE STATUS
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testChangeStatusBacklogTicket() {
        TicketType__c tt = getTicketType();
        Status__c todo = startStatus();
        Status__c done = endStatus();

        Ticket__c ticket = buildTicket('TCK-004', 5, todo.Id, null);
        TicketService.createTicketWithoutSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);
        List<WorkflowTransition__c> transitions = WorkflowService.getTransitionsByWorkflow(tt.Workflow__c);

        Test.startTest();
        ChangeTicketStateDto result = TicketService.changeTicketState(loaded, todo, done, transitions);
        Test.stopTest();

        Assert.isTrue(result.isEndStatus, 'Target should be end status');
        Assert.areEqual(null, result.updatedSprint, 'No sprint update for backlog ticket');
    }

    @isTest
    static void testChangeStatusSprintTicketToEndStatus() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-ChangeStatus');
        Status__c todo = startStatus();
        Status__c done = endStatus();

        Ticket__c ticket = buildTicket('TCK-005', 5, todo.Id, sprint.Id);
        TicketService.createTicketWithSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);
        List<WorkflowTransition__c> transitions = WorkflowService.getTransitionsByWorkflow(tt.Workflow__c);

        Test.startTest();
        ChangeTicketStateDto result = TicketService.changeTicketState(loaded, todo, done, transitions);
        Test.stopTest();

        Assert.isTrue(result.isEndStatus, 'Target should be end status');
        Assert.areEqual(5, result.updatedSprint.TotalEndedStoryPoint__c, 'Ended story points should increase by ticket SP');
    }

    // ─────────────────────────────────────────────────────────────
    // MOVE SPRINT <-> BACKLOG
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testMoveTicketFromSprintToBacklog() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-MoveOut');
        Ticket__c ticket = buildTicket('TCK-006', 5, startStatus().Id, sprint.Id);
        TicketService.createTicketWithSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c updated = TicketService.removeTicketSprint(loaded);
        Test.stopTest();

        Assert.areEqual(0, updated.TotalStoryPoint__c, 'Total story points should be 0 after move out');
        Assert.areEqual(0, updated.TotalEndedStoryPoint__c, 'Ended story points should remain 0');
    }

    @isTest
    static void testMoveEndedTicketFromSprintToBacklog() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-MoveOutEnd');
        Ticket__c ticket = buildTicket('TCK-007', 7, endStatus().Id, sprint.Id);
        TicketService.createTicketWithSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c updated = TicketService.removeTicketSprint(loaded);
        Test.stopTest();

        Assert.areEqual(0, updated.TotalStoryPoint__c, 'Total story points should be 0 after move out');
        Assert.areEqual(0, updated.TotalEndedStoryPoint__c, 'Ended story points should be 0 after move out');
    }

    @isTest
    static void testMoveTicketFromBacklogToSprint() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-MoveIn');
        Ticket__c ticket = buildTicket('TCK-008', 4, startStatus().Id, null);
        TicketService.createTicketWithoutSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c updated = TicketService.moveTicketToSprint(loaded, sprint);
        Test.stopTest();

        Assert.areEqual(4, updated.TotalStoryPoint__c, 'Total story points should increase by ticket SP');
        Assert.areEqual(0, updated.TotalEndedStoryPoint__c, 'Ended story points should remain 0');
    }

    @isTest
    static void testMoveEndedTicketFromBacklogToSprint() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-MoveInEnd');
        Ticket__c ticket = buildTicket('TCK-009', 6, endStatus().Id, null);
        TicketService.createTicketWithoutSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c updated = TicketService.moveTicketToSprint(loaded, sprint);
        Test.stopTest();

        Assert.areEqual(6, updated.TotalStoryPoint__c, 'Total story points should increase by ticket SP');
        Assert.areEqual(6, updated.TotalEndedStoryPoint__c, 'Ended story points should increase by ticket SP');
    }

    // ─────────────────────────────────────────────────────────────
    // DELETE SINGLE
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testDeleteTicketFromBacklog() {
        TicketType__c tt = getTicketType();
        Ticket__c ticket = buildTicket('TCK-010', 3, null, null);
        TicketService.createTicketWithoutSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c result = TicketService.deleteTicket(loaded);
        Test.stopTest();

        Assert.areEqual(null, result, 'No sprint should be returned for backlog delete');
        Ticket__c after = [SELECT RecordStatus__c FROM Ticket__c WHERE Id = :ticket.Id];
        Assert.areEqual('delete', after.RecordStatus__c, 'Ticket should be soft-deleted');
    }

    @isTest
    static void testDeleteTicketFromSprint() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-DeleteSingle');
        Ticket__c ticket = buildTicket('TCK-011', 5, startStatus().Id, sprint.Id);
        TicketService.createTicketWithSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c result = TicketService.deleteTicket(loaded);
        Test.stopTest();

        Assert.areEqual(0, result.TotalStoryPoint__c, 'Total story points should decrease by ticket SP');
        Assert.areEqual(0, result.TotalEndedStoryPoint__c, 'Ended story points should remain 0');
    }

    @isTest
    static void testDeleteEndedTicketFromSprint() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-DeleteEnded');
        Ticket__c ticket = buildTicket('TCK-012', 5, endStatus().Id, sprint.Id);
        TicketService.createTicketWithSprint(ticket, tt);

        Ticket__c loaded = TicketService.findTicketById(ticket.Id);

        Test.startTest();
        Sprint__c result = TicketService.deleteTicket(loaded);
        Test.stopTest();

        Assert.areEqual(0, result.TotalStoryPoint__c, 'Total story points should decrease by ticket SP');
        Assert.areEqual(0, result.TotalEndedStoryPoint__c, 'Ended story points should decrease by ticket SP');
    }

    // ─────────────────────────────────────────────────────────────
    // DELETE BULK
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testDeleteBulkFromBacklog() {
        TicketType__c tt = getTicketType();
        Ticket__c t1 = buildTicket('TCK-013', 2, null, null);
        Ticket__c t2 = buildTicket('TCK-014', 3, null, null);
        TicketService.createTicketWithoutSprint(t1, tt);
        TicketService.createTicketWithoutSprint(t2, tt);

        List<Ticket__c> tickets = [
            SELECT Id, Sprint__c, StoryPoint__c, CurrentState__c, RecordStatus__c
            FROM Ticket__c WHERE Id IN (:t1.Id, :t2.Id)
        ];

        Test.startTest();
        List<Sprint__c> result = TicketService.deleteTickets(tickets);
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'No sprint updates for backlog bulk delete');
        List<Ticket__c> after = [SELECT Id FROM Ticket__c WHERE Id IN (:t1.Id, :t2.Id) AND RecordStatus__c = 'delete'];
        Assert.areEqual(2, after.size(), 'Both tickets should be soft-deleted');
    }

    @isTest
    static void testDeleteBulkFromSprint() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-BulkDel');
        Ticket__c t1 = buildTicket('TCK-015', 2, startStatus().Id, sprint.Id);
        Ticket__c t2 = buildTicket('TCK-016', 3, startStatus().Id, sprint.Id);
        TicketService.createTicketWithSprint(t1, tt);
        TicketService.createTicketWithSprint(t2, tt);

        List<Ticket__c> tickets = [
            SELECT Id, Sprint__c, StoryPoint__c, CurrentState__c
            FROM Ticket__c WHERE Id IN (:t1.Id, :t2.Id)
        ];

        Test.startTest();
        List<Sprint__c> result = TicketService.deleteTickets(tickets);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'One sprint should be updated');
        Assert.areEqual(0, result[0].TotalStoryPoint__c, 'Total story points should be 0 after bulk delete');
        Assert.areEqual(0, result[0].TotalEndedStoryPoint__c, 'Ended story points should remain 0');
    }

    @isTest
    static void testDeleteBulkFromSprintWithEndStatus() {
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-BulkDelMix');
        Ticket__c t1 = buildTicket('TCK-017', 2, startStatus().Id, sprint.Id);
        Ticket__c t2 = buildTicket('TCK-018', 3, endStatus().Id, sprint.Id);
        TicketService.createTicketWithSprint(t1, tt);
        TicketService.createTicketWithSprint(t2, tt);

        List<Ticket__c> tickets = [
            SELECT Id, Sprint__c, StoryPoint__c, CurrentState__c
            FROM Ticket__c WHERE Id IN (:t1.Id, :t2.Id)
        ];

        Test.startTest();
        List<Sprint__c> result = TicketService.deleteTickets(tickets);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'One sprint should be updated');
        Assert.areEqual(0, result[0].TotalStoryPoint__c, 'Total story points should be 0 after bulk delete');
        Assert.areEqual(0, result[0].TotalEndedStoryPoint__c, 'Ended story points should be 0 after bulk delete');
    }

    // ─────────────────────────────────────────────────────────────
    // TICKET LINKS
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testGetTicketLinkedTo() {
        TicketType__c tt = getTicketType();
        Ticket__c fromTicket = buildTicket('TCK-019', 3, null, null);
        Ticket__c toTicket   = buildTicket('TCK-020', 5, null, null);
        TicketService.createTicketWithoutSprint(fromTicket, tt);
        TicketService.createTicketWithoutSprint(toTicket, tt);

        TicketService.linkToTicket(fromTicket, toTicket, tt, tt, 'Blocks');

        Test.startTest();
        List<TicketLinkToDto> result = TicketService.getTicketLinkedTo(fromTicket.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return one linked ticket');
        Assert.areEqual(toTicket.Id, result[0].linkedToTicket.Id, 'Linked ticket id should match toTicket');
        Assert.areEqual('Blocks', result[0].type, 'Link type should match');
        Assert.areEqual('TCK-020', result[0].linkedToTicket.Summary__c, 'Summary should match toTicket');
        Assert.isNotNull(result[0].linkId, 'Link id should be populated');
        Assert.isNotNull(result[0].linkedToTicket.CurrentState__c, 'Current status id should be populated');
    }

    @isTest
    static void testGetTicketLinkedToReturnsEmptyWhenNoLinks() {
        TicketType__c tt = getTicketType();
        Ticket__c ticket = buildTicket('TCK-021', 2, null, null);
        TicketService.createTicketWithoutSprint(ticket, tt);

        Test.startTest();
        List<TicketLinkToDto> result = TicketService.getTicketLinkedTo(ticket.Id);
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'Should return empty list when no links exist');
    }

    // ─────────────────────────────────────────────────────────────
    // MOVE TICKET POSITION (Score__c reorder)
    // ─────────────────────────────────────────────────────────────

    @isTest
    static void testMoveTicketPositionWithBeforeTicket() {
        // Sprint with three tickets created in order → scores '0', '1', '2'.
        // Move ticket3 right after ticket1 → new score should be '0' + '1' = '01'.
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-Move-WithBefore');

        Ticket__c t1 = buildTicket('TCK-MV-1', 1, null, sprint.Id);
        CreateTicketResponse response1 = TicketService.createTicketWithSprint(t1, tt);
        Ticket__c t2 = buildTicket('TCK-MV-2', 1, null, sprint.Id);
        TicketService.createTicketWithSprint(t2, tt);
        Ticket__c t3 = buildTicket('TCK-MV-3', 1, null, sprint.Id);
        TicketService.createTicketWithSprint(t3, tt);

        Ticket__c saved1 = [SELECT Id, Sprint__c, Ticket_Type__c, Score__c FROM Ticket__c WHERE Id = :t1.Id];
        Ticket__c saved2 = [SELECT Id, Sprint__c, Ticket_Type__c, Score__c FROM Ticket__c WHERE Id = :t2.Id];
        Ticket__c saved3 = [SELECT Id, Sprint__c, Ticket_Type__c, Score__c FROM Ticket__c WHERE Id = :t3.Id];

        Assert.areEqual('0', saved1.Score__c, 'First created ticket should get score 0');
        Assert.areEqual('1', saved2.Score__c, 'Second created ticket should get score 1');
        Assert.areEqual('2', saved3.Score__c, 'Third created ticket should get score 2');

        Test.startTest();
        TicketService.moveTicketPosition(saved3, saved1);
        Test.stopTest();

        Ticket__c after = [SELECT Score__c FROM Ticket__c WHERE Id = :saved3.Id];
        Assert.areEqual('01', after.Score__c,
            'Moved ticket should get beforeTicket.score + successor.score = "0" + "1"');

        // Confirm ASC order is now: t1 (0) → t3 (01) → t2 (1)
        List<Ticket__c> ordered = [
            SELECT Id, Score__c FROM Ticket__c
            WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
            ORDER BY Score__c ASC NULLS LAST
        ];
        Assert.areEqual(3, ordered.size(), 'Sprint should still have 3 active tickets');
        Assert.areEqual(saved1.Id, ordered[0].Id, 'First in order should be t1');
        Assert.areEqual(saved3.Id, ordered[1].Id, 'Second in order should be the moved t3');
        Assert.areEqual(saved2.Id, ordered[2].Id, 'Third in order should be t2');
    }

    @isTest
    static void testMoveTicketPositionWithNullBeforeTicket() {
        // Sprint with three tickets → scores '0','1','2'.
        // Move ticket3 to the top (beforeTicket=null) → new score is the
        // previous ASCII char of the current first score ('0' → '/').
        TicketType__c tt = getTicketType();
        Sprint__c sprint = createSprint('Sprint-Move-NullBefore');

        Ticket__c t1 = buildTicket('TCK-MV-N1', 1, null, sprint.Id);
        TicketService.createTicketWithSprint(t1, tt);
        Ticket__c t2 = buildTicket('TCK-MV-N2', 1, null, sprint.Id);
        TicketService.createTicketWithSprint(t2, tt);
        Ticket__c t3 = buildTicket('TCK-MV-N3', 1, null, sprint.Id);
        TicketService.createTicketWithSprint(t3, tt);

        Ticket__c saved3 = [SELECT Id, Sprint__c, Ticket_Type__c, Score__c FROM Ticket__c WHERE Id = :t3.Id];

        Test.startTest();
        TicketService.moveTicketPosition(saved3, null);
        Test.stopTest();

        Ticket__c after = [SELECT Score__c FROM Ticket__c WHERE Id = :saved3.Id];
        Assert.areEqual('/', after.Score__c,
            'Moved-to-top ticket should get previous ASCII char of first score "0" → "/"');

        List<Ticket__c> ordered = [
            SELECT Id, Score__c FROM Ticket__c
            WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
            ORDER BY Score__c ASC NULLS LAST
        ];
        Assert.areEqual(saved3.Id, ordered[0].Id, 'Moved ticket should now be first in ASC order');
    }
}

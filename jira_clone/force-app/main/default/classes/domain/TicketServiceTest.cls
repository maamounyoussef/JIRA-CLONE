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

        Workflow__c workflow = new Workflow__c(Name = 'TestWorkflow', Project__c = project.Id);
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
        Ticket__c ticket = new Ticket__c();
        ticket.Name           = name;
        ticket.Summary__c     = name;
        ticket.Ticket_Type__c = tt.Id;
        ticket.StoryPoint__c  = storyPoint;
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
}

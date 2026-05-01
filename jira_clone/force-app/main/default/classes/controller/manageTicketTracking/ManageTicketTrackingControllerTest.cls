@isTest
public class ManageTicketTrackingControllerTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        Status__c stTodo = new Status__c(Name = 'Todo', Project__c = project.Id);
        Status__c stDone = new Status__c(Name = 'Done', Project__c = project.Id);
        insert new List<Status__c>{ stTodo, stDone };

        Workflow__c workflow = new Workflow__c(Name = 'Default WF', Project__c = project.Id);
        insert workflow;

        TicketType__c ttBug = new TicketType__c(
            Name            = 'Bug',
            Project__c      = project.Id,
            Workflow__c     = workflow.Id,
            RecordStatus__c = 'active',
            Description__c  = 'Bug ticket type',
            IconUrl__c      = 'https://example.com/bug.png'
        );
        insert ttBug;

        WorkflowTransition__c transition = new WorkflowTransition__c(
            Name            = 'Todo to Done',
            Workflow__c     = workflow.Id,
            FromStatus__c   = stTodo.Id,
            ToStatus__c     = stDone.Id,
            RecordStatus__c = 'active'
        );
        insert transition;

        Sprint__c sprint = new Sprint__c(
            Name            = 'Sprint 1',
            Project__c      = project.Id,
            RecordStatus__c = 'in_progress',
            Duration__c     = 14,
            StartDate__c    = Date.today(),
            Goal__c         = 'Test goal'
        );
        insert sprint;

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        ProjectMember__c pm = new ProjectMember__c(
            User__c         = currentUser.Id,
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert pm;

        Ticket__c ticket = new Ticket__c(
            Name            = 'TCK-001',
            Summary__c      = 'Fix bug',
            Ticket_Type__c  = ttBug.Id,
            CurrentState__c = stTodo.Id,
            Sprint__c       = sprint.Id,
            RecordStatus__c = 'active',
            Creator__c      = pm.Id
        );
        insert ticket;
    }

    @isTest
    static void testLoadManageTicketTrackingPage_Success() {
        Id projectId = [SELECT Id FROM Project__c LIMIT 1].Id;

        Test.startTest();
        APIResponse res = ManageTicketTrackingController.loadManageTicketTrackingPage(projectId);
        Test.stopTest();

        System.assertEquals(true, res.success, 'Should succeed loading page data');
        System.assertNotEquals(null, res.data,  'Data should not be null');
    }

    @isTest
    static void testChangeTicketState_Success() {
        Ticket__c             ticket     = [SELECT Id FROM Ticket__c WHERE Name = 'TCK-001' LIMIT 1];
        Status__c             stDone     = [SELECT Id FROM Status__c WHERE Name = 'Done' LIMIT 1];
        Workflow__c           workflow   = [SELECT Id FROM Workflow__c LIMIT 1];
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];

        Test.startTest();
        APIResponse res = ManageTicketTrackingController.changeTicketState(
            ticket.Id, stDone.Id, workflow.Id, transition.Id
        );
        Test.stopTest();

        System.assertEquals(true, res.success, 'Should succeed changing ticket state');
        Ticket__c updated = [SELECT CurrentState__c FROM Ticket__c WHERE Id = :ticket.Id LIMIT 1];
        System.assertEquals(stDone.Id, updated.CurrentState__c, 'CurrentState should be updated to Done');
    }
}

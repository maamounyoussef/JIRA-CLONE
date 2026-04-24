@isTest
public class ManageBacklogControllerTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        // When create a project a status should be created automatically 
        Status__c stTodo = new Status__c(Name = 'todo', Project__c = project.Id);
        insert stTodo;

        Workflow__c workflow = new Workflow__c(Name = 'Default WF', Project__c = project.Id);
        insert workflow;

        // TicketType__c has RecordStatus__c field
        TicketType__c ttBug = new TicketType__c(
            Name = 'Bug',
            Project__c = project.Id,
            Workflow__c = workflow.Id,
            RecordStatus__c = 'active'
        );
        insert ttBug;
    }

    private static Id getTicketTypeId(String name) {
        return [SELECT Id FROM TicketType__c WHERE Name = :name LIMIT 1].Id;
    }

    private static Id getTodoStatusId() {
        return [SELECT Id FROM Status__c WHERE Name = 'Todo' LIMIT 1].Id;
    }

    @isTest
    static void testCreateTicket_MissingCurrentState() {
        Id typeId = getTicketTypeId('Bug');

        Test.startTest();
        APIResponse res = ManageBacklogController.createTicket(
            'TCK-001',       // name
            'Fix login bug', // summary
            typeId,          // ticketTypeId
            '',            // currentStateId — intentionally missing
            null,            // description
            null,            // storyPoint
            null,            // assignedToId
            null,            // epicId
            null,            // sprintId
            null             // priority
        );
        Test.stopTest();

        System.assertEquals(true, res.success, 'Should succeed when currentStateId is missing');
        System.assertNotEquals(null, res.data, 'Created ticket should be returned');

        Ticket__c created = [
            SELECT Id, Name, CurrentState__c
            FROM Ticket__c
            WHERE Name = 'TCK-001'
            LIMIT 1
        ];
        System.assertEquals(getTodoStatusId(), created.CurrentState__c, 'Trigger should default CurrentState__c to Todo');
    }
}

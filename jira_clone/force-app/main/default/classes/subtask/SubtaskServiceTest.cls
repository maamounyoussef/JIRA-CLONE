/**
 * @description Tests for Subtask operations referenced by ManageBacklog page
 */
@isTest
public class SubtaskServiceTest {

    static Ticket__c TEST_TICKET;

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'SubtaskProject');
        insert project;

        // Workflow for ticket types (required)
        Workflow__c wf = new Workflow__c(Name = 'WF Subtask', Project__c = project.Id);
        insert wf;

        TicketType__c tt = new TicketType__c(Name = 'Bug', Project__c = project.Id, Workflow__c = wf.Id);
        insert tt;

        // create status required by Ticket__c
        Status__c st = new Status__c(Name = 'To Do', Project__c = project.Id);
        insert st;

        // Create a Ticket__c directly (fields exist in the org)
        Ticket__c t = new Ticket__c(
            Name = 'SubTicket-1',
            Summary__c = 'Ticket for subtasks',
            Ticket_Type__c = tt.Id,
            CurrentState__c = st.Id
        );
        insert t;

        ProjectMember__c pm = new ProjectMember__c(Name = 'Member Sub', Project__c = project.Id);
        insert pm;

        // Fetch the ticket we just created
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];

        // assign to static test variable for easy reuse in tests
        TEST_TICKET = ticket;

        // Create two subtasks for the ticket
        Subtask__c s1 = new Subtask__c(Summary__c = 'Subtask A', Ticket__c = ticket.Id);
        insert s1;

        Subtask__c s2 = new Subtask__c(Summary__c = 'Subtask B', Ticket__c = ticket.Id);
        insert s2;
    }

    @isTest
    static void testLoadSubtasksByTicket() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];

        Test.startTest();
        List<Subtask__c> subs = SubtaskService.getSubtasksByTicket(ticket.Id);
        Test.stopTest();

        System.assertNotEquals(null, subs);
        System.assertEquals(2, subs.size(), 'Expect two subtasks for the ticket');
    }

    @isTest
    static void testUpdateSubtaskFields() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        Subtask__c s = [SELECT Id, Summary__c, Description__c FROM Subtask__c WHERE Ticket__c = :ticket.Id LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        // Update subtask using DTO with all fields
        SubtaskUpdateDto dto = new SubtaskUpdateDto(s.Id, 'Updated Summary', 'New Description', null, st.Id, null);
        SubtaskService.updateSubtask(dto);
        Test.stopTest();

        s = [SELECT Summary__c, Description__c FROM Subtask__c WHERE Id = :s.Id];
        System.assertEquals('Updated Summary', s.Summary__c, 'Summary should be updated');
        System.assertEquals('New Description', s.Description__c, 'Description should be updated');
    }

    @isTest
    static void testUpdateSubtaskSummary() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        Subtask__c s = [SELECT Id, Summary__c FROM Subtask__c WHERE Ticket__c = :ticket.Id LIMIT 1];

        Test.startTest();
        SubtaskService.updateSubtaskSummary(s.Id, 'Only Summary Updated');
        Test.stopTest();

        s = [SELECT Summary__c FROM Subtask__c WHERE Id = :s.Id];
        System.assertEquals('Only Summary Updated', s.Summary__c, 'Only summary should be updated');
    }

    @isTest
    static void testAssignSubtask() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'SubtaskProject' LIMIT 1];
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        Subtask__c s = [SELECT Id, Assignee__c FROM Subtask__c WHERE Ticket__c = :ticket.Id LIMIT 1];

        // Create a new project member to assign
        ProjectMember__c pm = new ProjectMember__c(Name = 'Member Sub 2', Project__c = project.Id);
        insert pm;

        Test.startTest();
        SubtaskService.assignSubtask(s.Id, pm.Id);
        Test.stopTest();

        s = [SELECT Assignee__c FROM Subtask__c WHERE Id = :s.Id];
        System.assertEquals(pm.Id, s.Assignee__c, 'Subtask should be assigned to the project member');
    }

    @isTest
    static void testDeleteSubtask() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        Subtask__c s = [SELECT Id FROM Subtask__c WHERE Ticket__c = :ticket.Id LIMIT 1];

        Test.startTest();
        SubtaskService.deleteSubtasks(new List<String>{s.Id});
        Test.stopTest();

        Integer remaining = [SELECT COUNT() FROM Subtask__c WHERE Ticket__c = :ticket.Id AND RecordStatus__c != 'delete'];
        System.assertEquals(1, remaining, 'One active subtask should remain after deletion');
    }

    @isTest
    static void testCreateSubtask() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        ProjectMember__c pm = [SELECT Id FROM ProjectMember__c WHERE Name = 'Member Sub' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        SubtaskCreateDto dto = new SubtaskCreateDto('New Subtask Summary', ticket.Id, 'New Subtask Description', pm.Id, st.Id, null, null);
        Subtask__c newSubtask = SubtaskService.createSubtask(dto);
        Test.stopTest();

        System.assertNotEquals(null, newSubtask.Id, 'Subtask should be created with an ID');
        System.assertEquals('New Subtask Summary', newSubtask.Summary__c, 'Summary should match');
        System.assertEquals('New Subtask Description', newSubtask.Description__c, 'Description should match');
        System.assertEquals(pm.Id, newSubtask.Assignee__c, 'Assignee should match');
        System.assertEquals(ticket.Id, newSubtask.Ticket__c, 'Ticket should match');
    }

    @isTest
    static void testCreateSubtaskMinimal() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];

        Test.startTest();
        SubtaskCreateDto dto = new SubtaskCreateDto('Minimal Subtask', ticket.Id);
        Subtask__c newSubtask = SubtaskService.createSubtask(dto);
        Test.stopTest();

        System.assertNotEquals(null, newSubtask.Id, 'Subtask should be created with an ID');
        System.assertEquals('Minimal Subtask', newSubtask.Summary__c, 'Summary should match');
        System.assertEquals(ticket.Id, newSubtask.Ticket__c, 'Ticket should match');
        System.assertEquals(null, newSubtask.Assignee__c, 'Assignee should be null when not provided');
    }

    @isTest
    static void testCreateSubtaskLegacy() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        ProjectMember__c pm = [SELECT Id FROM ProjectMember__c WHERE Name = 'Member Sub' LIMIT 1];

        Test.startTest();
        Subtask__c newSubtask = SubtaskService.createSubtaskLegacy('Legacy Summary', 'Legacy Description', pm.Id, ticket.Id);
        Test.stopTest();

        System.assertNotEquals(null, newSubtask.Id, 'Subtask should be created with an ID');
        System.assertEquals('Legacy Summary', newSubtask.Summary__c, 'Summary should match');
        System.assertEquals('Legacy Description', newSubtask.Description__c, 'Description should match');
        System.assertEquals(pm.Id, newSubtask.Assignee__c, 'Assignee should match');
        System.assertEquals(ticket.Id, newSubtask.Ticket__c, 'Ticket should match');
    }

    @isTest
    static void testGetSubtaskById() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];
        Subtask__c s = [SELECT Id FROM Subtask__c WHERE Ticket__c = :ticket.Id LIMIT 1];

        Test.startTest();
        Subtask__c retrieved = SubtaskService.getSubtaskById(s.Id);
        Test.stopTest();

        System.assertNotEquals(null, retrieved, 'Subtask should be retrieved');
        System.assertEquals(s.Id, retrieved.Id, 'Retrieved subtask should match the queried one');
    }

    @isTest
    static void testCreateSubtaskMissingRequiredSummary() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'SubTicket-1' LIMIT 1];

        Test.startTest();
        try {
            SubtaskCreateDto dto = new SubtaskCreateDto('', ticket.Id);
            SubtaskService.createSubtask(dto);
            System.assert(false, 'Should throw exception for missing summary');
        } catch (SubtaskException ex) {
            System.assert(ex.getMessage().contains('summary is required'), 'Should validate summary is required');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSubtaskMissingRequiredTicket() {
        Test.startTest();
        try {
            SubtaskCreateDto dto = new SubtaskCreateDto('Summary', null);
            SubtaskService.createSubtask(dto);
            System.assert(false, 'Should throw exception for missing ticketId');
        } catch (SubtaskException ex) {
            System.assert(ex.getMessage().contains('ticketId is required'), 'Should validate ticketId is required');
        }
        Test.stopTest();
    }


}

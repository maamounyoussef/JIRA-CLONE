/**
 * @description Test class for TicketController
 */
@isTest
public class TicketControllerTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'ControllerTestProject');
        insert project;

        Workflow__c wf = new Workflow__c(Name = 'WF Controller Test', Project__c = project.Id);
        insert wf;

        TicketType__c tt = new TicketType__c(Name = 'Feature', Project__c = project.Id, Workflow__c = wf.Id);
        insert tt;

        Status__c st = new Status__c(Name = 'In Progress', Project__c = project.Id);
        insert st;

        Status__c stTodo = new Status__c(Name = 'To Do', Project__c = project.Id);
        insert stTodo;

        Epic__c epic = new Epic__c(Name = 'Epic Controller Test',Summary__c= 'Epic summary', Project__c = project.Id);
        insert epic;

        Sprint__c sprint = new Sprint__c(Name = 'Sprint Controller Test', Project__c = project.Id);
        insert sprint;

        ProjectMember__c member = new ProjectMember__c(Name = 'Controller Test Member', Project__c = project.Id);
        insert member;

        Ticket__c t = new Ticket__c(
            Name = 'TICKET-CTRL-1',
            Summary__c = 'Test ticket',
            Ticket_Type__c = tt.Id,
            CurrentState__c = st.Id,
            Epic__c = epic.Id,
            Sprint__c = sprint.Id,
            AssignedTo__c = member.Id,
            Priority__c = 'Medium',
            StartDate__c = DateTime.now(),
            EndDate__c = DateTime.now().addDays(5),
            StoryPoint__c = 3
        );
        insert t;
    }

    @isTest
    static void testCreateTicket() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Feature' LIMIT 1];
        ProjectMember__c pm = [SELECT Id FROM ProjectMember__c WHERE Name = 'Controller Test Member' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'In Progress' LIMIT 1];

        Test.startTest();
        TicketCreateDto dto = new TicketCreateDto('New Ticket', 'New Summary', tt.Id, st.Id, 'New Description', 3, pm.Id, null, null, null);
        String dtoJson = JSON.serialize(dto);
        APIResponse response = TicketController.createTicket(dtoJson);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket should be created successfully');
        System.assertNotEquals(null, response.data, 'Response data should not be null');

        // Verify the created ticket contains all required fields
        Ticket__c createdTicket = (Ticket__c) response.data;
        System.assertEquals('New Ticket', createdTicket.Name, 'Ticket name should match');
        System.assertEquals('New Summary', createdTicket.Summary__c, 'Ticket summary should match');
        System.assertEquals('New Description', createdTicket.Description__c, 'Ticket description should match');
        System.assertEquals(3, createdTicket.StoryPoint__c, 'Ticket story points should match');
        System.assertEquals(tt.Id, createdTicket.Ticket_Type__c, 'Ticket type should match');
        System.assertEquals(pm.Id, createdTicket.AssignedTo__c, 'Assigned member should match');
    }

    @isTest
    static void testCreateTicketFull() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Feature' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        TicketCreateDto dto = new TicketCreateDto('Full Ticket', 'Full Summary', tt.Id, st.Id, 'Full Description', 5, null, null, null, null);
        String dtoJson = JSON.serialize(dto);
        APIResponse response = TicketController.createTicket(dtoJson);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket should be created successfully');
        System.assertNotEquals(null, response.data, 'Response data should not be null');
    }

    @isTest
    static void testUpdateTicket() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'In Progress' LIMIT 1];

        Test.startTest();
        TicketUpdateDto dto = new TicketUpdateDto(ticket.Id, 'Updated Summary', null, null, null, null, st.Id);
        String dtoJson = JSON.serialize(dto);
        APIResponse response = TicketController.updateTicket(dtoJson);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket should be updated successfully');
        System.assertNotEquals(null, response.data, 'Response data should not be null');
    }

    @isTest
    static void testUpdateTicketSummary() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];

        Test.startTest();
        APIResponse response = TicketController.updateTicketSummary(ticket.Id, 'Updated via Controller');
        Test.stopTest();

        System.assertEquals(true, response.success, 'Summary should be updated successfully');
    }

    @isTest
    static void testUpdateTicketPriority() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];

        Test.startTest();
        APIResponse response = TicketController.updateTicketPriority(ticket.Id, 'High');
        Test.stopTest();

        System.assertEquals(true, response.success, 'Priority should be updated successfully');
    }

    @isTest
    static void testAssignTicket() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'ControllerTestProject' LIMIT 1];
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];

        ProjectMember__c pm = new ProjectMember__c(Name = 'Controller Test Member', Project__c = project.Id);
        insert pm;

        Test.startTest();
        APIResponse response = TicketController.assignTicket(ticket.Id, pm.Id);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket should be assigned successfully');
    }

    @isTest
    static void testUpdateTicketState() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'In Progress' LIMIT 1];

        Test.startTest();
        APIResponse response = TicketController.updateTicketState(ticket.Id, st.Id);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket state should be updated successfully');
    }

    @isTest
    static void testDeleteTicket() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];

        Test.startTest();
        APIResponse response = TicketController.deleteTicket(ticket.Id);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket should be deleted successfully');
    }

    @isTest
    static void testCreateTicketWithEpicAndSprint() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Feature' LIMIT 1];
        Epic__c epic = [SELECT Id FROM Epic__c WHERE Name = 'Epic Controller Test' LIMIT 1];
        Sprint__c sprint = [SELECT Id FROM Sprint__c WHERE Name = 'Sprint Controller Test' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        TicketCreateDto dto = new TicketCreateDto('Ticket with Epic', 'Summary with Epic', tt.Id, st.Id, 'Description with Epic', 5, null, epic.Id, sprint.Id, null);
        String dtoJson = JSON.serialize(dto);
        APIResponse response = TicketController.createTicket(dtoJson);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket with Epic should be created successfully');
        System.assertNotEquals(null, response.data, 'Response data should not be null');
    }

    @isTest
    static void testUpdateTicketWithAllFields() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];
        ProjectMember__c pm = [SELECT Id FROM ProjectMember__c WHERE Name = 'Controller Test Member' LIMIT 1];

        Test.startTest();
        TicketUpdateDto dto = new TicketUpdateDto(
            ticket.Id,
            'Updated Summary with All Fields',
            'Updated Description',
            8,
            'High',
            pm.Id,
            st.Id
        );
        String dtoJson = JSON.serialize(dto);
        APIResponse response = TicketController.updateTicket(dtoJson);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket with all fields should be updated successfully');
        System.assertNotEquals(null, response.data, 'Response data should not be null');
    }

    @isTest
    static void testUpdateTicketStateToCompleted() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        APIResponse response = TicketController.updateTicketState(ticket.Id, st.Id);
        Test.stopTest();

        System.assertEquals(true, response.success, 'Ticket state should be updated to new status');

        // Verify the update
        Ticket__c updatedTicket = [SELECT Id, CurrentState__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals(st.Id, updatedTicket.CurrentState__c, 'CurrentState should be updated');
    }

    @isTest
    static void testAssignAndUpdateTicketPriority() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'ControllerTestProject' LIMIT 1];
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-CTRL-1' LIMIT 1];

        ProjectMember__c newMember = new ProjectMember__c(Name = 'New Test Member', Project__c = project.Id);
        insert newMember;

        Test.startTest();
        APIResponse assignResponse = TicketController.assignTicket(ticket.Id, newMember.Id);
        System.assertEquals(true, assignResponse.success, 'Ticket should be assigned successfully');

        APIResponse priorityResponse = TicketController.updateTicketPriority(ticket.Id, 'Critical');
        System.assertEquals(true, priorityResponse.success, 'Priority should be updated successfully');
        Test.stopTest();

        // Verify both updates
        Ticket__c updatedTicket = [SELECT Id, AssignedTo__c, Priority__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals(newMember.Id, updatedTicket.AssignedTo__c, 'AssignedTo should be updated');
        System.assertEquals('Critical', updatedTicket.Priority__c, 'Priority should be Critical');
    }

}
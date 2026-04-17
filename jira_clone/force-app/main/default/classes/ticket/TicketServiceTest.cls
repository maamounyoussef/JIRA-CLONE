/**
 * @description Tests for TicketService used by ManageBacklogController
 */
@isTest
public class TicketServiceTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'TicketProject');
        insert project;

        // Workflow and ticket type (Workflow__c is required on TicketType__c)
        Workflow__c wf = new Workflow__c(Name = 'WF Ticket', Project__c = project.Id);
        insert wf;

        TicketType__c tt = new TicketType__c(Name = 'Bug', Project__c = project.Id, Workflow__c = wf.Id);
        insert tt;

        // Create a status required by Ticket__c.CurrentState__c
        Status__c st = new Status__c(Name = 'To Do', Project__c = project.Id);
        insert st;

        // Create Ticket__c statically for tests
        Ticket__c t = new Ticket__c(
            Name = 'TICKET-1',
            Summary__c = 'Sample summary',
            Ticket_Type__c = tt.Id,
            CurrentState__c = st.Id,
            RecordStatus__c = 'active'
        );
        insert t;
    }

    @isTest
    static void testLoadTickets() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'TicketProject' LIMIT 1];
        Test.startTest();
        List<Ticket__c> tickets = TicketService.loadTickets(project.Id);
        Test.stopTest();

        System.assertNotEquals(null, tickets);
        System.assert(tickets.size() >= 1);
    }

    @isTest
    static void testGetTicketById() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];

        Test.startTest();
        Ticket__c retrieved = TicketService.getTicketById(ticket.Id);
        Test.stopTest();

        System.assertNotEquals(null, retrieved, 'Ticket should be retrieved');
        System.assertEquals(ticket.Id, retrieved.Id, 'Retrieved ticket should match');
    }

    @isTest
    static void testCreateTicket() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Bug' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        TicketCreateDto dto = new TicketCreateDto('New Ticket', 'New Summary', tt.Id, st.Id, 'New Description', 8, null, null, null, null);
        Ticket__c created = TicketService.createTicket(dto);
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Ticket should be created with an ID');
        System.assertEquals('New Ticket', created.Name, 'Name should match');
        System.assertEquals('New Summary', created.Summary__c, 'Summary should match');
        System.assertEquals('New Description', created.Description__c, 'Description should match');
        System.assertEquals(8, created.StoryPoint__c, 'StoryPoint should match');
        System.assertEquals(tt.Id, created.Ticket_Type__c, 'TicketType should match');
    }

    @isTest
    static void testCreateTicketMinimal() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Bug' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        TicketCreateDto dto = new TicketCreateDto('Minimal Ticket', 'Minimal Summary', tt.Id, st.Id);
        Ticket__c created = TicketService.createTicket(dto);
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Ticket should be created with an ID');
        System.assertEquals('Minimal Ticket', created.Name, 'Name should match');
        System.assertEquals('Minimal Summary', created.Summary__c, 'Summary should match');
        System.assertEquals(tt.Id, created.Ticket_Type__c, 'TicketType should match');
    }

    @isTest
    static void testCreateTicketLegacy() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Bug' LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'TicketProject' LIMIT 1];

        ProjectMember__c pm = new ProjectMember__c(Name = 'Service Test Member', Project__c = project.Id);
        insert pm;

        Test.startTest();
        Ticket__c created = TicketService.createTicketLegacy('Legacy Ticket', 'Legacy Summary', 'Legacy Description', 5, tt.Id, pm.Id);
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Ticket should be created with an ID');
        System.assertEquals('Legacy Ticket', created.Name, 'Name should match');
        System.assertEquals('Legacy Summary', created.Summary__c, 'Summary should match');
        System.assertEquals('Legacy Description', created.Description__c, 'Description should match');
        System.assertEquals(5, created.StoryPoint__c, 'StoryPoint should match');
        System.assertEquals(pm.Id, created.AssignedTo__c, 'Assignee should match');
    }

    @isTest
    static void testUpdateTicket() {
        Ticket__c ticket = [SELECT Id, Summary__c FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        TicketUpdateDto dto = new TicketUpdateDto(ticket.Id, 'Updated Summary', 'Updated Description', 10, 'Medium', null, st.Id);
        Ticket__c updated = TicketService.updateTicket(dto);
        Test.stopTest();

        ticket = [SELECT Id, Summary__c, Description__c, StoryPoint__c, Priority__c, CurrentState__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals('Updated Summary', ticket.Summary__c, 'Summary should be updated');
        System.assertEquals('Updated Description', ticket.Description__c, 'Description should be updated');
        System.assertEquals(10, ticket.StoryPoint__c, 'StoryPoint should be updated');
        System.assertEquals('Medium', ticket.Priority__c, 'Priority should be updated');
    }

    @isTest
    static void testUpdateTicketSummary() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];

        Test.startTest();
        Ticket__c updated = TicketService.updateTicketSummary(ticket.Id, 'Service Updated Summary');
        Test.stopTest();

        ticket = [SELECT Id, Summary__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals('Service Updated Summary', ticket.Summary__c, 'Summary should be updated');
    }

    @isTest
    static void testUpdateTicketPriority() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];

        Test.startTest();
        Ticket__c updated = TicketService.updateTicketPriority(ticket.Id, 'High');
        Test.stopTest();

        ticket = [SELECT Id, Priority__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals('High', ticket.Priority__c, 'Priority should be updated');
    }

    @isTest
    static void testAssignTicket() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'TicketProject' LIMIT 1];
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];

        ProjectMember__c pm = new ProjectMember__c(Name = 'Assign Test Member', Project__c = project.Id);
        insert pm;

        Test.startTest();
        Ticket__c updated = TicketService.assignTicket(ticket.Id, pm.Id);
        Test.stopTest();

        ticket = [SELECT Id, AssignedTo__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals(pm.Id, ticket.AssignedTo__c, 'Assignee should be updated');
    }

    @isTest
    static void testUpdateTicketState() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        Ticket__c updated = TicketService.updateTicketState(ticket.Id, st.Id);
        Test.stopTest();

        ticket = [SELECT Id, CurrentState__c FROM Ticket__c WHERE Id = :ticket.Id];
        System.assertEquals(st.Id, ticket.CurrentState__c, 'State should be updated');
    }

    @isTest
    static void testDeleteTicket() {
        Ticket__c ticket = [SELECT Id FROM Ticket__c WHERE Name = 'TICKET-1' LIMIT 1];

        Test.startTest();
        TicketService.deleteTickets(new List<String>{ticket.Id});
        Test.stopTest();

        Integer remaining = [SELECT COUNT() FROM Ticket__c WHERE Id = :ticket.Id AND RecordStatus__c != 'delete'];
        System.assertEquals(0, remaining, 'Ticket should be soft-deleted');
    }

    @isTest
    static void testCreateTicketMissingRequiredTicketType() {
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        try {
            TicketCreateDto dto = new TicketCreateDto('Name', 'Summary', null, st.Id);
            TicketService.createTicket(dto);
            System.assert(false, 'Should throw exception for missing ticketTypeId');
        } catch (TicketException ex) {
            System.assert(ex.getMessage().contains('ticket_type is required'), 'Should validate ticketTypeId is required');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateTicketMissingRequiredName() {
        TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Name = 'Bug' LIMIT 1];
        Status__c st = [SELECT Id FROM Status__c WHERE Name = 'To Do' LIMIT 1];

        Test.startTest();
        try {
            TicketCreateDto dto = new TicketCreateDto('', 'Summary', tt.Id, st.Id);
            TicketService.createTicket(dto);
            System.assert(false, 'Should throw exception for missing name');
        } catch (TicketException ex) {
            System.assert(ex.getMessage().contains('name is required'), 'Should validate name is required');
        }
        Test.stopTest();
    }
}

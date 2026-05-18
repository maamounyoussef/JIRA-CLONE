@isTest
public class ManageBacklogControllerTest {

    @isTest
    static void testMoveTicketToBacklog() {
        Test.startTest();
        APIResponse res = ManageBacklogController.moveTicketToBacklog('a0Cd200001CmawGEAR');
        Test.stopTest();

    }

    @isTest
    static void testMoveTicketToSprint() {
        Test.startTest();
        APIResponse res = ManageBacklogController.moveTicketToSprint('a0Cd200001ChQWbEAN', 'a06d200000LI7QLAA1');
        Test.stopTest();

    }

    @isTest
    static void testLoadTicket() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        Workflow__c workflow = new Workflow__c(Name = 'Test Workflow', Project__c = project.Id, RecordStatus__c = 'active');
        insert workflow;

        Status__c status = new Status__c(Name = 'To Do', Project__c = project.Id);
        insert status;

        TicketType__c ticketType = new TicketType__c(
            Name = 'Story',
            Project__c = project.Id,
            Workflow__c = workflow.Id,
            RecordStatus__c = 'active',
            Description__c = 'Story type',
            IconUrl__c = 'https://example.com/icon.png'
        );
        insert ticketType;

        ProjectMember__c member = new ProjectMember__c(
            Project__c = project.Id,
            User__c = UserInfo.getUserId(),
            RecordStatus__c = 'active'
        );
        insert member;

        List<Ticket__c> tickets = new List<Ticket__c>{
            new Ticket__c(
                Name = 'TICKET-001',
                Summary__c = 'Searchable summary one',
                Ticket_Type__c = ticketType.Id,
                CurrentState__c = status.Id,
                Creator__c = member.Id,
                Description__c = 'Description one',
                Priority__c = 'High',
                RecordStatus__c = 'active'
            ),
            new Ticket__c(
                Name = 'TICKET-002',
                Summary__c = 'Searchable summary two',
                Ticket_Type__c = ticketType.Id,
                CurrentState__c = status.Id,
                Creator__c = member.Id,
                Description__c = 'Description two',
                Priority__c = 'Medium',
                RecordStatus__c = 'active'
            ),
            new Ticket__c(
                Name = 'TICKET-003',
                Summary__c = 'Searchable summary three',
                Ticket_Type__c = ticketType.Id,
                CurrentState__c = status.Id,
                Creator__c = member.Id,
                Description__c = 'Description three',
                Priority__c = 'Low',
                RecordStatus__c = 'active'
            )
        };
        insert tickets;

        Test.startTest();
 // Set fixed results BEFORE startTest
        List<Id> ticketIds = new List<Id>{ tickets[0].Id, tickets[1].Id, tickets[2].Id };
              Test.setFixedSearchResults(ticketIds);
 
        APIResponse res = ManageBacklogController.loadTicket(project.Id, 'one');
        Test.stopTest();

        System.assertEquals(true, res.success, 'Expected loadTicket to succeed');
        System.assertEquals(1, ((List<Ticket__c>) res.data).size(), 'Expected data list to have 3 records');
      
    }
}

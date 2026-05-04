@isTest
public class ManageTicketTrackingControllerTest {

    @isTest(SeeAllData=true)
    static void testLoadManageTicketTrackingPage_Success() {
        // Id projectId = [SELECT Id FROM Project__c LIMIT 1].Id;

        Test.startTest();
        APIResponse res = ManageTicketTrackingController.loadManageTicketTrackingPage('a00d200002fOoZJAA0');
        Test.stopTest();

        System.assertEquals(true, res.success, 'Should succeed loading page data');
        System.assertNotEquals(null, res.data,  'Data should not be null');
    }

    @isTest
    static void testChangeTicketState_Success() {
        Ticket__c ticket = [SELECT Id, CurrentState__c FROM Ticket__c WHERE Name = 'TCK-001' LIMIT 1];
        Status__c stDone = [SELECT Id FROM Status__c WHERE Name = 'Done' LIMIT 1];

        Test.startTest();
        APIResponse res = ManageTicketTrackingController.changeTicketState(
            ticket.Id, ticket.CurrentState__c, stDone.Id
        );
        Test.stopTest();

        System.assertEquals(true, res.success, 'Should succeed changing ticket state');
        Ticket__c updated = [SELECT CurrentState__c FROM Ticket__c WHERE Id = :ticket.Id LIMIT 1];
        System.assertEquals(stDone.Id, updated.CurrentState__c, 'CurrentState should be updated to Done');
    }
}

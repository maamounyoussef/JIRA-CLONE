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
}

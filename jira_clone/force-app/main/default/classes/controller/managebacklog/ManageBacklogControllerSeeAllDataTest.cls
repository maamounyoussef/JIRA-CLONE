@isTest
public class ManageBacklogControllerSeeAllDataTest {

    /**
     * Isolated in its own class because @isTest(SeeAllData=true) cannot coexist
     * cleanly with the data-seeding tests in ManageBacklogControllerTest.
     */
    @isTest(SeeAllData=true)
    static void testLoadTicketBySearchTermSeeAllData() {
        Test.startTest();
        APIResponse res = ManageBacklogController.loadTicketBySearchTerm('a00d200002j4o2wAAA', 'aaa');
        Test.stopTest();

        System.debug('result : ' + res);
        Assert.isNotNull(res, 'Response should not be null');
        Assert.isTrue(res.success, 'loadTicketBySearchTerm should succeed; got: ' + res.message);
    }
}

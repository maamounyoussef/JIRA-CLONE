@isTest(SeeAllData=true)
public class LoadBacklogDataSeeAllDataTest {

    @isTest
    static void callLoadBacklogData() {
        Test.startTest();
        APIResponse result = ManageBacklogController.loadBacklogData('a00d200002j4o2wAAA');
        Test.stopTest();
        System.debug('==== loadBacklogData result ====');
        System.debug(JSON.serializePretty(result));
    }
}

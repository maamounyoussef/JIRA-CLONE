/**
 * @description Test class for ReportController.
 */
@isTest
public class ReportControllerTest {

    @isTest
    static void testLoadBurndownChart() {
        Test.startTest();
        APIResponse result = ReportController.loadBurndownChart();
        Test.stopTest();
        System.debug('loadBurndownChart result: ' + JSON.serializePretty(result));
    }
}

/**
 * @description Tests for StatusController createStatus behavior
 */
@isTest
public class StatusControllerTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'Status Test Project');
        insert project;

        // insert an initial status to test duplicate behavior
        Status__c existing = new Status__c(Name = 'Open', Project__c = project.Id);
        insert existing;
    }

    @isTest
    static void testCreateStatusSuccess() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        APIResponse res = StatusController.createStatus('In Progress', project.Id);
        Test.stopTest();

        System.assert(res.success, 'Creation should succeed for a unique name');
        System.assertNotEquals(null, res.data, 'Response data should contain the created status');
        Status__c created = (Status__c) res.data;
        System.assertEquals('In Progress', created.Name, 'Created status name should match');
    }

    @isTest
    static void testCreateStatusDuplicateName() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        APIResponse res = StatusController.createStatus('Open', project.Id);
        Test.stopTest();

        System.assert(!res.success, 'Creation should fail for duplicate name');
        System.assert(res.message.contains('already exists'), 'Error message should indicate duplicate name');
    }
}

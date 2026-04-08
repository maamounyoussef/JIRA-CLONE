/**
 * @description Test class for TicketTypeController
 * Tests all CRUD operations and ticket type management functions
 */
@isTest
public class TicketTypeControllerTest {
    
    /**
     * Create test data: Project and TicketTypes
     */
    @testSetup
    static void setupTestData() {
        // Create a test Project
        Project__c testProject = new Project__c(
            Name = 'Test Project'
        );
        insert testProject;
        
        // Create test TicketTypes
        List<TicketType__c> testTicketTypes = new List<TicketType__c>();
        testTicketTypes.add(new TicketType__c(Name = 'Bug', Project__c = testProject.Id));
        testTicketTypes.add(new TicketType__c(Name = 'Feature', Project__c = testProject.Id));
        testTicketTypes.add(new TicketType__c(Name = 'Task', Project__c = testProject.Id));
        insert testTicketTypes;
    }
    
    /**
     * Test loadTicketTypes method returns correct ticket types
     */
    @isTest
    static void testLoadTicketTypes() {
        // Get the test project from test data
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = TicketTypeController.loadTicketTypes(project.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<TicketType__c> ticketTypes = (List<TicketType__c>)result.data;
        Assert.areEqual(3, ticketTypes.size(), 'Should have 3 ticket types');
        Assert.isTrue(ticketTypes[0].Name.compareTo(ticketTypes[1].Name) <= 0, 'Ticket types should be sorted by name');
    }
    
    /**
     * Test getTicketTypeByName method returns correct ticket type
     */
    @isTest
    static void testGetTicketTypeByName() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = TicketTypeController.getTicketTypeByName('Bug', project.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        TicketType__c ticketType = (TicketType__c)result.data;
        Assert.areEqual('Bug', ticketType.Name, 'Ticket type name should match');
        Assert.areEqual(project.Id, ticketType.Project__c, 'Project Id should match');
    }
    
    /**
     * Test error handling - missing project id
     */
    @isTest
    static void testLoadTicketTypesWithMissingProjectId() {
        Test.startTest();
        APIResponse result = TicketTypeController.loadTicketTypes('');
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail with empty project Id');
        Assert.isTrue(result.message.contains('required'), 'Error message should mention required parameter');
    }
    
    /**
     * Test error handling - invalid project id
     */
    @isTest
    static void testLoadTicketTypesWithInvalidProjectId() {
        Test.startTest();
        APIResponse result = TicketTypeController.loadTicketTypes('invalidId12345');
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Should succeed but return empty list for invalid project');
        List<TicketType__c> ticketTypes = (List<TicketType__c>)result.data;
        Assert.areEqual(0, ticketTypes.size(), 'Should return empty list for invalid project');
    }
    
    /**
     * Test error handling - ticket type not found
     */
    @isTest
    static void testGetTicketTypeByNameNotFound() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = TicketTypeController.getTicketTypeByName('NonExistent', project.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail when ticket type not found');
        Assert.isTrue(result.message.contains('not found'), 'Error message should mention not found');
    }
    
    /**
     * Test error handling - missing parameters in getTicketTypeByName
     */
    @isTest
    static void testGetTicketTypeByNameWithMissingParams() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = TicketTypeController.getTicketTypeByName('', project.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail with empty ticket type name');
        Assert.isTrue(result.message.contains('required'), 'Error message should mention required parameter');
    }
}

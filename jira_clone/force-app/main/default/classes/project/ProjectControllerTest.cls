/**
 * @description Test class for ProjectController
 * Tests all CRUD operations and project management functions
 */
@isTest
public class ProjectControllerTest {
    
    /**
     * Create test data: Projects
     */
    @testSetup
    static void setupTestData() {
        // Create test Projects
        List<Project__c> testProjects = new List<Project__c>();
        testProjects.add(new Project__c(Name = 'Alpha Project'));
        testProjects.add(new Project__c(Name = 'Beta Project'));
        testProjects.add(new Project__c(Name = 'Gamma Project'));
        insert testProjects;
        
        // Create test Statuses for the first project
        Project__c project = testProjects[0];
        List<Status__c> testStatuses = new List<Status__c>();
        testStatuses.add(new Status__c(Name = 'To Do', Project__c = project.Id));
        testStatuses.add(new Status__c(Name = 'In Progress', Project__c = project.Id));
        testStatuses.add(new Status__c(Name = 'Done', Project__c = project.Id));
        insert testStatuses;
    }
    
    /**
     * Test loadProjects method returns all projects
     */
    @isTest
    static void testLoadProjects() {
        Test.startTest();
        APIResponse result = ProjectController.loadProjects();
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<Project__c> projects = (List<Project__c>)result.data;
        Assert.areEqual(3, projects.size(), 'Should have 3 projects');
        Assert.isTrue(projects[0].Name.compareTo(projects[1].Name) <= 0, 'Projects should be sorted by name');
    }
    
    /**
     * Test loadProjects with no data
     */
    @isTest
    static void testLoadProjectsEmpty() {
        // Delete all test data
        delete [SELECT Id FROM Project__c];
        
        Test.startTest();
        APIResponse result = ProjectController.loadProjects();
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<Project__c> projects = (List<Project__c>)result.data;
        Assert.areEqual(0, projects.size(), 'Should return empty list when no projects exist');
    }
    
    /**
     * Test getProjectByName method returns correct project
     */
    @isTest
    static void testGetProjectByName() {
        Test.startTest();
        APIResponse result = ProjectController.getProjectByName('Alpha Project');
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        Project__c project = (Project__c)result.data;
        Assert.areEqual('Alpha Project', project.Name, 'Project name should match');
    }
    
    /**
     * Test getProjectByName with different project
     */
    @isTest
    static void testGetProjectByNameBeta() {
        Test.startTest();
        APIResponse result = ProjectController.getProjectByName('Beta Project');
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        Project__c project = (Project__c)result.data;
        Assert.areEqual('Beta Project', project.Name, 'Project name should match');
    }
    
    /**
     * Test error handling - project not found
     */
    @isTest
    static void testGetProjectByNameNotFound() {
        Test.startTest();
        APIResponse result = ProjectController.getProjectByName('NonExistent Project');
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail when project not found');
        Assert.isTrue(result.message.contains('not found'), 'Error message should mention not found');
    }
    
    /**
     * Test error handling - empty project name
     */
    @isTest
    static void testGetProjectByNameEmpty() {
        Test.startTest();
        APIResponse result = ProjectController.getProjectByName('');
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail with empty project name');
        Assert.isTrue(result.message.contains('required'), 'Error message should mention required parameter');
    }
    
    /**
     * Test getProjectByName is case sensitive
     */
    @isTest
    static void testGetProjectByNameCaseSensitive() {
        Test.startTest();
        APIResponse result = ProjectController.getProjectByName('alpha project');
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail with wrong case');
        Assert.isTrue(result.message.contains('not found'), 'Error message should mention not found');
    }
    
    /**
     * Test getProjectStatuses method returns all project statuses
     */
    @isTest
    static void testGetProjectStatuses() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Alpha Project' LIMIT 1];
        
        Test.startTest();
        APIResponse result = ProjectController.getProjectStatuses(project.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<Status__c> statuses = (List<Status__c>)result.data;
        Assert.areEqual(3, statuses.size(), 'Should have 3 statuses');
    }
}
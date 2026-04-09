/**
 * @description Test class for WorkflowTransitionController
 * Tests workflow transition retrieval, including getWorkflowTransitionById
 */
@isTest
public class WorkflowTransitionControllerTest {
    
    /**
     * Create test data: Project, Workflow, Statuses, and Transitions
     */
    @testSetup
    static void setupTestData() {
        // Create a test Project
        Project__c testProject = new Project__c(
            Name = 'Test Project'
        );
        insert testProject;
        
        // Create test Statuses
        List<Status__c> testStatuses = new List<Status__c>();
        testStatuses.add(new Status__c(Name = 'To Do', Project__c = testProject.Id));
        testStatuses.add(new Status__c(Name = 'In Progress', Project__c = testProject.Id));
        testStatuses.add(new Status__c(Name = 'Done', Project__c = testProject.Id));
        insert testStatuses;
        
        // Create a test Workflow
        Workflow__c testWorkflow = new Workflow__c(
            Name = 'Test Workflow',
            Project__c = testProject.Id
        );
        insert testWorkflow;
        
        // Create test Workflow Transitions
        List<WorkflowTransition__c> testTransitions = new List<WorkflowTransition__c>();
        testTransitions.add(new WorkflowTransition__c(
            Name = 'To Do > In Progress',
            Workflow__c = testWorkflow.Id,
            FromStatus__c = testStatuses[0].Id,
            ToStatus__c = testStatuses[1].Id,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING
        ));
        testTransitions.add(new WorkflowTransition__c(
            Name = 'In Progress > Done',
            Workflow__c = testWorkflow.Id,
            FromStatus__c = testStatuses[1].Id,
            ToStatus__c = testStatuses[2].Id,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING
        ));
        insert testTransitions;
    }
    
    /**
     * Test loadTransitions method returns all transitions for a workflow
     */
    @isTest
    static void testLoadTransitions() {
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.loadTransitions(workflow.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<WorkflowTransition__c> transitions = (List<WorkflowTransition__c>)result.data;
        Assert.areEqual(2, transitions.size(), 'Should return 2 transitions');
    }

    /**
     * Test getWorkflowTransitionById method returns correct transition
     */
    @isTest
    static void testGetWorkflowTransitionById() {
        WorkflowTransition__c transition = [SELECT Id, Name, FromStatus__c, ToStatus__c 
                                            FROM WorkflowTransition__c 
                                            WHERE Name = 'To Do > In Progress' 
                                            LIMIT 1];
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.getWorkflowTransitionById(transition.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        WorkflowTransition__c retrievedTransition = (WorkflowTransition__c)result.data;
        Assert.areEqual(transition.Id, retrievedTransition.Id, 'Transition ID should match');
        Assert.areEqual(transition.Name, retrievedTransition.Name, 'Transition name should match');
        Assert.areEqual(transition.FromStatus__c, retrievedTransition.FromStatus__c, 'From status should match');
        Assert.areEqual(transition.ToStatus__c, retrievedTransition.ToStatus__c, 'To status should match');
    }

    /**
     * Test getWorkflowTransitionById with invalid ID returns error
     */
    @isTest
    static void testGetWorkflowTransitionByIdInvalid() {
        String invalidId = 'a0Ad2000006invalidx';
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.getWorkflowTransitionById(invalidId);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'API response should fail for invalid ID');
        Assert.isTrue(result.message.contains('not found'), 'Error message should indicate not found');
    }

    /**
     * Test createTransition method creates new transition
     */
    @isTest
    static void testCreateTransition() {
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        List<Status__c> statuses = [SELECT Id FROM Status__c LIMIT 2];
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.createTransition(
            'New Transition',
            workflow.Id,
            statuses[0].Id,
            statuses[1].Id,
            WorkflowConstants.RECORD_STATUS_PENDING
        );
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        WorkflowTransition__c createdTransition = (WorkflowTransition__c)result.data;
        Assert.areEqual('New Transition', createdTransition.Name, 'Transition name should match');
    }
}

/**
 * @description Test class for WorkflowController
 * Tests all CRUD operations and workflow management functions
 */
@isTest
public class WorkflowControllerTest {
    
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
        
        // Create test Workflow Transition
        WorkflowTransition__c testTransition = new WorkflowTransition__c(
            Name = 'To Do > In Progress',
            Workflow__c = testWorkflow.Id,
            FromStatus__c = testStatuses[0].Id,
            ToStatus__c = testStatuses[1].Id,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING
        );
        insert testTransition;
    }
    
    /**
     * Test getWorkflow method returns correct workflow data
     */
    @isTest
    static void testGetWorkflow() {
        // Get the test workflow from test data
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = WorkflowController.getWorkflow(workflow.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        WorkflowConfigDTO config = (WorkflowConfigDTO)result.data;
        Assert.isNotNull(config.workflow, 'Workflow object should not be null');
        Assert.areEqual(workflow.Id, config.workflow.id, 'Workflow ID should match');
        Assert.areEqual('Test Workflow', config.workflow.name, 'Workflow name should match');
        Assert.isTrue(config.workflow.transitions.size() > 0, 'Should have at least one transition');
        Assert.isTrue(config.projectStatus.size() > 0, 'Should have project statuses');
    }
    
    /**
     * Test addValidationRule method
     */
    @isTest
    static void testAddValidationRule() {
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = WorkflowController.addValidationRule(
            transition.Id,
            'Summary__c',
            WorkflowConstants.VALIDATION_TYPE_NOT_EQUALS
        );
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Add validation rule should succeed');
        Assert.isNotNull(result.data, 'Response data should not be null');
        ValidationRule__c rule = (ValidationRule__c)result.data;
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_PENDING, rule.RecordStatus__c, 
                       'New rule should have pending status');
        Assert.areEqual('Summary__c', rule.TicketField__c, 'Ticket field should match');
    }
    

    
    /**
     * Test deleteValidationRule method (soft delete)
     */
    @isTest
    static void testDeleteValidationRule() {
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        ValidationRule__c rule = new ValidationRule__c(
            WorkflowTransition__c = transition.Id,
            TicketField__c = 'Summary__c',
            Type__c = WorkflowConstants.VALIDATION_TYPE_NOT_EQUALS,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING
        );
        insert rule;
        
        Test.startTest();
        APIResponse result = WorkflowController.deleteValidationRule(rule.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Delete validation rule should succeed');
        
        // Verify soft delete
        ValidationRule__c deletedRule = [SELECT RecordStatus__c FROM ValidationRule__c WHERE Id = :rule.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_DELETED, deletedRule.RecordStatus__c, 
                       'Rule status should be deleted');
    }
    
    /**
     * Test addWorkflowTransition method
     */
    @isTest
    static void testAddWorkflowTransition() {
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        List<Status__c> statuses = [SELECT Id FROM Status__c LIMIT 2];
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.addWorkflowTransition(
            workflow.Id,
            'In Progress > Done',
            statuses[0].Id,
            statuses[1].Id
        );
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Add workflow transition should succeed');
        Assert.isNotNull(result.data, 'Response data should not be null');
        WorkflowTransition__c trans = (WorkflowTransition__c)result.data;
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_PENDING, trans.RecordStatus__c, 
                       'New transition should have pending status');
        Assert.areEqual('In Progress > Done', trans.Name, 'Transition name should match');
    }
    
    /**
     * Test activateValidationRule method
     */
    @isTest
    static void testActivateValidationRule() {
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        ValidationRule__c rule = new ValidationRule__c(
            WorkflowTransition__c = transition.Id,
            TicketField__c = 'Summary__c',
            Type__c = WorkflowConstants.VALIDATION_TYPE_NOT_EQUALS,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING
        );
        insert rule;
        
        Test.startTest();
        APIResponse result = WorkflowController.activateValidationRule(rule.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Activate validation rule should succeed');
        
        ValidationRule__c activatedRule = [SELECT RecordStatus__c FROM ValidationRule__c WHERE Id = :rule.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_ACTIVE, activatedRule.RecordStatus__c, 
                       'Rule status should be active');
    }
    
    /**
     * Test activateWorkflowTransition method
     */
    @isTest
    static void testActivateWorkflowTransition() {
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.activateWorkflowTransition(transition.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Activate transition should succeed');
        
        WorkflowTransition__c activatedTransition = [SELECT RecordStatus__c FROM WorkflowTransition__c WHERE Id = :transition.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_ACTIVE, activatedTransition.RecordStatus__c, 
                       'Transition status should be active');
    }
    
    /**
     * Test updateWorkflow method (bulk activate pending records)
     */
    @isTest
    static void testUpdateWorkflow() {
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        // Create a pending validation rule
        ValidationRule__c rule = new ValidationRule__c(
            WorkflowTransition__c = transition.Id,
            TicketField__c = 'Summary__c',
            Type__c = WorkflowConstants.VALIDATION_TYPE_NOT_EQUALS,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_PENDING
        );
        insert rule;
        
        Test.startTest();
        APIResponse result = WorkflowController.updateWorkflow(workflow.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Update workflow should succeed');
        
        // Verify all pending records are now active
        WorkflowTransition__c updatedTransition = [SELECT RecordStatus__c FROM WorkflowTransition__c WHERE Id = :transition.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_ACTIVE, updatedTransition.RecordStatus__c, 
                       'Transition should be active after workflow update');
        
        ValidationRule__c updatedRule = [SELECT RecordStatus__c FROM ValidationRule__c WHERE Id = :rule.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_ACTIVE, updatedRule.RecordStatus__c, 
                       'Rule should be active after workflow update');
    }
    
    /**
     * Test error handling - activating already active validation rule
     */
    @isTest
    static void testActivateAlreadyActiveRule() {
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        ValidationRule__c rule = new ValidationRule__c(
            WorkflowTransition__c = transition.Id,
            TicketField__c = 'Summary__c',
            Type__c = WorkflowConstants.VALIDATION_TYPE_NOT_EQUALS,
            RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE
        );
        insert rule;
        
        Test.startTest();
        APIResponse result = WorkflowController.activateValidationRule(rule.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail when trying to activate non-pending rule');
        Assert.isTrue(result.message.contains('pending'), 'Error message should mention pending status');
    }
    
    /**
     * Test error handling - activating already active workflow transition
     */
    @isTest
    static void testActivateAlreadyActiveWorkflowTransition() {
        // Get the test transition and set it to active
        WorkflowTransition__c transition = [SELECT Id, RecordStatus__c FROM WorkflowTransition__c LIMIT 1];
        transition.RecordStatus__c = WorkflowConstants.RECORD_STATUS_ACTIVE;
        update transition;
        
        Test.startTest();
        APIResponse result = WorkflowTransitionController.activateWorkflowTransition(transition.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail when trying to activate non-pending transition');
        Assert.isTrue(result.message.contains('pending'), 'Error message should mention pending status');
    }
}

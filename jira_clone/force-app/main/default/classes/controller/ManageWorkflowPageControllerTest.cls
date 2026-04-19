/**
 * @description Consolidated test class for ManageWorkflowPageController
 * Tests all CRUD operations for workflow, workflow transitions, and validation rules
 * Consolidates tests from WorkflowControllerTest and WorkflowTransitionControllerTest
 */
@isTest
public class ManageWorkflowPageControllerTest {
    
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
    
    // ==================== WORKFLOW TESTS ====================
    
    /**
     * Test getWorkflow method returns correct workflow data
     */
    @isTest
    static void testGetWorkflow() {
        // Get the test workflow from test data
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.getWorkflow(workflow.Id);
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
     * Test loadWorkflows method returns all workflows
     */
    @isTest
    static void testLoadWorkflows() {
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.loadWorkflows();
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<Workflow__c> workflows = (List<Workflow__c>)result.data;
        Assert.areEqual(1, workflows.size(), 'Should return 1 workflow');
    }
    
    /**
     * Test createWorkflow method creates new workflow
     */
    @isTest
    static void testCreateWorkflow() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.createWorkflow(
            'New Workflow',
            project.Id
        );
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        Workflow__c createdWorkflow = (Workflow__c)result.data;
        Assert.areEqual('New Workflow', createdWorkflow.Name, 'Workflow name should match');
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
        APIResponse result = ManageWorkflowPageController.updateWorkflow(workflow.Id);
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
     * Test getProjectStatuses method returns project statuses
     */
    @isTest
    static void testGetProjectStatuses() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.getProjectStatuses(project.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<Status__c> statuses = (List<Status__c>)result.data;
        Assert.areEqual(3, statuses.size(), 'Should return 3 statuses');
    }
    
    // ==================== WORKFLOW TRANSITION TESTS ====================
    
    /**
     * Test loadTransitions method returns all transitions for a workflow
     */
    @isTest
    static void testLoadTransitions() {
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.loadTransitions(workflow.Id);
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
        APIResponse result = ManageWorkflowPageController.getWorkflowTransitionById(transition.Id);
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
        APIResponse result = ManageWorkflowPageController.getWorkflowTransitionById(invalidId);
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
        APIResponse result = ManageWorkflowPageController.createTransition(
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
    
    /**
     * Test addWorkflowTransition method
     */
    @isTest
    static void testAddWorkflowTransition() {
        Workflow__c workflow = [SELECT Id FROM Workflow__c LIMIT 1];
        List<Status__c> statuses = [SELECT Id FROM Status__c LIMIT 2];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.addWorkflowTransition(
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
     * Test activateWorkflowTransition changes status from pending to active
     */
    @isTest
    static void testActivateWorkflowTransition() {
        WorkflowTransition__c transition = [SELECT Id, RecordStatus__c 
                                            FROM WorkflowTransition__c 
                                            WHERE Name = 'To Do > In Progress' 
                                            LIMIT 1];
        
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_PENDING, transition.RecordStatus__c, 'Initial status should be pending');
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.activateWorkflowTransition(transition.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        
        WorkflowTransition__c activatedTransition = [SELECT Id, RecordStatus__c 
                                                     FROM WorkflowTransition__c 
                                                     WHERE Id = :transition.Id 
                                                     LIMIT 1];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_ACTIVE, activatedTransition.RecordStatus__c, 'Status should be changed to active');
    }

    /**
     * Test activateWorkflowTransition fails when transition is not pending
     */
    @isTest
    static void testActivateWorkflowTransitionNotPending() {
        WorkflowTransition__c transition = [SELECT Id 
                                            FROM WorkflowTransition__c 
                                            WHERE Name = 'To Do > In Progress' 
                                            LIMIT 1];
        
        // First, activate the transition
        ManageWorkflowPageController.activateWorkflowTransition(transition.Id);
        
        Test.startTest();
        // Try to activate again - should fail
        APIResponse result = ManageWorkflowPageController.activateWorkflowTransition(transition.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'API response should fail when not pending');
        Assert.isTrue(result.message.contains('pending'), 'Error message should mention pending status');
    }

    /**
     * Test deleteWorkflowTransition performs soft delete by setting status to deleted
     */
    @isTest
    static void testDeleteWorkflowTransition() {
        WorkflowTransition__c transition = [SELECT Id, RecordStatus__c 
                                            FROM WorkflowTransition__c 
                                            WHERE Name = 'In Progress > Done' 
                                            LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.deleteWorkflowTransition(transition.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        
        WorkflowTransition__c deletedTransition = [SELECT Id, RecordStatus__c 
                                                   FROM WorkflowTransition__c 
                                                   WHERE Id = :transition.Id 
                                                   LIMIT 1];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_DELETED, deletedTransition.RecordStatus__c, 'Status should be changed to deleted');
    }

    /**
     * Test deleteWorkflowTransition with invalid ID returns error
     */
    @isTest
    static void testDeleteWorkflowTransitionInvalid() {
        String invalidId = 'a0Ad2000006invalidx';
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.deleteWorkflowTransition(invalidId);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'API response should fail for invalid ID');
        Assert.isTrue(result.message.contains('not found'), 'Error message should indicate not found');
    }
    
    // ==================== VALIDATION RULE TESTS ====================
    
    /**
     * Test addValidationRule method
     */
    @isTest
    static void testAddValidationRule() {
        WorkflowTransition__c transition = [SELECT Id FROM WorkflowTransition__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.addValidationRule(
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
        APIResponse result = ManageWorkflowPageController.deleteValidationRule(rule.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Delete validation rule should succeed');
        
        // Verify soft delete
        ValidationRule__c deletedRule = [SELECT RecordStatus__c FROM ValidationRule__c WHERE Id = :rule.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_DELETED, deletedRule.RecordStatus__c, 
                       'Rule status should be deleted');
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
        APIResponse result = ManageWorkflowPageController.activateValidationRule(rule.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Activate validation rule should succeed');
        
        ValidationRule__c activatedRule = [SELECT RecordStatus__c FROM ValidationRule__c WHERE Id = :rule.Id];
        Assert.areEqual(WorkflowConstants.RECORD_STATUS_ACTIVE, activatedRule.RecordStatus__c, 
                       'Rule status should be active');
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
        APIResponse result = ManageWorkflowPageController.activateValidationRule(rule.Id);
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
        APIResponse result = ManageWorkflowPageController.activateWorkflowTransition(transition.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Should fail when trying to activate non-pending transition');
        Assert.isTrue(result.message.contains('pending'), 'Error message should mention pending status');
    }
    
    // ==================== STATUS TESTS ====================
    
    /**
     * Test loadStatuses method returns all statuses for a project
     */
    @isTest
    static void testLoadStatuses() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.loadStatuses(project.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'API response should be successful');
        Assert.isNotNull(result.data, 'Response data should not be null');
        List<Status__c> statuses = (List<Status__c>)result.data;
        Assert.areEqual(3, statuses.size(), 'Should return 3 statuses');
    }
    
    /**
     * Test createStatus method creates a new status successfully
     */
    @isTest
    static void testCreateStatusSuccess() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.createStatus('In Review', project.Id);
        Test.stopTest();
        
        Assert.isTrue(result.success, 'Creation should succeed for a unique name');
        Assert.isNotNull(result.data, 'Response data should contain the created status');
        Status__c created = (Status__c)result.data;
        Assert.areEqual('In Review', created.Name, 'Created status name should match');
    }
    
    /**
     * Test createStatus method fails with duplicate name
     */
    @isTest
    static void testCreateStatusDuplicateName() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        Test.startTest();
        APIResponse result = ManageWorkflowPageController.createStatus('To Do', project.Id);
        Test.stopTest();
        
        Assert.isFalse(result.success, 'Creation should fail for duplicate name');
        Assert.isTrue(result.message.contains('already exists'), 'Error message should indicate duplicate name');
    }
}

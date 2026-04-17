/**
 * @description Tests for ManageBacklogController (manage backlog page aggregation)
 */
@isTest
public class ManageBacklogControllerTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'MBP Project');
        insert project;

        // Statuses (To Do, In Progress, Done)
        Status__c stTodo = new Status__c(Name = 'To Do', Project__c = project.Id);
        Status__c stInProgress = new Status__c(Name = 'In Progress', Project__c = project.Id);
        Status__c stDone = new Status__c(Name = 'Done', Project__c = project.Id);
        insert new List<Status__c>{stTodo, stInProgress, stDone};
        // keep `st` reference for compatibility with existing code (use To Do)
        Status__c st = stTodo;

        // Project member
        ProjectMember__c pm = new ProjectMember__c(Name = 'Member One', Project__c = project.Id);
        insert pm;

        // Epic (Summary__c is required)
        Epic__c e = new Epic__c(Name = 'EP-1', Project__c = project.Id, Summary__c = 'Epic summary');
        insert e;

        // Sprint
        Sprint__c sp = new Sprint__c(
            Name = 'Sprint 1',
            Project__c = project.Id,
            StartDate__c = Date.today(),
            Duration__c = 7,
            RecordStatus__c = 'future'
        );
        insert sp;

        // Workflow for ticket types (required by TicketType__c)
        Workflow__c wf = new Workflow__c(Name = 'Default WF', Project__c = project.Id);
        insert wf;

        // Ticket Type (requires Workflow__c)
        TicketType__c tt = new TicketType__c(Name = 'Bug', Project__c = project.Id, Workflow__c = wf.Id);
        insert tt;

        // Create multiple Ticket__c records manually so tests have sample data
        List<Ticket__c> ticketsToInsert = new List<Ticket__c>{
            new Ticket__c(
                Name = 'TCK-1',
                Summary__c = 'Sample summary 1',
                Ticket_Type__c = tt.Id,
                Sprint__c = sp.Id,
                Epic__c = e.Id,
                AssignedTo__c = pm.Id,
                CurrentState__c = st.Id,
                RecordStatus__c = 'active'
            ),
            new Ticket__c(
                Name = 'TCK-2',
                Summary__c = 'Sample summary 2',
                Ticket_Type__c = tt.Id,
                Sprint__c = sp.Id,
                Epic__c = e.Id,
                AssignedTo__c = pm.Id,
                CurrentState__c = st.Id,
                RecordStatus__c = 'active'

            ),
            new Ticket__c(
                Name = 'TCK-3',
                Summary__c = 'Sample summary 3',
                Ticket_Type__c = tt.Id,
                Sprint__c = sp.Id,
                Epic__c = e.Id,
                AssignedTo__c = pm.Id,
                CurrentState__c = st.Id,
                RecordStatus__c = 'active'

            )
        };
        insert ticketsToInsert;
    }

    @isTest
    static void testLoadBacklogDataSuccess() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'MBP Project' LIMIT 1];
        Test.startTest();
        APIResponse resp = ManageBacklogController.loadBacklogData(project.Id);
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertNotEquals(null, resp.data);

        Map<String, Object> data = (Map<String, Object>)resp.data;
        System.assert(data.containsKey('tickets'));
        System.assert(data.containsKey('sprints'));
        System.assert(data.containsKey('status'));
        System.assert(data.containsKey('members'));
        System.assert(data.containsKey('epics'));

        List<Sprint__c> sprints = (List<Sprint__c>)data.get('sprints');
        System.assert(sprints.size() >= 1, 'Expect at least one sprint');
    }

    @isTest
    static void testLoadBacklogDataEmptyProjectId() {
        Test.startTest();
        APIResponse resp = ManageBacklogController.loadBacklogData('');
        Test.stopTest();
        System.assertEquals(false, resp.success);
        System.assert(resp.message != null && resp.message.length() > 0);
    }

    @isTest
    static void testLoadBacklogDataInvalidProjectId() {
        Test.startTest();
        APIResponse resp = ManageBacklogController.loadBacklogData('000000000000000');
        Test.stopTest();
        System.assertEquals(false, resp.success);
    }

}
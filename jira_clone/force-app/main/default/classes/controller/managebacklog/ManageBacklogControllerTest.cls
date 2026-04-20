/**
 * @description Tests for ManageBacklogController (manage backlog page aggregation)
 */
@isTest
public class ManageBacklogControllerTest {

    @testSetup
    static void setupTestData() {
        // Create 3 projects
        Project__c p1 = new Project__c(Name = 'Project 1');
        Project__c p2 = new Project__c(Name = 'Project 2');
        Project__c p3 = new Project__c(Name = 'Project 3');
        insert new List<Project__c>{p1, p2, p3};

        // Statuses for project 1: Todo, In Progress, Done
        Status__c stTodo = new Status__c(Name = 'Todo', Project__c = p1.Id);
        Status__c stInProgress = new Status__c(Name = 'In Progress', Project__c = p1.Id);
        Status__c stDone = new Status__c(Name = 'Done', Project__c = p1.Id);
        insert new List<Status__c>{stTodo, stInProgress, stDone};

        // Project members: 2 per project
        List<ProjectMember__c> members = new List<ProjectMember__c>{
            new ProjectMember__c(Name = 'P1 Member 1', Project__c = p1.Id),
            new ProjectMember__c(Name = 'P1 Member 2', Project__c = p1.Id),
            new ProjectMember__c(Name = 'P2 Member 1', Project__c = p2.Id),
            new ProjectMember__c(Name = 'P2 Member 2', Project__c = p2.Id),
            new ProjectMember__c(Name = 'P3 Member 1', Project__c = p3.Id),
            new ProjectMember__c(Name = 'P3 Member 2', Project__c = p3.Id)
        };
        insert members;

        // Epic in project 1 (include 2 tickets later)
        Epic__c epic = new Epic__c(Name = 'EP-1', Project__c = p1.Id, Summary__c = 'Epic summary');
        insert epic;

        // Sprint in project 1
        Sprint__c sp = new Sprint__c(Name = 'Sprint 1', Project__c = p1.Id, StartDate__c = Date.today(), Duration__c = 7, RecordStatus__c = 'future');
        insert sp;

        // Workflow and TicketTypes for project 1
        Workflow__c wf = new Workflow__c(Name = 'Default WF', Project__c = p1.Id);
        insert wf;

        TicketType__c ttBug = new TicketType__c(Name = 'Bug', Project__c = p1.Id, Workflow__c = wf.Id);
        TicketType__c ttTask = new TicketType__c(Name = 'Task', Project__c = p1.Id, Workflow__c = wf.Id);
        TicketType__c ttStory = new TicketType__c(Name = 'User Story', Project__c = p1.Id, Workflow__c = wf.Id);
        insert new List<TicketType__c>{ttBug, ttTask, ttStory};

        // Create multiple tickets: 5 in project1, 1 in project2 (total 6)
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<String> ticketNames = new List<String>{'TCK-1','TCK-2','TCK-3','TCK-4','TCK-5','TCK-6'};
        if (gd.containsKey('Ticket__c')) {
            Schema.SObjectType ttype = gd.get('Ticket__c');
            Map<String, Schema.SObjectField> tfields = ttype.getDescribe().fields.getMap();

            List<SObject> toInsert = new List<SObject>();

            // specs: Name, Summary, TicketTypeId, ProjectId
            List<Map<String, Object>> specs = new List<Map<String, Object>>{
                new Map<String,Object>{'Name' => 'TCK-1', 'Summary' => 'Ticket 1', 'TypeId' => ttBug.Id, 'ProjectId' => p1.Id},
                new Map<String,Object>{'Name' => 'TCK-2', 'Summary' => 'Ticket 2', 'TypeId' => ttTask.Id, 'ProjectId' => p1.Id},
                new Map<String,Object>{'Name' => 'TCK-3', 'Summary' => 'Ticket 3', 'TypeId' => ttStory.Id, 'ProjectId' => p1.Id},
                new Map<String,Object>{'Name' => 'TCK-4', 'Summary' => 'Ticket 4', 'TypeId' => ttBug.Id, 'ProjectId' => p1.Id},
                new Map<String,Object>{'Name' => 'TCK-5', 'Summary' => 'Ticket 5', 'TypeId' => ttTask.Id, 'ProjectId' => p1.Id},
                new Map<String,Object>{'Name' => 'TCK-6', 'Summary' => 'Ticket 6', 'TypeId' => ttBug.Id, 'ProjectId' => p2.Id}
            };

            for (Integer i = 0; i < specs.size(); i++) {
                Map<String,Object> s = specs[i];
                SObject t = ttype.newSObject();
                if (tfields.containsKey('Name')) t.put('Name', s.get('Name'));
                if (tfields.containsKey('Summary__c')) t.put('Summary__c', s.get('Summary'));
                // set ticket type field (support both variants)
                if (tfields.containsKey('Ticket_Type__c')) t.put('Ticket_Type__c', s.get('TypeId'));
                if (tfields.containsKey('TicketType__c')) t.put('TicketType__c', s.get('TypeId'));
                // set project on ticket if field exists
                if (tfields.containsKey('Project__c')) t.put('Project__c', s.get('ProjectId'));
                // set default state to Todo if present
                if (tfields.containsKey('CurrentState__c')) t.put('CurrentState__c', stTodo.Id);
                else if (tfields.containsKey('Current_State__c')) t.put('Current_State__c', stTodo.Id);
                toInsert.add(t);
            }
            insert toInsert;

            // Link epic to exactly two project1 tickets (TCK-1 and TCK-2)
            List<Ticket__c> created = [SELECT Id, Name FROM Ticket__c WHERE Name IN :ticketNames];
            List<EpicLink__c> links = new List<EpicLink__c>();
            for (Ticket__c ct : created) {
                if (ct.Name == 'TCK-1' || ct.Name == 'TCK-2') {
                    links.add(new EpicLink__c(Epic__c = epic.Id, Ticket__c = ct.Id));
                }
            }
            if (!links.isEmpty()) insert links;

            // Create multiple subtasks for a ticket of type Task (use TCK-2 if present)
            List<Ticket__c> taskFound = [SELECT Id FROM Ticket__c WHERE Name = 'TCK-2' LIMIT 1];
            if (!taskFound.isEmpty() && gd.containsKey('Subtask__c')) {
                Id taskTicketId = taskFound[0].Id;
                Schema.SObjectType stype = gd.get('Subtask__c');
                Map<String, Schema.SObjectField> sfields = stype.getDescribe().fields.getMap();
                List<SObject> subs = new List<SObject>();
                for (Integer k = 1; k <= 3; k++) {
                    SObject sub = stype.newSObject();
                    if (sfields.containsKey('Name')) sub.put('Name', 'Subtask ' + k);
                    if (sfields.containsKey('Summary__c')) sub.put('Summary__c', 'Subtask summary ' + k);
                    if (sfields.containsKey('Ticket__c')) sub.put('Ticket__c', taskTicketId);
                    if (sfields.containsKey('CurrentState__c')) sub.put('CurrentState__c', stTodo.Id);
                    subs.add(sub);
                }
                if (!subs.isEmpty()) insert subs;
            }
        }
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

        List<Object> sprints = (List<Object>)data.get('sprints');
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
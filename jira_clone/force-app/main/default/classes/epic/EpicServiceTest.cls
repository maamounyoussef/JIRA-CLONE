/**
 * @description Tests for EpicService used by ManageBacklogController
 */
@isTest
public class EpicServiceTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'EpicProject');
        insert project;

        Epic__c e = new Epic__c(
            Name = 'Epic A',
            Summary__c = 'Epic A summary',
            Project__c = project.Id
        );
        insert e;
    }

    @isTest
    static void testGetEpicsByProject() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'EpicProject' LIMIT 1];

        Test.startTest();
        List<Epic__c> epics = EpicService.getEpicsByProject(project.Id);
        Test.stopTest();

        System.assertNotEquals(null, epics);
        System.assertEquals(1, epics.size());
        System.assertEquals('Epic A', epics[0].Name);
    }

    @isTest
    static void testGetEpicById() {
        Epic__c epic = [SELECT Id FROM Epic__c WHERE Name = 'Epic A' LIMIT 1];

        Test.startTest();
        Epic__c retrieved = EpicService.getEpicById(epic.Id);
        Test.stopTest();

        System.assertNotEquals(null, retrieved, 'Epic should be retrieved');
        System.assertEquals(epic.Id, retrieved.Id, 'Retrieved epic should match');
        System.assertEquals('Epic A', retrieved.Name, 'Name should match');
        System.assertEquals('Epic A summary', retrieved.Summary__c, 'Summary should match');
    }

    @isTest
    static void testCreateEpic() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'EpicProject' LIMIT 1];

        Test.startTest();
        EpicCreateDto dto = new EpicCreateDto(
            'New Epic',
            'New Epic Summary',
            project.Id,
            'New Epic Description',
            DateTime.now(),
            DateTime.now().addDays(30)
        );
        Epic__c created = EpicService.createEpic(dto);
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Epic should be created with an ID');
        System.assertEquals('New Epic', created.Name, 'Name should match');
        System.assertEquals('New Epic Summary', created.Summary__c, 'Summary should match');
        System.assertEquals('New Epic Description', created.Description__c, 'Description should match');
        System.assertEquals(project.Id, created.Project__c, 'Project should match');
    }

    @isTest
    static void testCreateEpicMinimal() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'EpicProject' LIMIT 1];

        Test.startTest();
        EpicCreateDto dto = new EpicCreateDto('Minimal Epic', 'Minimal Summary', project.Id);
        Epic__c created = EpicService.createEpic(dto);
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Epic should be created with an ID');
        System.assertEquals('Minimal Epic', created.Name, 'Name should match');
        System.assertEquals('Minimal Summary', created.Summary__c, 'Summary should match');
        System.assertEquals(project.Id, created.Project__c, 'Project should match');
        System.assertEquals(null, created.Description__c, 'Description should be null when not provided');
    }

    @isTest
    static void testUpdateEpic() {
        Epic__c epic = [SELECT Id FROM Epic__c WHERE Name = 'Epic A' LIMIT 1];

        Test.startTest();
        EpicUpdateDto dto = new EpicUpdateDto(
            epic.Id,
            'Updated Epic A',
            'Updated Summary',
            'Updated Description',
            DateTime.now(),
            DateTime.now().addDays(60)
        );
        Epic__c updated = EpicService.updateEpic(dto);
        Test.stopTest();

        System.assertNotEquals(null, updated.Id, 'Epic should be updated with an ID');
        System.assertEquals('Updated Epic A', updated.Name, 'Name should be updated');
        System.assertEquals('Updated Summary', updated.Summary__c, 'Summary should be updated');
        System.assertEquals('Updated Description', updated.Description__c, 'Description should be updated');
    }

    @isTest
    static void testUpdateEpicPartial() {
        Epic__c epic = [SELECT Id FROM Epic__c WHERE Name = 'Epic A' LIMIT 1];

        Test.startTest();
        EpicUpdateDto dto = new EpicUpdateDto(epic.Id, 'Updated Name', null, null, null, null);
        Epic__c updated = EpicService.updateEpic(dto);
        Test.stopTest();

        System.assertNotEquals(null, updated.Id, 'Epic should be updated with an ID');
        System.assertEquals('Updated Name', updated.Name, 'Name should be updated');
        System.assertEquals('Epic A summary', updated.Summary__c, 'Summary should remain unchanged');
    }

    @isTest
    static void testCreateEpicMissingName() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'EpicProject' LIMIT 1];

        Test.startTest();
        try {
            EpicCreateDto dto = new EpicCreateDto('', 'Summary', project.Id);
            EpicService.createEpic(dto);
            System.assert(false, 'Should throw exception for missing name');
        } catch (EpicException ex) {
            System.assert(ex.getMessage().contains('name is required'), 'Should validate name is required');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateEpicMissingSummary() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'EpicProject' LIMIT 1];

        Test.startTest();
        try {
            EpicCreateDto dto = new EpicCreateDto('Name', '', project.Id);
            EpicService.createEpic(dto);
            System.assert(false, 'Should throw exception for missing summary');
        } catch (EpicException ex) {
            System.assert(ex.getMessage().contains('summary is required'), 'Should validate summary is required');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateEpicInvalidProject() {
        Test.startTest();
        try {
            EpicCreateDto dto = new EpicCreateDto('Name', 'Summary', 'invalid-project-id');
            EpicService.createEpic(dto);
            System.assert(false, 'Should throw exception for invalid projectId');
        } catch (EpicException ex) {
            System.assert(ex.getMessage().contains('Invalid project'), 'Should validate project exists');
        }
        Test.stopTest();
    }
}

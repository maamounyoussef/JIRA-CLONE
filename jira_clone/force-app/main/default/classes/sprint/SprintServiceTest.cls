/**
 * @description Tests for SprintService - Tests refactored service layer with DTO/Mapper pattern
 */
@isTest
public class SprintServiceTest {

    @testSetup
    static void setupTestData() {
        Project__c project = new Project__c(Name = 'SprintProject');
        insert project;

        Sprint__c sp = new Sprint__c(
            Name = 'Sprint X',
            Project__c = project.Id,
            StartDate__c = Date.today(),
            Duration__c = 14,
            RecordStatus__c = 'future'
        );
        insert sp;

        Sprint__c sp2 = new Sprint__c(
            Name = 'Sprint Y',
            Project__c = project.Id,
            StartDate__c = Date.today().addDays(15),
            Duration__c = 14,
            RecordStatus__c = 'future'
        );
        insert sp2;
    }

    private static Project__c getProject() {
        return [SELECT Id FROM Project__c WHERE Name = 'SprintProject' LIMIT 1];
    }

    private static Sprint__c getSprint(String name) {
        return [SELECT Id, Name, Duration__c, StartDate__c, Goal__c, Project__c, RecordStatus__c FROM Sprint__c WHERE Name = :name LIMIT 1];
    }

    // ─────────────────────────────────────────────
    // loadSprints
    // ─────────────────────────────────────────────

    @isTest
    static void testLoadSprints_Success() {
        Project__c project = getProject();
        Test.startTest();
        List<Sprint__c> sprints = SprintService.loadSprints(project.Id);
        Test.stopTest();

        System.assertNotEquals(null, sprints);
        System.assertEquals(2, sprints.size());
        Sprint__c s = sprints[0];
        System.assertEquals(Date.today(), s.StartDate__c);
        System.assertEquals(14, s.Duration__c);
    }

    @isTest
    static void testLoadSprints_InvalidProjectId() {
        Test.startTest();
        try {
            SprintService.loadSprints(null);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('projectId is required'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // getSprintById
    // ─────────────────────────────────────────────

    @isTest
    static void testGetSprintById_Success() {
        Sprint__c sprint = getSprint('Sprint X');

        Test.startTest();
        Sprint__c result = SprintService.getSprintById(sprint.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(sprint.Id, result.Id);
        System.assertEquals('Sprint X', result.Name);
    }

    @isTest
    static void testGetSprintById_NotFound() {
        Test.startTest();
        try {
            SprintService.getSprintById('INVALID_ID');
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Sprint not found'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSprintById_NullId() {
        Test.startTest();
        try {
            SprintService.getSprintById(null);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('sprintId is required'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // createSprint (with DTO)
    // ─────────────────────────────────────────────

    @isTest
    static void testCreateSprint_Success() {
        Project__c project = getProject();

        Test.startTest();
        SprintCreateDto dto = new SprintCreateDto(
            'New Sprint',
            7,
            Date.today().addDays(30),
            'Sprint Goal',
            project.Id
        );
        Sprint__c created = SprintService.createSprint(dto);
        Test.stopTest();

        System.assertNotEquals(null, created.Id);
        System.assertEquals('New Sprint', created.Name);
        System.assertEquals(7, created.Duration__c);
        System.assertEquals('future', created.RecordStatus__c);
    }

    @isTest
    static void testCreateSprint_PartialFields() {
        Project__c project = getProject();

        Test.startTest();
        SprintCreateDto dto = new SprintCreateDto('Minimal Sprint', project.Id);
        Sprint__c created = SprintService.createSprint(dto);
        Test.stopTest();

        System.assertNotEquals(null, created.Id);
        System.assertEquals('Minimal Sprint', created.Name);
        System.assertEquals('future', created.RecordStatus__c);
        System.assertEquals(null, created.Duration__c);
    }

    @isTest
    static void testCreateSprint_InvalidProjectId() {
        Test.startTest();
        try {
            SprintCreateDto dto = new SprintCreateDto(
                'Sprint',
                7,
                Date.today(),
                'Goal',
                'INVALID_PROJECT_ID'
            );
            SprintService.createSprint(dto);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Invalid project'));
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSprint_NoName() {
        Project__c project = getProject();

        Test.startTest();
        try {
            SprintCreateDto dto = new SprintCreateDto(null, project.Id);
            SprintService.createSprint(dto);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('name is required'));
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSprint_NullDto() {
        Test.startTest();
        try {
            SprintService.createSprint((SprintCreateDto) null);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('SprintCreateDto is required'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // updateSprint (with DTO)
    // ─────────────────────────────────────────────

    @isTest
    static void testUpdateSprint_AllFields() {
        Sprint__c sprint = getSprint('Sprint X');

        Test.startTest();
        SprintUpdateDto dto = new SprintUpdateDto(
            sprint.Id,
            'Updated Sprint X',
            21,
            Date.today().addDays(1),
            'Updated Goal'
        );
        Sprint__c updated = SprintService.updateSprint(dto);
        Test.stopTest();

        System.assertEquals('Updated Sprint X', updated.Name);
        System.assertEquals(21, updated.Duration__c);
        System.assertEquals('Updated Goal', updated.Goal__c);
    }

    @isTest
    static void testUpdateSprint_PartialFields() {
        Sprint__c sprint = getSprint('Sprint X');
        String originalName = sprint.Name;

        Test.startTest();
        SprintUpdateDto dto = new SprintUpdateDto(sprint.Id);
        dto.goal = 'New Goal Only';
        Sprint__c updated = SprintService.updateSprint(dto);
        Test.stopTest();

        System.assertEquals(originalName, updated.Name, 'Name should not change');
        System.assertEquals('New Goal Only', updated.Goal__c);
    }

    @isTest
    static void testUpdateSprint_NullDto() {
        Test.startTest();
        try {
            SprintService.updateSprint(null);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('SprintUpdateDto is required'));
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateSprint_InvalidSprintId() {
        Test.startTest();
        try {
            SprintUpdateDto dto = new SprintUpdateDto('INVALID_ID', 'Name', null, null, null);
            SprintService.updateSprint(dto);
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Sprint not found'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // updateSprintName
    // ─────────────────────────────────────────────

    @isTest
    static void testUpdateSprintName_Success() {
        Sprint__c sprint = getSprint('Sprint X');

        Test.startTest();
        Sprint__c updated = SprintService.updateSprintName(sprint.Id, 'Renamed Sprint X');
        Test.stopTest();

        System.assertEquals('Renamed Sprint X', updated.Name);
    }

    @isTest
    static void testUpdateSprintName_InvalidSprintId() {
        Test.startTest();
        try {
            SprintService.updateSprintName('INVALID_ID', 'Name');
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Sprint not found'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // completeSprint
    // ─────────────────────────────────────────────

    @isTest
    static void testCompleteSprint_Success() {
        Sprint__c sprint = getSprint('Sprint X');

        Test.startTest();
        SprintService.completeSprint(sprint.Id);
        Test.stopTest();

        Sprint__c updated = getSprint('Sprint X');
        System.assertEquals('completed', updated.RecordStatus__c);
    }

    @isTest
    static void testCompleteSprint_InvalidSprintId() {
        Test.startTest();
        try {
            SprintService.completeSprint('INVALID_ID');
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Sprint not found'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // startSprint
    // ─────────────────────────────────────────────

    @isTest
    static void testStartSprint_Success() {
        Sprint__c sprint = getSprint('Sprint X');

        Test.startTest();
        SprintService.startSprint(sprint.Id);
        Test.stopTest();

        Sprint__c updated = getSprint('Sprint X');
        System.assertEquals('in_progress', updated.RecordStatus__c);
    }

    @isTest
    static void testStartSprint_InvalidSprintId() {
        Test.startTest();
        try {
            SprintService.startSprint('INVALID_ID');
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Sprint not found'));
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // deleteSprint
    // ─────────────────────────────────────────────

    @isTest
    static void testDeleteSprint_Success() {
        Sprint__c sprint = getSprint('Sprint Y');
        String sprintId = sprint.Id;

        Test.startTest();
        SprintService.deleteSprint(sprintId);
        Test.stopTest();

        List<Sprint__c> deleted = [SELECT Id FROM Sprint__c WHERE Id = :sprintId];
        System.assertEquals(0, deleted.size(), 'Sprint should be deleted');
    }

    @isTest
    static void testDeleteSprint_InvalidSprintId() {
        Test.startTest();
        try {
            SprintService.deleteSprint('INVALID_ID');
            System.assert(false, 'Expected SprintException');
        } catch (SprintException ex) {
            System.assert(ex.getMessage().contains('Error deleting sprint'));
        }
        Test.stopTest();
    }
}

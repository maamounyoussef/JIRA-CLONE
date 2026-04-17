/**
 * @description Test class for SprintController
 */
@IsTest
private class SprintControllerTest {

    // ─────────────────────────────────────────────
    // Test Data Setup
    // ─────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        Project__c project = new Project__c(
            Name = 'Test Project'
        );
        insert project;

        Sprint__c sprint = new Sprint__c(
            Name          = 'Test Sprint',
            Duration__c   = 14,
            StartDate__c  = Date.today(),
            Goal__c       = 'Test Goal',
            Project__c    = project.Id
        );
        insert sprint;
    }

    // ─────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────

    private static Sprint__c getSprint() {
        return [
            SELECT Id, Name, Duration__c, StartDate__c,
                   Goal__c, Project__c, RecordStatus__c
            FROM   Sprint__c
            LIMIT  1
        ];
    }

    private static Project__c getProject() {
        return [SELECT Id FROM Project__c LIMIT 1];
    }

    // ─────────────────────────────────────────────
    // createSprint
    // ─────────────────────────────────────────────

    @IsTest
    static void testCreateSprint_Success() {
        Project__c project = getProject();

        Test.startTest();
        String sprintCreateJson = JSON.serialize(new SprintCreateDto(
            'New Sprint',
            7,
            Date.today(),
            'Deliver feature X',
            project.Id
        ));
        APIResponse response = SprintController.createSprint(sprintCreateJson);
        Test.stopTest();

        System.assert(response.success, 'Expected successful response');
        System.assertEquals('Sprint created successfully', response.message, 'Unexpected message');
        System.assertNotEquals(null, response.data, 'Expected sprint data in response');
    }

    @IsTest
    static void testCreateSprint_SprintException() {
        Test.startTest();
        String sprintCreateJson = JSON.serialize(new SprintCreateDto(
            'Bad Sprint',
            7,
            Date.today(),
            'Goal',
            null  // invalid projectId → triggers SprintException
        ));
        APIResponse response = SprintController.createSprint(sprintCreateJson);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure response');
        System.assertNotEquals(null, response.message, 'Expected an error message');
    }

    @IsTest
    static void testCreateSprint_GenericException() {
        Test.startTest();
        String sprintCreateJson = JSON.serialize(new SprintCreateDto(
            'Bad Sprint',
            7,
            Date.today(),
            'Goal',
            'INVALID_ID_FORMAT'  // malformed Id → forces generic exception
        ));
        APIResponse response = SprintController.createSprint(sprintCreateJson);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure response');
        System.assertNotEquals(null, response.message, 'Expected error message');
    }

    // ─────────────────────────────────────────────
    // updateSprint
    // ─────────────────────────────────────────────

    @IsTest
    static void testUpdateSprint_AllFields_Success() {
        Sprint__c sprint = getSprint();

        Test.startTest();
        String sprintUpdateJson = JSON.serialize(new SprintUpdateDto(
            sprint.Id,
            'Updated Sprint Name',
            21,
            Date.today().addDays(1),
            'Updated Goal'
        ));
        APIResponse response = SprintController.updateSprint(sprintUpdateJson);
        Test.stopTest();

        System.assert(response.success, 'Expected successful update');
        System.assertEquals('Sprint updated successfully', response.message);
        System.assertNotEquals(null, response.data, 'Expected sprint data returned');
    }

    @IsTest
    static void testUpdateSprint_NullFields_Skipped() {
        Sprint__c sprint = getSprint();

        Test.startTest();
        SprintUpdateDto dto = new SprintUpdateDto(sprint.Id);
        dto.name = 'Partial Update';
        String sprintUpdateJson = JSON.serialize(dto);
        APIResponse response = SprintController.updateSprint(sprintUpdateJson);
        Test.stopTest();

        System.assert(response.success, 'Expected successful partial update');
        System.assertEquals('Sprint updated successfully', response.message);
    }

    @IsTest
    static void testUpdateSprint_SprintException() {
        Test.startTest();
        String sprintUpdateJson = JSON.serialize(new SprintUpdateDto(
            null,  // invalid sprintId → SprintException
            'Name',
            7,
            Date.today(),
            'Goal'
        ));
        APIResponse response = SprintController.updateSprint(sprintUpdateJson);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on null sprintId');
        System.assertNotEquals(null, response.message);
    }

    @IsTest
    static void testUpdateSprint_GenericException() {
        Test.startTest();
        String sprintUpdateJson = JSON.serialize(new SprintUpdateDto(
            'INVALID_ID',  // bad Id format → generic exception
            'Name',
            7,
            Date.today(),
            'Goal'
        ));
        APIResponse response = SprintController.updateSprint(sprintUpdateJson);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on bad sprintId');
        System.assertNotEquals(null, response.message);
    }

    // ─────────────────────────────────────────────
    // completeSprint
    // ─────────────────────────────────────────────

    @IsTest
    static void testCompleteSprint_Success() {
        Sprint__c sprint = getSprint();

        Test.startTest();
        APIResponse response = SprintController.completeSprint(sprint.Id);
        Test.stopTest();

        System.assert(response.success, 'Expected successful completion');
        System.assertEquals('Sprint completed', response.message);
    }

    @IsTest
    static void testCompleteSprint_SprintException() {
        Test.startTest();
        APIResponse response = SprintController.completeSprint(null);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on null sprintId');
        System.assertNotEquals(null, response.message);
    }

    @IsTest
    static void testCompleteSprint_GenericException() {
        Test.startTest();
        APIResponse response = SprintController.completeSprint('INVALID_ID');
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on bad sprintId');
        System.assertNotEquals(null, response.message);
    }

    // ─────────────────────────────────────────────
    // deleteSprint
    // ─────────────────────────────────────────────

    @IsTest
    static void testDeleteSprint_Success() {
        Sprint__c sprint = getSprint();

        Test.startTest();
        APIResponse response = SprintController.deleteSprint(sprint.Id);
        Test.stopTest();

        System.assert(response.success, 'Expected successful deletion');
        System.assertEquals('Sprint deleted', response.message);
    }

    @IsTest
    static void testDeleteSprint_SprintException() {
        Test.startTest();
        APIResponse response = SprintController.deleteSprint(null);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on null sprintId');
        System.assertNotEquals(null, response.message);
    }

    @IsTest
    static void testDeleteSprint_GenericException() {
        Test.startTest();
        APIResponse response = SprintController.deleteSprint('INVALID_ID');
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on bad sprintId');
        System.assertNotEquals(null, response.message);
    }

    // ─────────────────────────────────────────────
    // startSprint
    // ─────────────────────────────────────────────

    @IsTest
    static void testStartSprint_Success() {
        Sprint__c sprint = getSprint();

        Test.startTest();
        APIResponse response = SprintController.startSprint(sprint.Id);
        Test.stopTest();

        System.assert(response.success, 'Expected successful start');
        System.assertEquals('Sprint started', response.message);
    }

    @IsTest
    static void testStartSprint_SprintException() {
        Test.startTest();
        APIResponse response = SprintController.startSprint(null);
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on null sprintId');
        System.assertNotEquals(null, response.message);
    }

    @IsTest
    static void testStartSprint_GenericException() {
        Test.startTest();
        APIResponse response = SprintController.startSprint('INVALID_ID');
        Test.stopTest();

        System.assert(!response.success, 'Expected failure on bad sprintId');
        System.assertNotEquals(null, response.message);
    }
}
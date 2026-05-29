/**
 * Custom, self-contained governor-limit measurement for loading EVERY Ticket__c
 * row in the org. The SOQL is INLINE — this test does not call any controller
 * or service method, so the numbers reflect only the cost of the query itself
 * plus the cursor iteration.
 *
 * Fields enumerated from force-app/main/default/objects/Ticket__c/fields/.
 * SeeAllData=true is required because the goal is to measure against the real
 * production data set, not rows inserted by the test.
 *
 * Excludes soft-deleted rows per the soql-exclude-deleted project rule.
 */
@isTest(SeeAllData=true)
public class LoadAllTicketsGovernorTest {

    @isTest
    static void measureLoadAllTicketsGovernorUsage() {

        Test.startTest();

        Integer soqlBefore     = Limits.getQueries();
        Integer queryRowBefore = Limits.getQueryRows();
        Integer heapBefore     = Limits.getHeapSize();
        Integer cpuBefore      = Limits.getCpuTime();
        Long    wallBefore     = System.currentTimeMillis();

        List<Ticket__c> tickets = [
            SELECT
                Id,
                Name,
                CreatedDate,
                LastModifiedDate,
                OwnerId,
                CreatedById,
                LastModifiedById,
                SystemModstamp,
                AssignedTo__c,
                Creator__c,
                CurrentState__c,
                Description__c,
                EndDate__c,
                Epic__c,
                Priority__c,
                RecordStatus__c,
                Score__c,
                Sprint__c,
                StartDate__c,
                StoryPoint__c,
                Summary__c,
                Ticket_Type__c
            FROM Ticket__c
            WHERE RecordStatus__c != 'delete'
        ];

        Long    wallAfter     = System.currentTimeMillis();
        Integer cpuUsed       = Limits.getCpuTime()    - cpuBefore;
        Integer heapUsed      = Limits.getHeapSize()   - heapBefore;
        Integer soqlUsed      = Limits.getQueries()    - soqlBefore;
        Integer queryRowsUsed = Limits.getQueryRows()  - queryRowBefore;
        Long    queryWallMs   = wallAfter - wallBefore;
        Integer recordCount   = tickets.size();

        Test.stopTest();

        System.debug('APEX_METRIC|LoadAllTicketsGovernorTest.inlineSelect'
            + '|N='        + recordCount
            + '|CPU='      + cpuUsed
            + '|HEAP='     + heapUsed
            + '|QUERYMS='  + queryWallMs
            + '|SOQL='     + soqlUsed
            + '|QROWS='    + queryRowsUsed);

        System.debug('Tickets loaded (all)    : ' + recordCount);
        System.debug('CPU time (ms)           : ' + cpuUsed       + ' / limit 10000');
        System.debug('Heap size (bytes)       : ' + heapUsed      + ' / limit 6000000');
        System.debug('Query wall time (ms)    : ' + queryWallMs);
        System.debug('SOQL queries used       : ' + soqlUsed      + ' / limit 100');
        System.debug('Query rows used         : ' + queryRowsUsed + ' / limit 50000');

        Assert.areEqual(1, soqlUsed, 'Exactly one SOQL query should have been issued.');
    }
}

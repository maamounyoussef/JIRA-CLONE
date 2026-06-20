/**
 * Governor-limit measurement for ManageBacklogController.moveTicketPosition.
 *
 * Scenario: move ticket a0Cd200001GAqYGEA1 to be positioned BEFORE
 * ticket a0Cd200001GAqTTEA1.
 *
 * SeeAllData=true is required because the ticket Ids point to real org records.
 * Measures CPU time, heap size, total query wall time, SOQL queries, query rows,
 * DML statements and DML rows used by the operation.
 */
@isTest(SeeAllData=true)
public class MoveTicketPositionGovernorTest {

    private static final Id MOVED_TICKET_ID  = 'a0Cd200001GAqYGEA1';
    private static final Id BEFORE_TICKET_ID = 'a0Cd200001GAqTSEA1';

    @isTest
    static void measureMoveTicketPositionGovernorUsage() {

        Test.startTest();

        Integer soqlBefore     = Limits.getQueries();
        Integer queryRowBefore = Limits.getQueryRows();
        Integer dmlBefore      = Limits.getDmlStatements();
        Integer dmlRowsBefore  = Limits.getDmlRows();
        Integer heapBefore     = Limits.getHeapSize();
        Integer cpuBefore      = Limits.getCpuTime();
        Long    wallBefore     = System.currentTimeMillis();

        APIResponse result = ManageBacklogController.moveTicketPosition(
            MOVED_TICKET_ID,
            BEFORE_TICKET_ID
        );

        Long    wallAfter     = System.currentTimeMillis();
        Integer cpuUsed       = Limits.getCpuTime()       - cpuBefore;
        Integer heapUsed      = Limits.getHeapSize()      - heapBefore;
        Integer soqlUsed      = Limits.getQueries()       - soqlBefore;
        Integer queryRowsUsed = Limits.getQueryRows()     - queryRowBefore;
        Integer dmlUsed       = Limits.getDmlStatements() - dmlBefore;
        Integer dmlRowsUsed   = Limits.getDmlRows()       - dmlRowsBefore;
        Long    queryWallMs   = wallAfter - wallBefore;

        Test.stopTest();

        System.debug('APEX_METRIC|MoveTicketPositionGovernorTest.moveTicketPosition'
            + '|MOVED='    + MOVED_TICKET_ID
            + '|BEFORE='   + BEFORE_TICKET_ID
            + '|CPU='      + cpuUsed
            + '|HEAP='     + heapUsed
            + '|QUERYMS='  + queryWallMs
            + '|SOQL='     + soqlUsed
            + '|QROWS='    + queryRowsUsed
            + '|DML='      + dmlUsed
            + '|DMLROWS='  + dmlRowsUsed);

        System.debug('Moved ticket            : ' + MOVED_TICKET_ID);
        System.debug('Before ticket           : ' + BEFORE_TICKET_ID);
        System.debug('CPU time (ms)           : ' + cpuUsed       + ' / limit 10000');
        System.debug('Heap size (bytes)       : ' + heapUsed      + ' / limit 6000000');
        System.debug('Total query time (ms)   : ' + queryWallMs);
        System.debug('SOQL queries used       : ' + soqlUsed      + ' / limit 100');
        System.debug('Query rows used         : ' + queryRowsUsed + ' / limit 50000');
        System.debug('DML statements used     : ' + dmlUsed       + ' / limit 150');
        System.debug('DML rows used           : ' + dmlRowsUsed   + ' / limit 10000');
        System.debug('==== moveTicketPosition result ====');
        System.debug(JSON.serializePretty(result));
    }
}

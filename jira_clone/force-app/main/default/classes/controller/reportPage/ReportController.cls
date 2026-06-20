/**
 * @description Endpoint for the Report Page.
 * Returns the report details (gallery cards + detail view) for a given project.
 */
public with sharing class ReportController {

    @AuraEnabled(cacheable= true)
    public static APIResponse loadBurndownChart()
    {
        List<HistoryRow> rows = new List<HistoryRow>();

        Id parentId = 'a06d200000MU0p7AAD';
        Id createdById = '005d200000OIH2zAAH';

        // ----- original rows from the query grid -----
        rows.add(new HistoryRow('017d200001AkbZjAAJ', parentId, 'TotalEndedStoryPoint__c', 'Double', '0', '2', createdById, '2026-06-08T15:20:12.000+0000'));
        rows.add(new HistoryRow('017d200001AjokAAAR', parentId, 'RecordStatus__c', 'Text', 'future', 'in_progress', createdById, '2026-06-08T11:45:15.000+0000'));
        rows.add(new HistoryRow('017d200001AjhtwAAB', parentId, 'TotalStoryPoint__c', 'Double', '59', '69', createdById, '2026-06-08T11:44:35.000+0000'));
        rows.add(new HistoryRow('017d200001AjKm9AAF', parentId, 'TotalStoryPoint__c', 'Double', '48', '59', createdById, '2026-06-08T11:44:21.000+0000'));
        rows.add(new HistoryRow('017d200001AjyEfAAJ', parentId, 'TotalStoryPoint__c', 'Double', '33', '48', createdById, '2026-06-08T11:43:54.000+0000'));
        rows.add(new HistoryRow('017d200001AjrhwAAB', parentId, 'TotalStoryPoint__c', 'Double', '29', '33', createdById, '2026-06-08T11:43:33.000+0000'));
        rows.add(new HistoryRow('017d200001AjdhdAAB', parentId, 'TotalStoryPoint__c', 'Double', '24', '29', createdById, '2026-06-08T11:43:16.000+0000'));
        rows.add(new HistoryRow('017d200001Ajy8DAAR', parentId, 'TotalStoryPoint__c', 'Double', '18', '24', createdById, '2026-06-08T11:43:00.000+0000'));
        rows.add(new HistoryRow('017d200001AjwdAAAR', parentId, 'TotalStoryPoint__c', 'Double', '8', '18', createdById, '2026-06-08T11:42:47.000+0000'));
        rows.add(new HistoryRow('017d200001AjmLfAAJ', parentId, 'TotalStoryPoint__c', 'Double', '4', '8', createdById, '2026-06-08T11:42:32.000+0000'));
        rows.add(new HistoryRow('017d200001Ajvv8AAB', parentId, 'TotalStoryPoint__c', 'Double', '2', '4', createdById, '2026-06-08T11:42:19.000+0000'));
        rows.add(new HistoryRow('017d200001AjnPyAAJ', parentId, 'TotalStoryPoint__c', 'Double', '0', '2', createdById, '2026-06-08T11:41:33.000+0000'));
        rows.add(new HistoryRow('017d200001AjxVVAAZ', parentId, 'created', 'Text', null, null, createdById, '2026-06-08T11:38:21.000+0000'));

        // ----- added rows: TotalEndedStoryPoint__c climbs from 2 up to 69 (== TotalStoryPoint__c) -----
        rows.add(new HistoryRow('017d200001Ak0a1AAB', parentId, 'TotalEndedStoryPoint__c', 'Double', '2', '8', createdById, '2026-06-09T15:35:40.000+0000'));
        rows.add(new HistoryRow('017d200001Ak0b2AAB', parentId, 'TotalEndedStoryPoint__c', 'Double', '8', '18', createdById, '2026-06-10T15:48:12.000+0000'));
        rows.add(new HistoryRow('017d200001Ak0c3AAB', parentId, 'TotalEndedStoryPoint__c', 'Double', '18', '29', createdById, '2026-06-11T16:02:05.000+0000'));
        rows.add(new HistoryRow('017d200001Ak0d4AAB', parentId, 'TotalEndedStoryPoint__c', 'Double', '29', '48', createdById, '2026-06-12T16:19:33.000+0000'));
        rows.add(new HistoryRow('017d200001Ak0e5AAB', parentId, 'TotalEndedStoryPoint__c', 'Double', '48', '59', createdById, '2026-06-13T16:31:50.000+0000'));
        rows.add(new HistoryRow('017d200001Ak0f6AAB', parentId, 'TotalEndedStoryPoint__c', 'Double', '59', '69', createdById, '2026-06-14T16:45:27.000+0000'));

        // get the records from the mock store and store in a list of ComparableHistoryRow
        List<ComparableHistoryRow> comparableRows = new List<ComparableHistoryRow>();
        for (HistoryRow row : rows) {
            comparableRows.add(new ComparableHistoryRow(
                row.parentId, row.field, row.dataType,
                row.oldValue, row.newValue, row.createdById, row.createdDate));
        }

        // chronological order: by day first, then by time within the same day
        comparableRows.sort();

        // keep the RecordStatus__c -> in_progress row (sprint start) and everything after it;
        // delete all rows before it
        List<ComparableHistoryRow> fromInProgress = new List<ComparableHistoryRow>();
        Boolean started = false;
        for (ComparableHistoryRow row : comparableRows) {
            if (!started && row.field == 'RecordStatus__c' && row.newValue == 'in_progress') {
                started = true;
            }
            if (started) {
                fromInProgress.add(row);
            }
        }

        return new APIResponse(true, 'Burndown history loaded', fromInProgress);
    }

    /**
     * @description Mock row mirroring a Sprint__History record
     * (Id, ParentId, Field, DataType, OldValue, NewValue, CreatedById, CreatedDate).
     */
    public class HistoryRow{
        @AuraEnabled public Id recordId;
        @AuraEnabled public Id parentId;
        @AuraEnabled public String field;
        @AuraEnabled public String dataType;
        @AuraEnabled public String oldValue;
        @AuraEnabled public String newValue;
        @AuraEnabled public Id createdById;
        @AuraEnabled public Datetime createdDate;

        public HistoryRow(Id recordId, Id parentId, String field, String dataType,
                          String oldValue, String newValue, Id createdById, String createdDate) {
            this.recordId = recordId;
            this.parentId = parentId;
            this.field = field;
            this.dataType = dataType;
            this.oldValue = oldValue;
            this.newValue = newValue;
            this.createdById = createdById;
            this.createdDate = (String.isBlank(createdDate)) ? null : (Datetime) JSON.deserialize('"' + createdDate + '"', Datetime.class);
        }
    }


    
}

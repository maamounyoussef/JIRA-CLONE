/**
 * @description A history row split into day + time, ordered chronologically.
 * Holds ParentId, Field, DataType, OldValue, NewValue, CreatedById and the
 * CreatedDate broken into `day` (Date) and `recordTime` (Time).
 *
 * Implements Comparable: orders by `day` first; for rows on the same day it
 * orders by `recordTime`. Use with List.sort() to get a chronological sequence.
 */
public with sharing class ComparableHistoryRow implements Comparable {

    @AuraEnabled public Id parentId;
    @AuraEnabled public String field;
    @AuraEnabled public String dataType;
    @AuraEnabled public String oldValue;
    @AuraEnabled public String newValue;
    @AuraEnabled public Id createdById;
    @AuraEnabled public Date day;
    @AuraEnabled public Time recordTime;

    public ComparableHistoryRow(Id parentId, String field, String dataType,
                                String oldValue, String newValue, Id createdById,
                                Datetime createdDate) {
        this.parentId = parentId;
        this.field = field;
        this.dataType = dataType;
        this.oldValue = oldValue;
        this.newValue = newValue;
        this.createdById = createdById;
        if (createdDate != null) {
            this.day = createdDate.date();
            this.recordTime = createdDate.time();
        }
    }

    /**
     * @description Compare by day first; if the day is the same, compare by time.
     * @return negative if this is earlier, positive if later, 0 if identical.
     */
    public Integer compareTo(Object compareTo) {
        ComparableHistoryRow other = (ComparableHistoryRow) compareTo;

        // nulls sort last so real rows come first
        if (this.day == null && other.day == null) return 0;
        if (this.day == null) return 1;
        if (other.day == null) return -1;

        if (this.day != other.day) {
            return (this.day > other.day) ? 1 : -1;
        }

        // same day → compare on time
        if (this.recordTime == null && other.recordTime == null) return 0;
        if (this.recordTime == null) return 1;
        if (other.recordTime == null) return -1;
        if (this.recordTime == other.recordTime) return 0;
        return (this.recordTime > other.recordTime) ? 1 : -1;
    }
}

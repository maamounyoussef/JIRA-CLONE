trigger ProjectTrigger on Project__c (after insert) {
    ProjectTriggerHandler.onAfterInsertCreateDefaultStatuses(Trigger.new);
}

trigger StatusTrigger on Status__c (before insert, before update) {
    if (Trigger.isInsert) {
        StatusTriggerHandler.preventDuplicateOnInsert(Trigger.new);
    }
    if (Trigger.isUpdate) {
        StatusTriggerHandler.preventUpdateOnFlaggedStatuses(Trigger.new, Trigger.oldMap);
    }
}

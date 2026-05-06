public with sharing class ProjectTriggerHandler {

    public static void onAfterInsertCreateDefaultStatuses(List<Project__c> newProjects) {
        List<Status__c> toInsert = new List<Status__c>();
        for (Project__c p : newProjects) {
            toInsert.add(new Status__c(Name = 'todo', Project__c = p.Id, isStart__c = true,  isEnd__c = false));
            toInsert.add(new Status__c(Name = 'done', Project__c = p.Id, isStart__c = false, isEnd__c = true));
        }
        insert toInsert;
    }
}

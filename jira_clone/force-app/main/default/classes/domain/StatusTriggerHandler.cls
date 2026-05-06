public with sharing class StatusTriggerHandler {

    // Before insert: if isStart__c or isEnd__c is true, block if one already exists for that project
    public static void preventDuplicateOnInsert(List<Status__c> newStatuses) {
        Set<Id> startProjects = new Set<Id>();
        Set<Id> endProjects   = new Set<Id>();

        for (Status__c s : newStatuses) {
            if (s.isStart__c) startProjects.add(s.Project__c);
            if (s.isEnd__c)   endProjects.add(s.Project__c);
        }

        Set<Id> allProjects = new Set<Id>();
        allProjects.addAll(startProjects);
        allProjects.addAll(endProjects);
        if (allProjects.isEmpty()) return;

        Set<Id> hasStart = new Set<Id>();
        Set<Id> hasEnd   = new Set<Id>();

        for (Status__c existing : [
            SELECT Project__c, isStart__c, isEnd__c
            FROM Status__c
            WHERE Project__c IN :allProjects
              AND (isStart__c = true OR isEnd__c = true)
        ]) {
            if (existing.isStart__c) hasStart.add(existing.Project__c);
            if (existing.isEnd__c)   hasEnd.add(existing.Project__c);
        }

        for (Status__c s : newStatuses) {
            if (s.isStart__c && hasStart.contains(s.Project__c)) {
                s.isStart__c.addError('A start status already exists for this project.');
            }
            if (s.isEnd__c && hasEnd.contains(s.Project__c)) {
                s.isEnd__c.addError('An end status already exists for this project.');
            }
        }
    }

    // Before update: if the record already has isStart__c or isEnd__c set to true, block any update
    public static void preventUpdateOnFlaggedStatuses(List<Status__c> newStatuses, Map<Id, Status__c> oldMap) {
        for (Status__c s : newStatuses) {
            Status__c old = oldMap.get(s.Id);
            if (old.isStart__c || old.isEnd__c) {
                s.addError('Start and end statuses cannot be modified.');
            }
        }
    }
}

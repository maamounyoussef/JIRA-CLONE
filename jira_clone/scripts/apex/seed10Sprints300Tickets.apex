// ---------------------------------------------------------------
// Seed: 10 sprints, each with 300 tickets.
// Total DML rows: 10 sprint inserts + 3000 ticket inserts + 10
// sprint updates = 3,020 rows (well under the 10,000 limit).
// ---------------------------------------------------------------

Integer SPRINT_COUNT       = 10;
Integer TICKETS_PER_SPRINT = 300;
Integer SCORE_GAP          = 200;
Integer SCORE_LEN          = 6;

// Resolve dependencies from a specific project.
Id PROJECT_ID = 'a00d200002j4o2wAAA';
Project__c project = [SELECT Id, Name FROM Project__c WHERE Id = :PROJECT_ID LIMIT 1];
TicketType__c ticketType = [
    SELECT Id FROM TicketType__c
    WHERE Project__c = :project.Id AND RecordStatus__c != 'delete'
    ORDER BY CreatedDate ASC LIMIT 1
];
Status__c startStatus = [
    SELECT Id FROM Status__c
    WHERE Project__c = :project.Id AND isStart__c = true LIMIT 1
];
ProjectMember__c member = [
    SELECT Id FROM ProjectMember__c
    WHERE Project__c = :project.Id
      AND User__c = :UserInfo.getUserId()
      AND RecordStatus__c != 'delete'
    LIMIT 1
];

System.debug('Seeding ' + SPRINT_COUNT + ' sprints x ' + TICKETS_PER_SPRINT +
             ' tickets in project ' + project.Name + ' (' + project.Id + ')');

// Step 1: insert sprints, each pre-seeded with MaxScore = 000000.
List<Sprint__c> sprints = new List<Sprint__c>();
for (Integer i = 1; i <= SPRINT_COUNT; i++) {
    sprints.add(new Sprint__c(
        Name                    = 'SeedSprint-' + i,
        Project__c              = project.Id,
        Duration__c             = 14,
        StartDate__c            = Date.today(),
        Goal__c                 = 'Seed sprint ' + i,
        RecordStatus__c         = 'future',
        TotalStoryPoint__c      = 0,
        TotalEndedStoryPoint__c = 0,
        MaxScore__c             = '000000'
    ));
}
insert sprints;

// Step 2: bulk-insert ALL tickets across ALL sprints in a single DML.
String finalMax = String.valueOf(TICKETS_PER_SPRINT * SCORE_GAP).leftPad(SCORE_LEN, '0');
List<Ticket__c> allTickets = new List<Ticket__c>();

for (Sprint__c sprint : sprints) {
    for (Integer n = 1; n <= TICKETS_PER_SPRINT; n++) {
        allTickets.add(new Ticket__c(
            Name            = sprint.Name + '-T' + n,
            Summary__c      = 'Ticket ' + n,
            Description__c  = 'Seed',
            CurrentState__c = startStatus.Id,
            Priority__c     = 'Medium',
            Creator__c      = member.Id,
            Ticket_Type__c  = ticketType.Id,
            Sprint__c       = sprint.Id,
            StoryPoint__c   = 1,
            RecordStatus__c = 'active',
            Score__c        = String.valueOf(n * SCORE_GAP).leftPad(SCORE_LEN, '0')
        ));
    }
    sprint.MaxScore__c             = finalMax;
    sprint.TotalStoryPoint__c      = TICKETS_PER_SPRINT;
    sprint.TotalEndedStoryPoint__c = 0;
}
insert allTickets;
update sprints;

System.debug('Done. DML rows: ' + Limits.getDmlRows() +
             ' / ' + Limits.getLimitDmlRows() +
             '   SOQL: ' + Limits.getQueries() +
             ' / ' + Limits.getLimitQueries());

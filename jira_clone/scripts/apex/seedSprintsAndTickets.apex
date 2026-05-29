// ---------------------------------------------------------------
// Seed: create N sprints, each with M tickets (default 15 × 1000).
//
// IMPORTANT — per-transaction DML row limit is 10,000.
// 15 sprints × 1000 tickets + 15 sprint rows = 15,015 rows, which
// exceeds the limit. Run this script TWICE, adjusting the bounds:
//   Pass 1 : SPRINT_FROM = 1 , SPRINT_TO = 9   (~ 9,009 rows)
//   Pass 2 : SPRINT_FROM = 10, SPRINT_TO = 15  (~ 6,006 rows)
// ---------------------------------------------------------------

Integer SPRINT_FROM        = 1;
Integer SPRINT_TO          = 9;
Integer TICKETS_PER_SPRINT = 1000;
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

System.debug('Seeding sprints ' + SPRINT_FROM + '..' + SPRINT_TO +
             ' in project ' + project.Name + ' (' + project.Id + ')');

// Step 1: insert sprints, each pre-seeded with MaxScore = 000000.
List<Sprint__c> sprints = new List<Sprint__c>();
for (Integer i = SPRINT_FROM; i <= SPRINT_TO; i++) {
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

// Step 2: for each sprint, bulk-insert tickets with pre-computed scores,
// then bump the sprint's MaxScore and totals.
String finalMax = String.valueOf(TICKETS_PER_SPRINT * SCORE_GAP).leftPad(SCORE_LEN, '0');

for (Sprint__c sprint : sprints) {
    List<Ticket__c> tickets = new List<Ticket__c>();
    for (Integer n = 1; n <= TICKETS_PER_SPRINT; n++) {
        tickets.add(new Ticket__c(
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
    insert tickets;

    sprint.MaxScore__c             = finalMax;
    sprint.TotalStoryPoint__c      = TICKETS_PER_SPRINT;
    sprint.TotalEndedStoryPoint__c = 0;

    System.debug(sprint.Name + ' filled. DML rows used so far: ' + Limits.getDmlRows());
}
update sprints;

System.debug('Done. DML rows: ' + Limits.getDmlRows() +
             ' / ' + Limits.getLimitDmlRows() +
             '   SOQL: ' + Limits.getQueries() +
             ' / ' + Limits.getLimitQueries());

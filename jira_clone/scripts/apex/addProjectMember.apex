// ---------------------------------------------------------------
// Add a new ProjectMember__c for a given user.
//
// Project__c is REQUIRED on ProjectMember__c, so you must supply a
// project. Set PROJECT_ID below before running.
//
// Single-record insert — no bulkification needed.
// ---------------------------------------------------------------

Id USER_ID    = '005d200000OIH2z';            // the user to add
Id PROJECT_ID = 'a00d200002fOoZJAA0';         // target project
String ROLE   = 'Developer';                  // PPO | Consultant | Test Factory | Scrum Master | Developer

// Resolve references (fail fast with a clear message if missing).
Project__c project = [SELECT Id, Name FROM Project__c WHERE Id = :PROJECT_ID LIMIT 1];
User usr           = [SELECT Id, Name FROM User WHERE Id = :USER_ID LIMIT 1];

// Guard: don't create a duplicate active membership (exclude soft-deleted rows).
List<ProjectMember__c> existing = [
    SELECT Id
    FROM ProjectMember__c
    WHERE Project__c = :PROJECT_ID
      AND User__c = :USER_ID
      AND RecordStatus__c != 'deleted'
    LIMIT 1
];

if (!existing.isEmpty()) {
    System.debug('Membership already exists (' + existing[0].Id +
                 ') for ' + usr.Name + ' in ' + project.Name + ' — nothing to do.');
} else {
    ProjectMember__c member = new ProjectMember__c(
        Name           = usr.Name + ' @ ' + project.Name,
        Project__c     = PROJECT_ID,
        User__c        = USER_ID,
        Role__c        = ROLE,
        RecordStatus__c = 'active'
    );
    insert member;
    System.debug('Created ProjectMember__c ' + member.Id +
                 ' — ' + usr.Name + ' as ' + ROLE + ' in ' + project.Name);
}

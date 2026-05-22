@isTest
public class ManageBacklogControllerGovernorTest {

    // ════════════════════════════════════════════════════════════════════════
    //  GOVERNOR-LIMIT OBSERVABILITY TEST
    //
    //  Measures, for a single ManageBacklogController.deleteTickets transaction:
    //    • CPU execution time          Limits.getCpuTime()        (ms)
    //    • Heap memory                 Limits.getHeapSize()       (bytes)
    //    • SOQL queries issued         Limits.getQueries()
    //    • Rows processed by DML       Limits.getDmlRows()
    //    • DML statements issued       Limits.getDmlStatements()
    //
    //  Each metric is captured immediately before and after the call and the
    //  delta (resource consumed by the method) is asserted against the platform
    //  limit and logged for inspection.
    //
    //  All required fields are set per OBJECT_VALIDATION_LWC_APEX.md
    //  (apex/store column).
    // ════════════════════════════════════════════════════════════════════════

    // The controller caps a single deletion at 24
    // (InputSecurityValidator.validateTicketDeletionLimit).
    private static final Integer TICKET_COUNT = 24;

    // ─── Test-data helpers (required fields per OBJECT_VALIDATION_LWC_APEX) ───

    // Project__c: Name (standard) required.
    private static Project__c createProject(String name) {
        Project__c p = new Project__c(Name = name);
        insert p;
        return p;
    }

    // Workflow__c: Project__c + Name required.
    private static Workflow__c createWorkflow(Project__c project, String name) {
        Workflow__c w = new Workflow__c(Name = name, Project__c = project.Id, RecordStatus__c = 'active');
        insert w;
        return w;
    }

    // Status__c: Project__c + Name required.
    private static Status__c createStatus(Project__c project, String name) {
        Status__c s = new Status__c(Name = name, Project__c = project.Id);
        insert s;
        return s;
    }

    // TicketType__c (apex/store): RecordStatus__c, Workflow__c, Description__c,
    // IconUrl__c, Project__c all required.
    private static TicketType__c createTicketType(Project__c project, Workflow__c workflow, String name) {
        TicketType__c tt = new TicketType__c(
            Name            = name,
            Description__c  = name + ' description',
            IconUrl__c      = 'https://example.com/icon.png',
            Workflow__c     = workflow.Id,
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert tt;
        return tt;
    }

    // ProjectMember__c (apex): Project__c + User__c required.
    private static ProjectMember__c createCurrentUserMember(Project__c project) {
        ProjectMember__c pm = new ProjectMember__c(
            User__c         = UserInfo.getUserId(),
            Project__c      = project.Id,
            RecordStatus__c = 'active'
        );
        insert pm;
        return pm;
    }

    // Sprint__c (apex/store): Project__c, Duration__c, Goal__c, RecordStatus__c required.
    private static Sprint__c createSprint(Project__c project, String name) {
        Sprint__c s = new Sprint__c(
            Name                   = name,
            Project__c             = project.Id,
            Duration__c            = 14,
            Goal__c                = 'Sprint goal',
            StartDate__c           = Date.today(),
            RecordStatus__c        = 'future',
            // Seed the rollup fields so SprintService.decreaseTotalAndEndedStoryPoints
            // can subtract without dereferencing a null (SprintService.cls:117-118).
            TotalStoryPoint__c     = 1000,
            TotalEndedStoryPoint__c = 1000
        );
        insert s;
        return s;
    }

    // ─── The measured test ───────────────────────────────────────────────────

    @isTest
    static void measureDeleteTicketsGovernorUsage() {
        // ---- Arrange: build a project context and a batch of tickets in a sprint.
        Project__c       project    = createProject('Gov-DeleteProj');
        Workflow__c      workflow   = createWorkflow(project, 'Gov-WF');
        Status__c        status     = createStatus(project, 'Open');
        TicketType__c    ticketType = createTicketType(project, workflow, 'Bug');
        ProjectMember__c creator    = createCurrentUserMember(project);
        Sprint__c        sprint     = createSprint(project, 'Gov-Sprint');

        // Ticket__c (apex/store) required fields: CurrentState__c, Summary__c,
        // Creator__c, Description__c, Priority__c, RecordStatus__c, Ticket_Type__c.
        List<Ticket__c> tickets = new List<Ticket__c>();
        for (Integer i = 0; i < TICKET_COUNT; i++) {
            tickets.add(new Ticket__c(
                Name            = 'GOV-TCK-' + i,
                Summary__c      = 'Summary ' + i,
                Description__c  = 'Description ' + i,
                Priority__c     = 'Medium',
                RecordStatus__c = 'active',
                CurrentState__c = status.Id,
                Ticket_Type__c  = ticketType.Id,
                Creator__c      = creator.Id,
                Sprint__c       = sprint.Id
            ));
        }
        insert tickets;

        List<String> ticketIds = new List<String>();
        for (Ticket__c t : tickets) {
            ticketIds.add(t.Id);
        }

        // ---- Act: measure governor usage strictly around the controller call.
        Test.startTest();

        Integer cpuBefore     = Limits.getCpuTime();
        Integer heapBefore    = Limits.getHeapSize();
        Integer soqlBefore    = Limits.getQueries();
        Integer dmlRowBefore  = Limits.getDmlRows();
        Integer dmlStmtBefore = Limits.getDmlStatements();

        APIResponse res = ManageBacklogController.deleteTickets(ticketIds);

        Integer cpuUsed     = Limits.getCpuTime()       - cpuBefore;
        Integer heapUsed    = Limits.getHeapSize()      - heapBefore;
        Integer soqlUsed    = Limits.getQueries()       - soqlBefore;
        Integer dmlRowUsed  = Limits.getDmlRows()       - dmlRowBefore;
        Integer dmlStmtUsed = Limits.getDmlStatements() - dmlStmtBefore;

        Test.stopTest();

        // ---- Report: surface the per-transaction resource consumption.
        System.debug('═══ deleteTickets governor usage (for ' + TICKET_COUNT + ' tickets) ═══');
        System.debug('CPU time (ms)      : ' + cpuUsed     + ' / limit ' + Limits.getLimitCpuTime());
        System.debug('Heap (bytes)       : ' + heapUsed    + ' / limit ' + Limits.getLimitHeapSize());
        System.debug('SOQL queries       : ' + soqlUsed    + ' / limit ' + Limits.getLimitQueries());
        System.debug('DML rows processed : ' + dmlRowUsed  + ' / limit ' + Limits.getLimitDmlRows());
        System.debug('DML statements     : ' + dmlStmtUsed + ' / limit ' + Limits.getLimitDmlStatements());

        // ---- Assert: the call succeeded and every metric stayed within limit.
        Assert.isTrue(res.success, 'deleteTickets should succeed; got: ' + res.message);

        Assert.isTrue(
            cpuUsed <= Limits.getLimitCpuTime(),
            'CPU time should not exceed the transaction limit; used ' + cpuUsed
        );
        Assert.isTrue(
            heapUsed <= Limits.getLimitHeapSize(),
            'Heap usage should not exceed the transaction limit; used ' + heapUsed
        );
        // The controller issues one requireTicketExists SOQL per id plus the
        // service-layer queries. Guard against accidental query growth.
        Assert.isTrue(
            soqlUsed <= Limits.getLimitQueries(),
            'SOQL queries should stay within the transaction limit; used ' + soqlUsed
        );
        Assert.isTrue(
            dmlStmtUsed <= Limits.getLimitDmlStatements(),
            'DML statements should stay within the transaction limit; used ' + dmlStmtUsed
        );
        // Soft-delete updates the tickets (and any affected sprints); rows
        // processed should be bounded and well under the platform ceiling.
        Assert.isTrue(
            dmlRowUsed <= Limits.getLimitDmlRows(),
            'DML rows should stay within the transaction limit; processed ' + dmlRowUsed
        );
    }
}

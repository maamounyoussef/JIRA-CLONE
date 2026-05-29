/**
 * @description Per-project counters used to generate default Names for
 * Sprint__c (SPR-N), Ticket__c (TKT-N) and Subtask__c (SUB-N).
 *
 * One NameSequence__c row exists per Project__c. The row is created by
 * ProjectService.createProject with all counters at 0; each create call
 * to the corresponding service increments its counter by 1.
 */
public with sharing class NameSequenceService {

    public static final String SPRINT_PREFIX  = 'SPR';
    public static final String TICKET_PREFIX  = 'TKT';
    public static final String SUBTASK_PREFIX = 'SUB';

    public static NameSequence__c createForProject(String projectId) {
        try {
            NameSequence__c row = new NameSequence__c(
                Project__c               = projectId,
                SprintLastSequence__c    = 0,
                TicketLastSequence__c    = 0,
                SubtaskLastSequence__c   = 0
            );
            insert row;
            return row;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating name sequence: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating name sequence: ' + ex.getMessage());
        }
    }

    public static String nextSprintName(String projectId) {
        return SPRINT_PREFIX + '-' + bumpCounter(projectId, 'sprint');
    }

    public static String nextTicketName(String projectId) {
        return TICKET_PREFIX + '-' + bumpCounter(projectId, 'ticket');
    }

    public static String nextSubtaskName(String projectId) {
        return SUBTASK_PREFIX + '-' + bumpCounter(projectId, 'subtask');
    }

    private static Integer bumpCounter(String projectId, String kind) {
        if (String.isBlank(projectId)) throw new ServiceException('projectId is required');

        NameSequence__c row = findOrCreate(projectId);

        Integer next;
        if (kind == 'sprint') {
            next = (row.SprintLastSequence__c == null ? 0 : row.SprintLastSequence__c.intValue()) + 1;
            row.SprintLastSequence__c = next;
        } else if (kind == 'ticket') {
            next = (row.TicketLastSequence__c == null ? 0 : row.TicketLastSequence__c.intValue()) + 1;
            row.TicketLastSequence__c = next;
        } else {
            next = (row.SubtaskLastSequence__c == null ? 0 : row.SubtaskLastSequence__c.intValue()) + 1;
            row.SubtaskLastSequence__c = next;
        }
        update row;
        return next;
    }

    private static NameSequence__c findOrCreate(String projectId) {
        List<NameSequence__c> rows = [
            SELECT Id, Project__c, SprintLastSequence__c, TicketLastSequence__c, SubtaskLastSequence__c
            FROM NameSequence__c
            WHERE Project__c = :projectId
            LIMIT 1
        ];
        if (!rows.isEmpty()) return rows[0];
        return createForProject(projectId);
    }
}

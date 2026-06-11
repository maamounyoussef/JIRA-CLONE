/**
 * @description Service class for Ticket, Subtask, and TicketType operations
 */
public with sharing class TicketService {

    private static final Integer DEFAULT_PAGE_SIZE = 5;

    // ═══════════════════════════════════════════════════════════════
    // TICKET
    // ═══════════════════════════════════════════════════════════════

    public static Ticket__c findTicketById(String ticketId) {
        try {
            List<Ticket__c> res = [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c, Score__c
                FROM Ticket__c
                WHERE Id = :ticketId AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving ticket: ' + ex.getMessage());
        }
    }

    public static CreateTicketResponse createTicketWithoutSprint(Ticket__c ticket, TicketType__c ticketType) {
        try {
            prepareTicketForInsert(ticket, ticketType);
            insert ticket;
            return new CreateTicketResponse(ticket);
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket: ' + ex.getMessage());
        }
    }

    public static CreateTicketResponse createTicketWithSprint(Ticket__c ticket, TicketType__c ticketType) {
        try {
            Status__c status = prepareTicketForInsert(ticket, ticketType);
            insert ticket;

            Sprint__c updatedSprint;
            if (DomainCompleteValidator.isEndStatus(status)) {
                updatedSprint = SprintService.increaseTotalAndEndedStoryPoint(ticket.Sprint__c, ticket.StoryPoint__c, ticket.StoryPoint__c);
            } else {
                updatedSprint = SprintService.increaseTotalAndEndedStoryPoint(ticket.Sprint__c, ticket.StoryPoint__c, 0);
            }
            return new CreateTicketResponse(ticket, updatedSprint);
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket: ' + ex.getMessage());
        }
    }

    private static Status__c prepareTicketForInsert(Ticket__c ticket, TicketType__c ticketType) {
        String projectId = ticketType.Project__c;

        if (String.isBlank(ticket.Creator__c)) {
            String userId = UserInfo.getUserId();
            ProjectMember__c creator = ProjectService.findActiveMemberByUserAndProject(userId, projectId);
            DomainCompleteValidator.requireCurrentUserMemberForProject(creator, userId);
            ticket.Creator__c = creator.Id;
        }

        if (String.isBlank(ticket.Priority__c)) ticket.Priority__c = 'Medium';

        Status__c status;
        if (String.isBlank(ticket.CurrentState__c)) {
            status = StatusService.getStartStatus(projectId);
        } else {
            status = StatusService.findStatus(ticket.CurrentState__c);
        }
        ticket.CurrentState__c = status.Id;

        ticket.RecordStatus__c = 'active';
        ticket.Score__c = nextScoreForInsert(ticket, projectId);
        ticket.Name = NameSequenceService.nextTicketName(projectId);
        return status;
    }

    public static Ticket__c updateTicket(Ticket__c ticket) {
        try {
            update ticket;
            return ticket;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket: ' + ex.getMessage());
        }
    }


    public static Ticket__c assignTicket(Ticket__c existing, String memberId) {
        try {
            existing.AssignedTo__c = memberId;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning ticket: ' + ex.getMessage());
        }
    }

    public static Sprint__c deleteTicket(Ticket__c ticket) {
        try {
            ticket.RecordStatus__c = 'deleted';
            updateTicket(ticket);
            if (String.isNotBlank(ticket.Sprint__c)) {
                Status__c status = StatusService.findStatus(ticket.CurrentState__c);
                if(DomainCompleteValidator.isEndStatus(status))
                    return SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, ticket.StoryPoint__c);
                else 
                    return SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, 0);
            }
            return null;
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting ticket: ' + ex.getMessage());
        }
    }
        
    public static List<Sprint__c> deleteTickets(List<Ticket__c> tickets) {
        try {
            if (tickets.isEmpty()) return new List<Sprint__c>();

            for (Ticket__c t : tickets) t.RecordStatus__c = 'deleted';
            update tickets;

            Map<String, Decimal> sprintTotalStoryPointMap = new Map<String, Decimal>();
            Map<String, Decimal> sprintEndedStoryPointMap = new Map<String, Decimal>();

            for (Ticket__c t : tickets) {
                if (String.isNotBlank(t.Sprint__c)) {
                    Decimal storyPoints = t.StoryPoint__c != null ? t.StoryPoint__c : 0;

                    Decimal currentTotal = sprintTotalStoryPointMap.containsKey(t.Sprint__c) ? sprintTotalStoryPointMap.get(t.Sprint__c) : 0;
                    sprintTotalStoryPointMap.put(t.Sprint__c, currentTotal + storyPoints);

                    Decimal currentEnded = sprintEndedStoryPointMap.containsKey(t.Sprint__c) ? sprintEndedStoryPointMap.get(t.Sprint__c) : 0;
                    Status__c status = StatusService.findStatus(t.CurrentState__c);
                    Decimal endedPoints = DomainCompleteValidator.isEndStatus(status) ? storyPoints : 0;
                    sprintEndedStoryPointMap.put(t.Sprint__c, currentEnded + endedPoints);
                }
            }

            List<Sprint__c> updatedSprints = new List<Sprint__c>();
            for (String sprintId : sprintTotalStoryPointMap.keySet()) {
                Sprint__c updated = SprintService.decreaseTotalAndEndedStoryPoints(
                    sprintId,
                    sprintTotalStoryPointMap.get(sprintId),
                    sprintEndedStoryPointMap.get(sprintId)
                );
                updatedSprints.add(updated);
            }

            return updatedSprints;
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting tickets: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting tickets: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> loadBacklogTickets(Project__c project, Integer offset, Integer pageSize) {
        try {
            System.debug('==== loadBacklogTickets hit8 ====');
            
            List<TicketType__c> types = [SELECT Id FROM TicketType__c WHERE Project__c = :project.Id];
            if (types.isEmpty()) return new List<Ticket__c>();
            List<Id> typeIds = new List<Id>();
            for (TicketType__c t : types) typeIds.add(t.Id);

            Integer currentOffset   = DomainCompleteValidator.safeOffset(offset);
            Integer currentPageSize = DomainCompleteValidator.safePageSize(pageSize, DEFAULT_PAGE_SIZE);
            System.debug('==== loadBacklogTickets hit9 ====');
            
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c, Score__c
                FROM Ticket__c
                WHERE Ticket_Type__c IN :typeIds AND RecordStatus__c = 'active' AND Sprint__c = null
                ORDER BY Score__c ASC NULLS LAST
                LIMIT :currentPageSize OFFSET :currentOffset
            ];

        } catch (Exception ex) {
            throw new ServiceException('Error querying backlog tickets: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> getActiveTicketsBySprintOrderByPriorityAsc(Sprint__c sprint, Integer offset, Integer pageSize) {
        try {
            Integer currentOffset   = DomainCompleteValidator.safeOffset(offset);
            Integer currentPageSize = DomainCompleteValidator.safePageSize(pageSize, DEFAULT_PAGE_SIZE);
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Creator__c, Epic__c, Sprint__c, RecordStatus__c, Ticket_Type__c,
                       StartDate__c, EndDate__c, Score__c
                FROM Ticket__c
                WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
                ORDER BY Score__c ASC NULLS LAST
                LIMIT :currentPageSize OFFSET :currentOffset
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying tickets by sprint: ' + ex.getMessage());
        }
    }

    public static List<Ticket__c> loadActiveTicketsBySprint(Sprint__c sprint) {
        try {
            return [
                SELECT Id, Name, Summary__c, CurrentState__c, Priority__c, StoryPoint__c,
                       AssignedTo__c, Epic__c, Sprint__c, Ticket_Type__c, RecordStatus__c, Score__c
                FROM Ticket__c
                WHERE Sprint__c = :sprint.Id AND RecordStatus__c = 'active'
                ORDER BY Score__c ASC NULLS LAST
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error loading active tickets by sprint: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketPriority(Ticket__c existing, String priority) {
        try {
            existing.Priority__c = priority;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket priority: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketSummary(Ticket__c existing, String summary) {
        try {
            existing.Summary__c = summary;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket summary: ' + ex.getMessage());
        }
    }

    public static Ticket__c updateTicketDescription(Ticket__c existing, String description) {
        try {
            existing.Description__c = description;
            return updateTicket(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket description: ' + ex.getMessage());
        }
    }

    public static Sprint__c removeTicketSprint(Ticket__c ticket) {
        try {
            if (String.isNotBlank(ticket.Sprint__c)) {
                Sprint__c updated;
                Status__c status = StatusService.findStatus(ticket.CurrentState__c);
                if (DomainCompleteValidator.isEndStatus(status))
                    updated = SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, ticket.StoryPoint__c);
                else
                    updated = SprintService.decreaseTotalAndEndedStoryPoints(ticket.Sprint__c, ticket.StoryPoint__c, 0);

                List<TicketType__c> types = [
                    SELECT Project__c FROM TicketType__c
                    WHERE Id = :ticket.Ticket_Type__c AND RecordStatus__c != 'deleted'
                    LIMIT 1
                ];
                if (types.isEmpty()) throw new ServiceException('Cannot resolve project for ticket ' + ticket.Id);

                ticket.Sprint__c = null;
                ticket.Score__c = nextScoreForBacklogInsert(types[0].Project__c);
                updateTicket(ticket);
                return updated;
            }
            return null;
        } catch (Exception ex) {
            throw new ServiceException('Error removing ticket from sprint: ' + ex.getMessage());
        }
    }

    public static void clearSprintFromTickets(String sprintId) {
        try {
            if (String.isBlank(sprintId)) return;
            List<Ticket__c> tickets = [
                SELECT Id, Sprint__c
                FROM Ticket__c
                WHERE Sprint__c = :sprintId
            ];
            if (tickets.isEmpty()) return;
            for (Ticket__c t : tickets) t.Sprint__c = null;
            update tickets;
        } catch (DmlException dex) {
            throw new ServiceException('DML error clearing sprint from tickets: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error clearing sprint from tickets: ' + ex.getMessage());
        }
    }

    public static Sprint__c moveTicketToSprint(Ticket__c ticket, Sprint__c sprint) {
        try {
            DomainCompleteValidator.requireTicketNotInDifferentSprint(ticket, sprint.Id);
            ticket.Sprint__c = sprint.Id;
            ticket.Score__c = nextScoreForSprintInsert(sprint.Id);
            updateTicket(ticket);
            Status__c status = StatusService.findStatus(ticket.CurrentState__c);
            if(DomainCompleteValidator.isEndStatus(status))
                return SprintService.increaseTotalAndEndedStoryPoint(sprint.Id, ticket.StoryPoint__c,ticket.StoryPoint__c);
            else
                return SprintService.increaseTotalAndEndedStoryPoint(sprint.Id, ticket.StoryPoint__c,0);
        } catch (Exception ex) {
            throw new ServiceException('Error moving ticket to sprint: ' + ex.getMessage());
        }
    }


    // ═══════════════════════════════════════════════════════════════
    // TICKET SCORE — fixed-width integer keys, max stored on
    // Sprint__c.MaxScore__c (sprint scope) or Project__c.BacklogMaxScore__c
    // (backlog scope). Score__c is a zero-padded 6-digit decimal so
    // string ASC sort matches integer ASC.
    // ═══════════════════════════════════════════════════════════════

    private static final Integer SCORE_LENGTH = 6;
    private static final Integer SCORE_GAP = 200;
    private static final String INITIAL_SCORE = '000000';

    /**
     * Reorder a ticket inside its current sprint (or backlog) so that, when
     * ordered ASC by Score__c, it sits immediately after `beforeTicket`
     * (or at the top when `beforeTicket` is null).
     *
     * Rules:
     *   - beforeTicket == null  → always rebalance the whole scope
     *     and place movedTicket first.
     *   - no successor exists   → append: newScore = beforeTicket + gap,
     *     and bump the scope's MaxScore.
     *   - successor exists      → newScore = (beforeInt + successorInt) / 2
     *     when the sum is even; otherwise rebalance the whole scope and
     *     place movedTicket between beforeTicket and successor.
     */
    public static Ticket__c moveTicketPosition(Ticket__c movedTicket, Ticket__c beforeTicket) {
        try {
            if (movedTicket == null) throw new ServiceException('movedTicket is required');

            if (beforeTicket != null) {
                if (movedTicket.Id == beforeTicket.Id) {
                    throw new ServiceException('movedTicket and beforeTicket must be different');
                }
                if (movedTicket.Sprint__c != beforeTicket.Sprint__c) {
                    throw new ServiceException('movedTicket and beforeTicket must share the same sprint (or both be in the backlog)');
                }
                if (String.isBlank(beforeTicket.Score__c)) {
                    throw new ServiceException('beforeTicket has no Score__c — backfill required');
                }
            }

            Boolean isBacklog = String.isBlank(movedTicket.Sprint__c);
            String projectId = null;
            Set<Id> backlogTypeIds = null;
            if (isBacklog) {
                TicketType__c tt = [
                    SELECT Project__c FROM TicketType__c
                    WHERE Id = :movedTicket.Ticket_Type__c AND RecordStatus__c != 'deleted'
                    LIMIT 1
                ];
                projectId = tt.Project__c;
                backlogTypeIds = projectTicketTypeIds(projectId);
            }

            if (beforeTicket == null) {
                return rebalanceScope(movedTicket, null, isBacklog, projectId, backlogTypeIds);
            }

            Ticket__c successor = findSuccessor(movedTicket, beforeTicket.Score__c, backlogTypeIds);
            Integer beforeInt = parseScore(beforeTicket.Score__c);

            if (successor == null) {
                String newScore = padScore(beforeInt + SCORE_GAP);
                movedTicket.Score__c = newScore;
                update movedTicket;
                if (isBacklog) setBacklogMaxScore(projectId, newScore);
                else setSprintMaxScore(movedTicket.Sprint__c, newScore);
                return movedTicket;
            }

            Integer successorInt = parseScore(successor.Score__c);
            Integer sum = beforeInt + successorInt;
            if (Math.mod(sum, 2) == 0) {
                Integer mid = sum / 2;
                if (mid != beforeInt && mid != successorInt) {
                    movedTicket.Score__c = padScore(mid);
                    update movedTicket;
                    return movedTicket;
                }
            }

            return rebalanceScope(movedTicket, beforeTicket, isBacklog, projectId, backlogTypeIds);
        } catch (DmlException dex) {
            throw new ServiceException('DML error moving ticket position: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error moving ticket position: ' + ex.getMessage());
        }
    }

    /**
     * Compute the score for a brand‑new ticket: append at the end of its
     * sprint (or backlog) ordering. The corresponding MaxScore on the scope
     * row is bumped in the same call.
     */
    private static String nextScoreForInsert(Ticket__c ticket, String projectId) {
        if (String.isNotBlank(ticket.Sprint__c)) {
            return nextScoreForSprintInsert(ticket.Sprint__c);
        }
        return nextScoreForBacklogInsert(projectId);
    }

    private static String nextScoreForSprintInsert(String sprintId) {
        List<Sprint__c> rows = [
            SELECT Id, MaxScore__c FROM Sprint__c
            WHERE Id = :sprintId AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (rows.isEmpty()) throw new ServiceException('Sprint not found: ' + sprintId);
        Sprint__c sprint = rows[0];
        Integer current = parseScore(sprint.MaxScore__c);
        String newScore = padScore(current + SCORE_GAP);
        sprint.MaxScore__c = newScore;
        update sprint;
        return newScore;
    }

    private static String nextScoreForBacklogInsert(String projectId) {
        Project__c project = ProjectService.findProjectById(projectId);
        if (project == null) throw new ServiceException('Project not found: ' + projectId);
        Integer current = parseScore(project.BacklogMaxScore__c);
        String newScore = padScore(current + SCORE_GAP);
        project.BacklogMaxScore__c = newScore;
        update project;
        return newScore;
    }

    private static void setSprintMaxScore(String sprintId, String newMax) {
        update new Sprint__c(Id = sprintId, MaxScore__c = newMax);
    }

    private static void setBacklogMaxScore(String projectId, String newMax) {
        update new Project__c(Id = projectId, BacklogMaxScore__c = newMax);
    }

    /**
     * Reload all tickets in the scope (excluding movedTicket), insert
     * movedTicket either at the head or right after `beforeTicket`, then
     * reassign Score__c = SCORE_GAP, 2*SCORE_GAP, … in a single update.
     * Also bumps the scope's MaxScore to the last score.
     */
    private static Ticket__c rebalanceScope(
        Ticket__c movedTicket,
        Ticket__c beforeTicket,
        Boolean isBacklog,
        String projectId,
        Set<Id> backlogTypeIds
    ) {
        List<Ticket__c> existing;
        if (!isBacklog) {
            existing = [
                SELECT Id, Score__c, Sprint__c
                FROM Ticket__c
                WHERE Sprint__c = :movedTicket.Sprint__c
                  AND RecordStatus__c != 'deleted'
                  AND Id != :movedTicket.Id
                ORDER BY Score__c ASC NULLS LAST
            ];
        } else {
            existing = [
                SELECT Id, Score__c, Sprint__c
                FROM Ticket__c
                WHERE Ticket_Type__c IN :backlogTypeIds
                  AND Sprint__c = null
                  AND RecordStatus__c != 'deleted'
                  AND Id != :movedTicket.Id
                ORDER BY Score__c ASC NULLS LAST
            ];
        }

        List<Ticket__c> ordered = new List<Ticket__c>();
        if (beforeTicket == null) {
            ordered.add(movedTicket);
            ordered.addAll(existing);
        } else {
            Boolean inserted = false;
            for (Ticket__c t : existing) {
                ordered.add(t);
                if (t.Id == beforeTicket.Id) {
                    ordered.add(movedTicket);
                    inserted = true;
                }
            }
            if (!inserted) ordered.add(movedTicket);
        }

        List<Ticket__c> toUpdate = new List<Ticket__c>();
        Integer running = 0;
        for (Ticket__c t : ordered) {
            running += SCORE_GAP;
            t.Score__c = padScore(running);
            toUpdate.add(t);
        }
        update toUpdate;

        String newMax = padScore(running);
        if (isBacklog) setBacklogMaxScore(projectId, newMax);
        else setSprintMaxScore(movedTicket.Sprint__c, newMax);

        return movedTicket;
    }

    private static Ticket__c findSuccessor(Ticket__c movedTicket, String beforeScore, Set<Id> backlogTypeIds) {
        Id excludeId = movedTicket.Id;
        if (String.isNotBlank(movedTicket.Sprint__c)) {
            List<Ticket__c> rows = [
                SELECT Id, Score__c
                FROM Ticket__c
                WHERE Sprint__c = :movedTicket.Sprint__c
                  AND RecordStatus__c != 'deleted'
                  AND Id != :excludeId
                  AND Score__c > :beforeScore
                ORDER BY Score__c ASC NULLS LAST
                LIMIT 1
            ];
            return rows.isEmpty() ? null : rows[0];
        }
        List<Ticket__c> rows = [
            SELECT Id, Score__c
            FROM Ticket__c
            WHERE Ticket_Type__c IN :backlogTypeIds
              AND Sprint__c = null
              AND RecordStatus__c != 'deleted'
              AND Id != :excludeId
              AND Score__c > :beforeScore
            ORDER BY Score__c ASC NULLS LAST
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static Set<Id> projectTicketTypeIds(String projectId) {
        List<TicketType__c> types = [
            SELECT Id FROM TicketType__c
            WHERE Project__c = :projectId AND RecordStatus__c != 'deleted'
        ];
        Set<Id> ids = new Set<Id>();
        for (TicketType__c t : types) ids.add(t.Id);
        return ids;
    }

    private static String padScore(Integer n) {
        if (n == null || n < 0) n = 0;
        String s = String.valueOf(n);
        while (s.length() < SCORE_LENGTH) s = '0' + s;
        return s;
    }

    private static Integer parseScore(String s) {
        if (String.isBlank(s)) return 0;
        try {
            return Integer.valueOf(s);
        } catch (Exception e) {
            return 0;
        }
    }


    // ═══════════════════════════════════════════════════════════════
    // SUBTASK
    // ═══════════════════════════════════════════════════════════════

    public static Subtask__c findSubtaskById(String subtaskId) {
        try {
            List<Subtask__c> res = [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Id = :subtaskId
                LIMIT 1
            ];
            return res.isEmpty() ? null : res[0];
        } catch (Exception ex) {
            throw new ServiceException('Error retrieving subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c createSubtask(Subtask__c s) {
        try {
            s.RecordStatus__c = 'active';
            String projectId = resolveProjectIdForSubtask(s);
            s.Name = NameSequenceService.nextSubtaskName(projectId);
            insert s;
            return s;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating subtask: ' + ex.getMessage());
        }
    }

    private static String resolveProjectIdForSubtask(Subtask__c s) {
        if (String.isBlank(s.Ticket__c)) {
            throw new ServiceException('Subtask.Ticket__c is required to derive default Name');
        }
        List<Ticket__c> rows = [
            SELECT Id, Ticket_Type__r.Project__c
            FROM Ticket__c
            WHERE Id = :s.Ticket__c AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (rows.isEmpty() || rows[0].Ticket_Type__r == null) {
            throw new ServiceException('Cannot resolve project for subtask Ticket ' + s.Ticket__c);
        }
        return rows[0].Ticket_Type__r.Project__c;
    }

    public static Subtask__c updateSubtask(Subtask__c s) {
        try {
            update s;
            return s;
        } catch (DmlException dex) {
            throw new ServiceException('DML error updating subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }


    public static Subtask__c assignSubtask(Subtask__c existing, String memberId) {
        try {
            existing.Assignee__c = memberId;
            return updateSubtask(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error assigning subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtask(Subtask__c subtask) {
        try {
            subtask.RecordStatus__c = 'deleted';
            updateSubtask(subtask);
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting subtask: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasks(List<String> subtaskIds) {
        try {
            List<Subtask__c> found = [SELECT Id, RecordStatus__c FROM Subtask__c WHERE Id IN :subtaskIds];
            if (!found.isEmpty()) {
                for (Subtask__c s : found) s.RecordStatus__c = 'deleted';
                update found;
            }
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting subtasks: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting subtasks: ' + ex.getMessage());
        }
    }

    public static List<Subtask__c> getSubtasksByTicket(Ticket__c ticket) {
        try {
            return [
                SELECT Id, Name, Summary__c, Description__c, CurrentState__c,
                       Assignee__c, StartDate__c, Ticket__c, RecordStatus__c
                FROM Subtask__c
                WHERE Ticket__c = :ticket.Id AND RecordStatus__c != 'deleted'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskSummary(Subtask__c existing, String summary) {
        try {
            existing.Summary__c = summary;
            return updateSubtask(existing);
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskWithValidation(Subtask__c subtask) {
        try {
            return updateSubtask(subtask);
        } catch (Exception ex) {
            throw new ServiceException('Error updating subtask: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET TYPE
    // ═══════════════════════════════════════════════════════════════

    public static TicketType__c getTicketTypeById(String ticketTypeId) {
        List<TicketType__c> ticketTypes = [
            SELECT Id, Name, Project__c, Workflow__c, Description__c, IconUrl__c, CreatedDate
            FROM TicketType__c
            WHERE Id = :ticketTypeId
            LIMIT 1
        ];
        if (ticketTypes.isEmpty()) throw new ServiceException('Ticket Type not found');
        return ticketTypes[0];
    }

    public static TicketType__c createTicketType(String name, String description, String iconUrl, String workflowId, String projectId) {
        try {
            TicketType__c ticketType = new TicketType__c(
                Name            = name,
                Description__c  = description,
                IconUrl__c      = iconUrl,
                Workflow__c     = workflowId,
                Project__c      = projectId,
                RecordStatus__c = 'active'
            );
            insert ticketType;
            return ticketType;
        } catch (DmlException ex) {
            throw new ServiceException('Error creating ticket type: ' + ex.getMessage());
        }
    }

    public static List<TicketType__c> loadTicketTypes(Project__c project) {
        try {
            return [
                SELECT
                    Id,
                    Name,
                    Description__c,
                    IconUrl__c,
                    Project__c,
                    RecordStatus__c,
                    Workflow__c,
                    Workflow__r.Name
                FROM TicketType__c
                WHERE Project__c = :project.Id
                AND RecordStatus__c != 'deleted'
                ORDER BY Name ASC
            ];

        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket types: ' + ex.getMessage());
        }
    }

    public static TicketType__c deleteTicketType(TicketType__c ticketType) {
        try {
            List<Ticket__c> referencingTickets = [
                SELECT Id
                FROM Ticket__c
                WHERE Ticket_Type__c = :ticketType.Id
                  AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            DomainCompleteValidator.requireNoTicketsReferenceTicketType(referencingTickets);

            ticketType.RecordStatus__c = 'deleted';
            update ticketType;
            return ticketType;
        } catch (DmlException dex) {
            throw new ServiceException('DML error deleting ticket type: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error deleting ticket type: ' + ex.getMessage());
        }
    }

    public static TicketType__c updateTicketType(String ticketTypeId, String name, String iconUrl, String workflowId) {
        try {
            TicketType__c ticketType = DomainCorrectness.requireTicketTypeExists(ticketTypeId);

            if (ticketType.Workflow__c != workflowId) {
                List<Ticket__c> referencingTickets = [
                    SELECT Id
                    FROM Ticket__c
                    WHERE Ticket_Type__c = :ticketType.Id
                      AND RecordStatus__c != 'deleted'
                    LIMIT 1
                ];
                DomainCompleteValidator.requireNoTicketsReferenceTicketTypeOnWorkflowChange(referencingTickets);
            }

            ticketType.Name        = name;
            ticketType.IconUrl__c  = iconUrl;
            ticketType.Workflow__c = workflowId;
            update ticketType;
            return [
                SELECT Id, Name, Description__c, IconUrl__c, Project__c, RecordStatus__c,
                       Workflow__c, Workflow__r.Name
                FROM TicketType__c
                WHERE Id = :ticketType.Id
                  AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
        } catch (DmlException ex) {
            throw new ServiceException('Error updating ticket type: ' + ex.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TICKET LINKS
    // ═══════════════════════════════════════════════════════════════

    public static List<Map<String, String>> getTicketLinkTypes() {
        try {
            List<Map<String, String>> result = new List<Map<String, String>>();
            Schema.DescribeFieldResult fieldResult = TicketLink__c.Type__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    result.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            return result;
        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket link types: ' + ex.getMessage());
        }
    }

    public static void createTicketLink(String fromTicketId, String toTicketId, String linkType) {
        try {
            TicketLink__c link = new TicketLink__c(
                LinkedFromTicket__c = fromTicketId,
                LinkedToTicket__c   = toTicketId,
                Type__c             = linkType,
                RecordStatus__c     = 'active'
            );
            insert link;
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket link: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket link: ' + ex.getMessage());
        }
    }

    public static TicketLinkToDto linkToTicket(Ticket__c fromTicket, Ticket__c toTicket, TicketType__c fromTicketType, TicketType__c toTicketType, String linkType) {
        try {
            DomainCompleteValidator.requireSameProjectForTicketLink(fromTicketType, toTicketType);

            TicketLink__c link = new TicketLink__c(
                LinkedFromTicket__c = fromTicket.Id,
                LinkedToTicket__c   = toTicket.Id,
                Type__c             = linkType,
                RecordStatus__c     = 'active'
            );
            insert link;

            TicketLinkToDto dto   = new TicketLinkToDto();
            dto.linkId            = link.Id;
            dto.type              = linkType;
            dto.recordStatus      = link.RecordStatus__c;
            dto.ticketFromId      = fromTicket.Id;
            dto.linkedToTicket    = toLinkedToTicketFormat(toTicket);
            return dto;
        } catch (DmlException dex) {
            throw new ServiceException('DML error linking ticket: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error linking ticket: ' + ex.getMessage());
        }
    }

    public static List<TicketLinkToDto> getTicketLinkedTo(String ticketId) {
        try {
            List<TicketLink__c> links = [
                SELECT Id, Type__c, RecordStatus__c,
                       LinkedFromTicket__c,
                       LinkedToTicket__c,
                       LinkedToTicket__r.Id,
                       LinkedToTicket__r.Name,
                       LinkedToTicket__r.Summary__c,
                       LinkedToTicket__r.Priority__c,
                       LinkedToTicket__r.CurrentState__c,
                       LinkedToTicket__r.AssignedTo__c,
                       LinkedToTicket__r.Ticket_Type__c
                FROM TicketLink__c
                WHERE LinkedFromTicket__c = :ticketId AND RecordStatus__c != 'deleted'
            ];

            List<TicketLinkToDto> result = new List<TicketLinkToDto>();
            for (TicketLink__c link : links) {
                TicketLinkToDto dto  = new TicketLinkToDto();
                dto.linkId         = link.Id;
                dto.type           = link.Type__c;
                dto.recordStatus   = link.RecordStatus__c;
                dto.ticketFromId   = link.LinkedFromTicket__c;
                dto.linkedToTicket = toLinkedToTicketFormat(link.LinkedToTicket__r);
                result.add(dto);
            }
            return result;
        } catch (Exception ex) {
            throw new ServiceException('Error loading linked tickets: ' + ex.getMessage());
        }
    }

    // Single flat format for TicketLinkToDto.linkedToTicket, so links produced by
    // linkToTicket and getTicketLinkedTo always serialize identically (no __r).
    private static Ticket__c toLinkedToTicketFormat(Ticket__c t) {
        return new Ticket__c(
            Id              = t.Id,
            Name            = t.Name,
            Summary__c      = t.Summary__c,
            Priority__c     = t.Priority__c,
            CurrentState__c = t.CurrentState__c,
            AssignedTo__c   = t.AssignedTo__c,
            Ticket_Type__c  = t.Ticket_Type__c
        );
    }

    // ═══════════════════════════════════════════════════════════════
    // WORKFLOW STATE CHANGE
    // ═══════════════════════════════════════════════════════════════

    public static ChangeTicketStateDto changeTicketState(Ticket__c ticket, Status__c fromStatus, Status__c toStatus, List<WorkflowTransition__c> transitions) {
        try {
            // The allowed transition for this fromStatus → toStatus carries the
            // validation fields that must pass before the change is applied.
            WorkflowTransition__c transition = DomainCompleteValidator.requireTransitionAllowed(fromStatus.Id, toStatus.Id, transitions);

            List<ValidateField__c> validateFields = ValidateFieldService.loadValidateFieldsByTransition(transition.Id);
            DomainCompleteValidator.requireValidateFieldsPass(ticket, validateFields);

            ticket.CurrentState__c = toStatus.Id;
            updateTicket(ticket);

            Boolean isEndStatus = DomainCompleteValidator.isEndStatus(toStatus);
            Sprint__c updatedSprint = null;

            if (isEndStatus && String.isNotBlank(ticket.Sprint__c)) {
                updatedSprint = SprintService.increaseTotalAndEndedStoryPoint(ticket.Sprint__c, 0,ticket.StoryPoint__c);
            }

            return new ChangeTicketStateDto(isEndStatus, updatedSprint);
        } catch (Exception ex) {
            throw new ServiceException('Error changing ticket state: ' + ex.getMessage());
        }
    }

}

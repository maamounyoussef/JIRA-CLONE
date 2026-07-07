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

            List<Ticket__c> duplicates = [
                SELECT Id
                FROM Ticket__c
                WHERE Name = :ticket.Name
                AND Ticket_Type__r.Project__c = :ticketType.Project__c
                AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            DomainCompleteValidator.requireTicketNameUniquePerProject(duplicates);

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

            List<Ticket__c> duplicates = [
                SELECT Id
                FROM Ticket__c
                WHERE Name = :ticket.Name
                AND Ticket_Type__r.Project__c = :ticketType.Project__c
                AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            DomainCompleteValidator.requireTicketNameUniquePerProject(duplicates);

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
            System.debug('user Id : is ' + userId);
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

    // Story points roll up into the sprint totals, so a change on a ticket that
    // sits in a sprint must shift that sprint by the delta (and the ended total
    // too when the ticket is in an end status). Backlog tickets (no sprint) have
    // nothing to adjust. Returns the updated sprint, or null when none changed.
    public static Sprint__c updateTicketStoryPoint(Ticket__c existing, Integer storyPoint) {
        try {
            Decimal oldSP = existing.StoryPoint__c != null ? existing.StoryPoint__c : 0;
            Decimal newSP = storyPoint != null ? storyPoint : 0;
            Decimal delta = newSP - oldSP;

            existing.StoryPoint__c = storyPoint;
            updateTicket(existing);

            if (String.isBlank(existing.Sprint__c) || delta == 0) return null;

            Status__c status  = StatusService.findStatus(existing.CurrentState__c);
            Boolean   isEnd   = DomainCompleteValidator.isEndStatus(status);
            Decimal   totalMag = Math.abs(delta);
            Decimal   endedMag = isEnd ? totalMag : 0;

            return delta > 0
                ? SprintService.increaseTotalAndEndedStoryPoint(existing.Sprint__c, totalMag, endedMag)
                : SprintService.decreaseTotalAndEndedStoryPoints(existing.Sprint__c, totalMag, endedMag);
        } catch (Exception ex) {
            throw new ServiceException('Error updating ticket story point: ' + ex.getMessage());
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

    public static TicketType__c updateTicketType(String ticketTypeId, String name, String workflowId) {
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

            // IconUrl__c is no longer user-supplied — the icon is whatever file
            // is currently linked to this record (resolved by applyLinkedIcons).
            ticketType.Name        = name;
            ticketType.Workflow__c = workflowId;
            update ticketType;

            List<TicketType__c> rows = [
                SELECT Id, Name, Description__c, IconUrl__c, Project__c, RecordStatus__c,
                       Workflow__c, Workflow__r.Name
                FROM TicketType__c
                WHERE Id = :ticketType.Id
                  AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            applyLinkedIcons(rows);
            return rows.isEmpty() ? ticketType : rows[0];
        } catch (DmlException ex) {
            throw new ServiceException('Error updating ticket type: ' + ex.getMessage());
        }
    }

    /**
     * Load a project's ticket types with each icon resolved from its linked
     * file (ContentDocumentLink), not from a stored URL. Scoped to the
     * manage-ticket-type screen — the plain loadTicketTypes (used by backlog /
     * tracking) keeps returning the stored IconUrl__c untouched.
     */
    public static List<TicketType__c> loadTicketTypesWithLinkedIcons(Project__c project) {
        return applyLinkedIcons(loadTicketTypes(project));
    }

    /**
     * Link an uploaded file (ContentDocument) to a ticket-type record so it
     * becomes that type's icon. Used by the create flow, where the file is
     * uploaded before the record exists; edit-mode uploads link directly via
     * lightning-file-upload's record-id and don't need this.
     */
    public static void linkContentToTicketType(Id ticketTypeId, Id contentDocumentId) {
        try {
            insert new ContentDocumentLink(
                LinkedEntityId    = ticketTypeId,
                ContentDocumentId = contentDocumentId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
        } catch (DmlException dex) {
            throw new ServiceException('DML error linking icon to ticket type: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error linking icon to ticket type: ' + ex.getMessage());
        }
    }

    /**
     * Populate each ticket type's IconUrl__c (in memory — no DML) with a
     * download URL for the most recently linked file, or null when none is
     * linked. Bulk-safe: one ContentDocumentLink query for all the types, so
     * the SOQL count stays flat regardless of how many types are passed.
     */
    public static List<TicketType__c> applyLinkedIcons(List<TicketType__c> types) {
        try {
            if (types == null || types.isEmpty()) return types;

            Set<Id> typeIds = new Set<Id>();
            for (TicketType__c t : types) typeIds.add(t.Id);

            // Newest link wins: ASC order means later rows overwrite earlier ones.
            Map<Id, Id> versionIdByType = new Map<Id, Id>();
            for (ContentDocumentLink link : [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :typeIds
                ORDER BY ContentDocument.CreatedDate ASC
            ]) {
                if (link.ContentDocument != null && link.ContentDocument.LatestPublishedVersionId != null) {
                    versionIdByType.put(link.LinkedEntityId, link.ContentDocument.LatestPublishedVersionId);
                }
            }

            for (TicketType__c t : types) {
                Id versionId = versionIdByType.get(t.Id);
                t.IconUrl__c = (versionId != null)
                    ? '/sfc/servlet.shepherd/version/download/' + versionId
                    : null;
            }
            return types;
        } catch (Exception ex) {
            throw new ServiceException('Error resolving ticket type icons: ' + ex.getMessage());
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

    // ═══════════════════════════════════════════════════════════════
    // HISTORY LOG  (Ticket__History → activity feed)
    // ═══════════════════════════════════════════════════════════════

    private static final String FIELD_CREATED = 'created';
    private static final String FIELD_STATE   = 'CurrentState__c';
    private static final String FIELD_SCORE   = 'Score__c';

    /**
     * Build the ticket activity log from Ticket__History. Bulk-safe: a fixed
     * number of queries regardless of how many history rows exist —
     *   1× Ticket (resolve project), 1× Ticket__History,
     *   1× Status (bulk name resolve), 1× ProjectMember (bulk member resolve).
     * Each row becomes a TicketHistoryDto carrying the editor's avatar +
     * project-member name, the change date, and a derived message.
     */
    public static List<TicketHistoryDto> getTicketHistory(String ticketId) {
        try {
            List<Ticket__c> ticketRows = [
                SELECT Id, Ticket_Type__r.Project__c
                FROM Ticket__c
                WHERE Id = :ticketId AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            if (ticketRows.isEmpty()) return new List<TicketHistoryDto>();
            String projectId = ticketRows[0].Ticket_Type__r != null
                ? ticketRows[0].Ticket_Type__r.Project__c : null;

            List<Ticket__History> rows = [
                SELECT Id, Field, OldValue, NewValue, CreatedDate, CreatedById,
                       CreatedBy.Name
                FROM Ticket__History
                WHERE ParentId = :ticketId
                ORDER BY CreatedDate DESC
            ];
            if (rows.isEmpty()) return new List<TicketHistoryDto>();

            // Pass 1 — collect the ids we need to resolve in bulk.
            Set<Id> statusIds = new Set<Id>();
            Set<Id> userIds   = new Set<Id>();
            for (Ticket__History h : rows) {
                if (h.CreatedById != null) userIds.add(h.CreatedById);
                if (h.Field == FIELD_STATE) {
                    addIfId(statusIds, h.OldValue);
                    addIfId(statusIds, h.NewValue);
                }
            }

            // Cross-service reads stay in their owning services (service isolation).
            Map<Id, Status__c> statusById = StatusService.findStatusesByIds(statusIds);
            Map<Id, ProjectMember__c> memberByUser =
                ProjectService.findMembersByUserIdsAndProject(userIds, projectId);

            // Pass 2 — shape each row into a log entry.
            List<TicketHistoryDto> logs = new List<TicketHistoryDto>();
            for (Ticket__History h : rows) {
                TicketHistoryDto dto = new TicketHistoryDto();
                dto.id          = h.Id;
                dto.field       = h.Field;
                dto.createdDate = h.CreatedDate;

                ProjectMember__c pm = memberByUser.get(h.CreatedById);
                dto.memberName = (pm != null)
                    ? pm.Name
                    : (h.CreatedBy != null ? h.CreatedBy.Name : 'Unknown');

                dto.message = buildHistoryMessage(h, statusById);
                logs.add(dto);
            }
            return logs;
        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket history: ' + ex.getMessage());
        }
    }

    private static void addIfId(Set<Id> ids, Object value) {
        Id parsed = toId(value);
        if (parsed != null) ids.add(parsed);
    }

    private static Id toId(Object value) {
        if (value == null) return null;
        try {
            return Id.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null; // history value wasn't a parseable Id
        }
    }

    // Map a history row → a human-readable message. State changes spell out
    // old → new (by name); score (ordering) changes are noted without the value.
    private static String buildHistoryMessage(Ticket__History h, Map<Id, Status__c> statusById) {
        if (h.Field == FIELD_CREATED) {
            return 'Ticket created';
        }
        if (h.Field == FIELD_STATE) {
            String fromName = statusName(h.OldValue, statusById);
            String toName   = statusName(h.NewValue, statusById);
            return 'Status changed from ' + fromName + ' to ' + toName;
        }
        if (h.Field == FIELD_SCORE) {
            return 'Backlog order changed';
        }
        return 'Field updated';
    }

    private static String statusName(Object value, Map<Id, Status__c> statusById) {
        Id parsed = toId(value);
        if (parsed != null) {
            Status__c st = statusById.get(parsed);
            if (st != null) return st.Name;
        }
        return 'none';
    }

    // ═══════════════════════════════════════════════════════════════
    // COMMENTS  (TicketComment__c → ticket-view comment section)
    // ═══════════════════════════════════════════════════════════════

    /**
     * Load a ticket's comments, newest first, shaped for the ticket-view.
     * Bulk-safe: a single query resolves the author (project member) name +
     * avatar through the Creator__r lookup — no per-row queries, no DML.
     * Soft-deleted comments are excluded.
     */
    public static List<TicketCommentDto> getTicketComments(String ticketId) {
        try {
            List<TicketComment__c> rows = [
                SELECT Id, Message__c, CreatedDate,
                       Creator__c, Creator__r.Name
                FROM TicketComment__c
                WHERE Ticket__c = :ticketId AND RecordStatus__c != 'deleted'
                ORDER BY CreatedDate DESC
            ];

            List<TicketCommentDto> comments = new List<TicketCommentDto>();
            for (TicketComment__c c : rows) {
                comments.add(toCommentDto(c));
            }
            return comments;
        } catch (Exception ex) {
            throw new ServiceException('Error loading ticket comments: ' + ex.getMessage());
        }
    }

    /**
     * Post a comment on a ticket, authored by the running user's active project
     * member, and return it shaped for the ticket-view comment section (same
     * shape getTicketComments returns, so the UI can append it directly).
     *
     * Single-record operation: resolves the ticket's project (own object),
     * finds the running user's project member through ProjectService (service
     * isolation — never queries ProjectMember__c here), inserts one
     * TicketComment__c, then re-reads it once to build the DTO with the
     * author's name + avatar.
     */
    public static TicketCommentDto createTicketComment(String ticketId, String message) {
        try {
            String projectId = resolveProjectIdForTicketComment(ticketId);

            ProjectMember__c author = ProjectService.findActiveMemberByUserAndProject(
                UserInfo.getUserId(), projectId
            );
            if (author == null) {
                throw new ServiceException('You are not an active member of this project.');
            }

            TicketComment__c comment = new TicketComment__c(
                Ticket__c       = ticketId,
                Creator__c      = author.Id,
                Message__c      = message,
                RecordStatus__c = 'active'
            );
            insert comment;

            List<TicketComment__c> rows = [
                SELECT Id, Message__c, CreatedDate,
                       Creator__c, Creator__r.Name
                FROM TicketComment__c
                WHERE Id = :comment.Id AND RecordStatus__c != 'deleted'
                LIMIT 1
            ];
            return toCommentDto(rows[0]);
        } catch (DmlException dex) {
            throw new ServiceException('DML error creating ticket comment: ' + dex.getMessage());
        } catch (Exception ex) {
            throw new ServiceException('Error creating ticket comment: ' + ex.getMessage());
        }
    }

    private static String resolveProjectIdForTicketComment(String ticketId) {
        List<Ticket__c> rows = [
            SELECT Id, Ticket_Type__r.Project__c
            FROM Ticket__c
            WHERE Id = :ticketId AND RecordStatus__c != 'deleted'
            LIMIT 1
        ];
        if (rows.isEmpty() || rows[0].Ticket_Type__r == null) {
            throw new ServiceException('Cannot resolve project for ticket ' + ticketId);
        }
        return rows[0].Ticket_Type__r.Project__c;
    }

    private static TicketCommentDto toCommentDto(TicketComment__c c) {
        TicketCommentDto dto = new TicketCommentDto();
        dto.id          = c.Id;
        dto.message     = c.Message__c;
        dto.createdDate = c.CreatedDate;
        dto.memberName  = c.Creator__r != null ? c.Creator__r.Name : 'Unknown';
        return dto;
    }

}

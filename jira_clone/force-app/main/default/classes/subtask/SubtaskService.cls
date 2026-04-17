/**
 * @description Service layer for Subtask business logic
 */
public with sharing class SubtaskService {

    public static List<Subtask__c> getSubtasksByTicket(String ticketId) {
        try {
            if (String.isBlank(ticketId)) throw new SubtaskException('ticketId is required');
            // validate ticket exists
            TicketRepository.findTicketById(ticketId);
            return SubtaskRepository.findSubtasksByTicket(ticketId);
        } catch (TicketException tex) {
            throw new SubtaskException('Invalid ticket: ' + tex.getMessage());
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error loading subtasks: ' + ex.getMessage());
        }
    }

    /**
     * @description Create subtask from DTO
     * Pattern: Map DTO → Create Domain → Call Repository
     * @param dto SubtaskCreateDto containing creation values
     * @return Created Subtask__c object
     */
    public static Subtask__c createSubtask(SubtaskCreateDto dto) {
        try {
            if (dto == null) throw new SubtaskException('SubtaskCreateDto is required');
            if (String.isBlank(dto.summary)) throw new SubtaskException('summary is required');
            if (String.isBlank(dto.ticketId)) throw new SubtaskException('ticketId is required');

            // Validate ticket exists
            TicketRepository.findTicketById(dto.ticketId);

            // Map DTO to domain object
            Subtask__c subtask = SubtaskMapper.mapCreateSubtaskDtoToDomain(dto);

            // Call repo method with domain object
            return SubtaskRepository.createSubtask(subtask);
        } catch (TicketException tex) {
            throw new SubtaskException('Invalid ticket: ' + tex.getMessage());
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error creating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c createSubtaskLegacy(String summary, String description, String assigneeId, String ticketId) {
        try {
            if (String.isBlank(summary)) throw new SubtaskException('summary is required');
            if (String.isBlank(ticketId)) throw new SubtaskException('ticketId is required');

            // Validate ticket exists
            TicketRepository.findTicketById(ticketId);

            // Create domain object with all fields
            Subtask__c subtask = new Subtask__c();
            subtask.Summary__c = summary;
            subtask.Ticket__c = ticketId;
            
            if (String.isNotBlank(description)) {
                subtask.Description__c = description;
            }
            if (String.isNotBlank(assigneeId)) {
                subtask.Assignee__c = assigneeId;
            }

            // Call repo method with domain object
            return SubtaskRepository.createSubtask(subtask);
        } catch (TicketException tex) {
            throw new SubtaskException('Invalid ticket: ' + tex.getMessage());
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error creating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c updateSubtaskSummary(String subtaskId, String summary) {
        try {
            if (String.isBlank(subtaskId)) throw new SubtaskException('subtaskId is required');
            if (summary == null ) throw new SubtaskException('summary field is required');

            Subtask__c s = getSubtaskById(subtaskId);
            if (s == null) throw new SubtaskException('Subtask not found: ' + subtaskId);

            s.Summary__c = summary;
            return SubtaskRepository.updateSubtask(s);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error updating subtask: ' + ex.getMessage());
        }
    }

    /**
     * @description Update subtask with DTO
     * Pattern: Retrieve → Update via Mapper → Call Repository
     * @param dto SubtaskUpdateDto containing update values
     * @return Updated Subtask__c object
     */
    public static Subtask__c updateSubtask(SubtaskUpdateDto dto) {
        try {
            if (dto == null) throw new SubtaskException('dto is required');
            if (String.isBlank(dto.subtaskId)) throw new SubtaskException('subtaskId is required');

            // Retrieve the right object
            Subtask__c existing = getSubtaskById(dto.subtaskId);
            if (existing == null) throw new SubtaskException('Subtask not found: ' + dto.subtaskId);

            // Update the right fields using mapper
            Subtask__c toUpdate = SubtaskMapper.mapUpdateSubtaskDtoToDomain(dto, existing);

            // Call repo method with updated domain object
            return SubtaskRepository.updateSubtask(toUpdate);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error updating subtask: ' + ex.getMessage());
        }
    }

    public static Subtask__c getSubtaskById(String subtaskId) {
        try {
            return SubtaskRepository.findSubtaskById(subtaskId);
        } catch (Exception ex) {
            throw new SubtaskException('Error retrieving subtask: ' + ex.getMessage());
        }
    }

    public static void deleteSubtasks(List<String> subtaskIds) {
        try {
            if (subtaskIds == null || subtaskIds.isEmpty()) throw new SubtaskException('subtaskIds are required');
            SubtaskRepository.deleteSubtasksByIds(subtaskIds);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error deleting subtasks: ' + ex.getMessage());
        }
    }

    public static Subtask__c assignSubtask(String subtaskId, String memberId) {
        try {
            if (String.isBlank(subtaskId)) throw new SubtaskException('subtaskId is required');
            if (String.isBlank(memberId)) throw new SubtaskException('memberId is required');

            // Retrieve the right object
            Subtask__c existing = getSubtaskById(subtaskId);
            if (existing == null) throw new SubtaskException('Subtask not found: ' + subtaskId);

            // Update the right field
            existing.Assignee__c = memberId;

            // Call repo method with updated domain object
            return SubtaskRepository.updateSubtask(existing);
        } catch (SubtaskException sex) {
            throw sex;
        } catch (Exception ex) {
            throw new SubtaskException('Error assigning subtask: ' + ex.getMessage());
        }
    }
}
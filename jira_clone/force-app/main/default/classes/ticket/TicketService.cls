/**
 * @description Service layer for Ticket business logic
 * Performs validation and delegates to TicketRepository
 */
public with sharing class TicketService {

    public static List<Ticket__c> loadTickets(String projectId) {
        try {
            if (String.isBlank(projectId)) throw new TicketException('projectId is required');
            // validate project exists
            ProjectRepository.getProjectById(projectId);
            return TicketRepository.getTicketsByProject(projectId);
        } catch (ProjectException pex) {
            throw new TicketException('Invalid project: ' + pex.getMessage());
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error loading tickets: ' + ex.getMessage());
        }
    }

    /**
     * @description Retrieve ticket by Id
     * @param ticketId The Id of the ticket
     * @return The Ticket__c object
     */
    public static Ticket__c getTicketById(String ticketId) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            return TicketRepository.findTicketById(ticketId);
        } catch (Exception ex) {
            throw new TicketException('Error retrieving ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Create ticket from DTO
     * Pattern: Map DTO → Create Domain → Call Repository
     * @param dto TicketCreateDto containing creation values
     * @return Created Ticket__c object
     */
    public static Ticket__c createTicket(TicketCreateDto dto) {
        try {
            if (dto == null) throw new TicketException('TicketCreateDto is required');
            if (String.isBlank(dto.ticketTypeId)) throw new TicketException('ticket_type is required');
            if (String.isBlank(dto.name)) throw new TicketException('name is required');
            if (String.isBlank(dto.currentStateId)) throw new TicketException('current_state is required');

            // Validate ticket type exists
            TicketType__c tt = [SELECT Id FROM TicketType__c WHERE Id = :dto.ticketTypeId LIMIT 1];
            if (tt == null) throw new TicketException('Invalid ticket type');

            // Validate status exists
            Status__c status = [SELECT Id FROM Status__c WHERE Id = :dto.currentStateId LIMIT 1];
            if (status == null) throw new TicketException('Invalid status');

            // Map DTO to domain object
            Ticket__c ticket = TicketMapper.mapCreateTicketDtoToDomain(dto);

            // Call repo method with domain object
            return TicketRepository.createTicket(ticket);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error creating ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Create ticket from legacy parameters (backward compatibility)
     * @param name Ticket name
     * @param summary Ticket summary
     * @param description Ticket description
     * @param storyPoint Story point estimate
     * @param ticketTypeId Ticket type Id
     * @param assignedToId Project member Id to assign to
     * @return Created Ticket__c object
     */
    public static Ticket__c createTicketLegacy(String name, String summary, String description, Integer storyPoint, String ticketTypeId, String assignedToId) {
        try {
            if (String.isBlank(ticketTypeId)) throw new TicketException('ticket_type is required');
            if (String.isBlank(name)) throw new TicketException('name is required');

            // Create domain object with all fields
            Ticket__c ticket = new Ticket__c();
            ticket.Name = name;
            
            if (String.isNotBlank(summary)) {
                ticket.Summary__c = summary;
            }
            if (String.isNotBlank(description)) {
                ticket.Description__c = description;
            }
            if (storyPoint != null) {
                ticket.StoryPoint__c = storyPoint;
            }
            ticket.Ticket_Type__c = ticketTypeId;
            if (String.isNotBlank(assignedToId)) {
                ticket.AssignedTo__c = assignedToId;
            }

            // Call repo method with domain object
            return TicketRepository.createTicket(ticket);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error creating ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Update ticket with DTO
     * Pattern: Retrieve → Update via Mapper → Call Repository
     * @param dto TicketUpdateDto containing update values
     * @return Updated Ticket__c object
     */
    public static Ticket__c updateTicket(TicketUpdateDto dto) {
        try {
            if (dto == null) throw new TicketException('dto is required');
            if (String.isBlank(dto.ticketId)) throw new TicketException('ticketId is required');

            // Retrieve the right object
            Ticket__c existing = getTicketById(dto.ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + dto.ticketId);

            // Update the right fields using mapper
            Ticket__c toUpdate = TicketMapper.mapUpdateTicketDtoToDomain(dto, existing);

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(toUpdate);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Update ticket summary
     * Pattern: Retrieve → Update → Call Repository
     * @param ticketId Ticket Id
     * @param summary New summary value
     * @return Updated Ticket__c object
     */
    public static Ticket__c updateTicketSummary(String ticketId, String summary) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (summary == null) throw new TicketException('summary is required');

            // Retrieve the right object
            Ticket__c existing = getTicketById(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.Summary__c = summary;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket summary: ' + ex.getMessage());
        }
    }

    /**
     * @description Update ticket priority
     * Pattern: Retrieve → Update → Call Repository
     * @param ticketId Ticket Id
     * @param priority New priority value
     * @return Updated Ticket__c object
     */
    public static Ticket__c updateTicketPriority(String ticketId, String priority) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (priority == null) throw new TicketException('priority is required');

            // Retrieve the right object
            Ticket__c existing = getTicketById(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.Priority__c = priority;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket priority: ' + ex.getMessage());
        }
    }

    /**
     * @description Assign ticket to a project member
     * Pattern: Retrieve → Update → Call Repository
     * @param ticketId Ticket Id
     * @param memberId Project member Id
     * @return Updated Ticket__c object
     */
    public static Ticket__c assignTicket(String ticketId, String memberId) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (String.isBlank(memberId)) throw new TicketException('memberId is required');

            // Retrieve the right object
            Ticket__c existing = getTicketById(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.AssignedTo__c = memberId;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error assigning ticket: ' + ex.getMessage());
        }
    }

    /**
     * @description Update ticket state
     * Pattern: Retrieve → Update → Call Repository
     * @param ticketId Ticket Id
     * @param stateId Status Id
     * @return Updated Ticket__c object
     */
    public static Ticket__c updateTicketState(String ticketId, String stateId) {
        try {
            if (String.isBlank(ticketId)) throw new TicketException('ticketId is required');
            if (String.isBlank(stateId)) throw new TicketException('stateId is required');

            // Retrieve the right object
            Ticket__c existing = getTicketById(ticketId);
            if (existing == null) throw new TicketException('Ticket not found: ' + ticketId);

            // Update the right field
            existing.CurrentState__c = stateId;

            // Call repo method with updated domain object
            return TicketRepository.updateTicket(existing);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error updating ticket state: ' + ex.getMessage());
        }
    }

    public static void deleteTickets(List<String> ticketIds) {
        try {
            if (ticketIds == null || ticketIds.isEmpty()) throw new TicketException('ticketIds are required');
            TicketRepository.deleteTicketsByIds(ticketIds);
        } catch (TicketException tex) {
            throw tex;
        } catch (Exception ex) {
            throw new TicketException('Error deleting tickets: ' + ex.getMessage());
        }
    }
}
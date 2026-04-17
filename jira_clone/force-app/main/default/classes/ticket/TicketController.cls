/**
 * @description Controller for loading Ticket records for LWC components
 */
public with sharing class TicketController {

	@AuraEnabled
	public static APIResponse createTicket(String ticketCreateDtoJson) {
		try {
			TicketCreateDto dto = (TicketCreateDto) JSON.deserialize(ticketCreateDtoJson, TicketCreateDto.class);
			Ticket__c created = TicketService.createTicket(dto);
			return new APIResponse(true, 'Ticket created successfully', created);
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error creating ticket: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse updateTicket(String ticketUpdateDtoJson) {
		try {
			TicketUpdateDto dto = (TicketUpdateDto) JSON.deserialize(ticketUpdateDtoJson, TicketUpdateDto.class);
			if (dto == null) throw new TicketException('dto is required');
			Ticket__c updated = TicketService.updateTicket(dto);
			return new APIResponse(true, 'Ticket updated', updated);
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error updating ticket: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse updateTicketSummary(String ticketId, String summary) {
		try {
			Ticket__c updated = TicketService.updateTicketSummary(ticketId, summary);
			return new APIResponse(true, 'Ticket summary updated', updated);
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error updating ticket summary: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse updateTicketPriority(String ticketId, String priority) {
		try {
			Ticket__c updated = TicketService.updateTicketPriority(ticketId, priority);
			return new APIResponse(true, 'Ticket priority updated', updated);
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error updating ticket priority: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse assignTicket(String ticketId, String memberId) {
		try {
			Ticket__c updated = TicketService.assignTicket(ticketId, memberId);
			return new APIResponse(true, 'Ticket assignee updated', updated);
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error assigning ticket: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse updateTicketState(String ticketId, String stateId) {
		try {
			Ticket__c updated = TicketService.updateTicketState(ticketId, stateId);
			return new APIResponse(true, 'Ticket state updated', updated);
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error updating ticket state: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse deleteTicket(String ticketId) {
		try {
			TicketService.deleteTickets(new List<String>{ticketId});
			return new APIResponse(true, 'Ticket deleted');
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error deleting ticket: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse deleteTickets(List<String> ticketIds) {
		try {
			TicketService.deleteTickets(ticketIds);
			return new APIResponse(true, 'Tickets deleted');
		} catch (TicketException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error deleting tickets: ' + ex.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static APIResponse loadSubtasks(String ticketId) {
		try {
			List<Subtask__c> subs = SubtaskService.getSubtasksByTicket(ticketId);
			return new APIResponse(true, 'Subtasks loaded', subs);
		} catch (SubtaskException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error loading subtasks: ' + ex.getMessage());
		}
	}

}
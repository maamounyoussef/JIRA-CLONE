/**
 * @description Controller for loading Sprint records for LWC components
 * Always returns response encapsulated by APIResponse
 */
public with sharing class SprintController {

	@AuraEnabled
	public static APIResponse createSprint(String sprintCreateDtoJson) {
		try {
			SprintCreateDto dto = (SprintCreateDto) JSON.deserialize(sprintCreateDtoJson, SprintCreateDto.class);
			Sprint__c created = SprintService.createSprint(dto);
			return new APIResponse(true, 'Sprint created successfully', created);
		} catch (SprintException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error creating sprint: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse updateSprint(String sprintUpdateDtoJson) {
		try {
			SprintUpdateDto dto = (SprintUpdateDto) JSON.deserialize(sprintUpdateDtoJson, SprintUpdateDto.class);
			Sprint__c updated = SprintService.updateSprint(dto);
			return new APIResponse(true, 'Sprint updated successfully', updated);
		} catch (SprintException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error updating sprint: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse completeSprint(String sprintId) {
		try {
			SprintService.completeSprint(sprintId);
			return new APIResponse(true, 'Sprint completed');
		} catch (SprintException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error completing sprint: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse deleteSprint(String sprintId) {
		try {
			SprintService.deleteSprint(sprintId);
			return new APIResponse(true, 'Sprint deleted');
		} catch (SprintException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error deleting sprint: ' + ex.getMessage());
		}
	}

	@AuraEnabled
	public static APIResponse startSprint(String sprintId) {
		try {
			SprintService.startSprint(sprintId);
			return new APIResponse(true, 'Sprint started');
		} catch (SprintException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error starting sprint: ' + ex.getMessage());
		}
	}
}
/**
 * @description Controller for Subtask operations used by LWC/Aura
 */
public with sharing class SubtaskController {

    @AuraEnabled
	public static APIResponse createSubtask(String subtaskCreateDtoJson) {
		try {
			SubtaskCreateDto dto = (SubtaskCreateDto) JSON.deserialize(subtaskCreateDtoJson, SubtaskCreateDto.class);
			Subtask__c created = SubtaskService.createSubtask(dto);
			return new APIResponse(true, 'Subtask created', created);
		} catch (SubtaskException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error creating subtask: ' + ex.getMessage());
		}
	}

    @AuraEnabled
    public static APIResponse updateSubtaskSummary(String subtaskId, String summary) {
        try {
            Subtask__c updated = SubtaskService.updateSubtaskSummary(subtaskId, summary);
            return new APIResponse(true, 'Subtask summary updated', updated);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating subtask summary: ' + ex.getMessage());
        }
    }

    @AuraEnabled
	public static APIResponse updateSubtask(String subtaskUpdateDtoJson) {
		try {
			SubtaskUpdateDto dto = (SubtaskUpdateDto) JSON.deserialize(subtaskUpdateDtoJson, SubtaskUpdateDto.class);
			if (dto == null) throw new SubtaskException('dto is required');
			Subtask__c updated = SubtaskService.updateSubtask(dto);
			return new APIResponse(true, 'Subtask updated', updated);
		} catch (SubtaskException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error updating subtask: ' + ex.getMessage());
		}
	}

    @AuraEnabled
    public static APIResponse assignSubtask(String subtaskId, String memberId) {
        try {
            Subtask__c updated = SubtaskService.assignSubtask(subtaskId, memberId);
            return new APIResponse(true, 'Subtask assignee updated', updated);
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error assigning subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtask(String subtaskId) {
        try {
            SubtaskService.deleteSubtasks(new List<String>{subtaskId});
            return new APIResponse(true, 'Subtask deleted');
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtask: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse deleteSubtasks(List<String> subtaskIds) {
        try {
            SubtaskService.deleteSubtasks(subtaskIds);
            return new APIResponse(true, 'Subtasks deleted');
        } catch (SubtaskException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error deleting subtasks: ' + ex.getMessage());
        }
    }

}

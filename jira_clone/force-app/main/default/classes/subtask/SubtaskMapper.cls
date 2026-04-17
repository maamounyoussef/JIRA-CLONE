/**
 * @description Mapper for converting Subtask DTOs to Subtask__c domain objects
 * Function naming convention: map<FunctionGoal><DomainName>DtoToDomain
 */
public with sharing class SubtaskMapper {

    /**
     * @description Maps SubtaskCreateDto to new Subtask__c object
     * @param dto The DTO containing creation values
     * @return New Subtask__c object
     */
    public static Subtask__c mapCreateSubtaskDtoToDomain(SubtaskCreateDto dto) {
        if (dto == null) throw new SubtaskException('dto is required');

        Subtask__c subtask = new Subtask__c();
        subtask.Summary__c = dto.summary;
        subtask.Ticket__c = dto.ticketId;
        
        if (String.isNotBlank(dto.description)) {
            subtask.Description__c = dto.description;
        }
        if (String.isNotBlank(dto.assigneeId)) {
            subtask.Assignee__c = dto.assigneeId;
        }
        if (String.isNotBlank(dto.currentStateId)) {
            subtask.CurrentState__c = dto.currentStateId;
        }
        if (dto.storyPoint != null) {
            subtask.StoryPoint__c = dto.storyPoint;
        }
        if (dto.startDate != null) {
            subtask.StartDate__c = dto.startDate;
        }

        return subtask;
    }

    /**
     * @description Maps SubtaskUpdateDto to existing Subtask__c object
     * Only updates non-blank fields to preserve existing values
     * @param dto The DTO containing update values
     * @param existing The existing Subtask__c object to update
     * @return Updated Subtask__c object
     */
    public static Subtask__c mapUpdateSubtaskDtoToDomain(SubtaskUpdateDto dto, Subtask__c existing) {
        if (dto == null) throw new SubtaskException('dto is required');
        if (existing == null) throw new SubtaskException('existing subtask is required');

        if (String.isNotBlank(dto.summary)) {
            existing.Summary__c = dto.summary;
        }
        if (String.isNotBlank(dto.description)) {
            existing.Description__c = dto.description;
        }
        if (String.isNotBlank(dto.assigneeId)) {
            existing.Assignee__c = dto.assigneeId;
        }
        if (String.isNotBlank(dto.currentStateId)) {
            existing.CurrentState__c = dto.currentStateId;
        }
        if (dto.storyPoint != null) {
            existing.StoryPoint__c = dto.storyPoint;
        }

        return existing;
    }
}

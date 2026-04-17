/**
 * @description Mapper for converting Sprint DTOs to Sprint__c domain objects
 * Function naming convention: map<FunctionGoal><DomainName>DtoToDomain
 */
public class SprintMapper {

    /**
     * @description Maps SprintCreateDto to new Sprint__c object
     * @param dto The DTO containing creation values
     * @return New Sprint__c object
     */
    public static Sprint__c mapCreateSprintDtoToDomain(SprintCreateDto dto) {
        if (dto == null) {
            return null;
        }

        Sprint__c sprint = new Sprint__c();
        sprint.Name = dto.name;
        sprint.Duration__c = dto.duration;
        sprint.StartDate__c = dto.startDate;
        sprint.Goal__c = dto.goal;
        sprint.Project__c = dto.projectId;
        sprint.RecordStatus__c = 'future';

        return sprint;
    }

    /**
     * @description Maps SprintUpdateDto to existing Sprint__c object
     * Only updates non-blank fields to preserve existing values
     * @param dto The DTO containing update values
     * @param existing The existing Sprint__c object to update
     * @return Updated Sprint__c object
     */
    public static Sprint__c mapUpdateSprintDtoToDomain(SprintUpdateDto dto, Sprint__c existing) {
        if (dto == null || existing == null) {
            return existing;
        }

        if (String.isNotBlank(dto.name)) {
            existing.Name = dto.name;
        }

        if (dto.duration != null) {
            existing.Duration__c = dto.duration;
        }

        if (dto.startDate != null) {
            existing.StartDate__c = dto.startDate;
        }

        if (String.isNotBlank(dto.goal)) {
            existing.Goal__c = dto.goal;
        }

        return existing;
    }
}

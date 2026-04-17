/**
 * @description Mapper for converting Epic DTOs to Epic__c domain objects
 * Function naming convention: map<FunctionGoal><DomainName>DtoToDomain
 */
public with sharing class EpicMapper {

    /**
     * @description Maps EpicCreateDto to new Epic__c object
     * @param dto The DTO containing creation values
     * @return New Epic__c object
     */
    public static Epic__c mapCreateEpicDtoToDomain(EpicCreateDto dto) {
        if (dto == null) throw new EpicException('dto is required');

        Epic__c epic = new Epic__c();
        epic.Name = dto.name;
        epic.Summary__c = dto.summary;
        epic.Project__c = dto.projectId;
        
        if (String.isNotBlank(dto.description)) {
            epic.Description__c = dto.description;
        }
        if (dto.startDate != null) {
            epic.StartDate__c = dto.startDate;
        }
        if (dto.endDate != null) {
            epic.EndDate__c = dto.endDate;
        }

        return epic;
    }

    /**
     * @description Maps EpicUpdateDto to existing Epic__c object
     * Only updates non-blank fields to preserve existing values
     * @param dto The DTO containing update values
     * @param existing The existing Epic__c object to update
     * @return Updated Epic__c object
     */
    public static Epic__c mapUpdateEpicDtoToDomain(EpicUpdateDto dto, Epic__c existing) {
        if (dto == null) throw new EpicException('dto is required');
        if (existing == null) throw new EpicException('existing epic is required');

        if (String.isNotBlank(dto.name)) {
            existing.Name = dto.name;
        }
        if (String.isNotBlank(dto.summary)) {
            existing.Summary__c = dto.summary;
        }
        if (String.isNotBlank(dto.description)) {
            existing.Description__c = dto.description;
        }
        if (dto.startDate != null) {
            existing.StartDate__c = dto.startDate;
        }
        if (dto.endDate != null) {
            existing.EndDate__c = dto.endDate;
        }

        return existing;
    }
}

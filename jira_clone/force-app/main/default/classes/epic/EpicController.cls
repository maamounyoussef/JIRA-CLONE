/**
 * @description Controller for Epic operations used by LWC/Aura
 */
public with sharing class EpicController {

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicsByProject(String projectId) {
        try {
            List<Epic__c> epics = EpicService.getEpicsByProject(projectId);
            return new APIResponse(true, 'Epics retrieved successfully', epics);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epics: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static APIResponse getEpicById(String epicId) {
        try {
            Epic__c epic = EpicService.getEpicById(epicId);
            return new APIResponse(true, 'Epic retrieved successfully', epic);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error retrieving epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse createEpic(String epicCreateDtoJson) {
        try {
            EpicCreateDto dto = (EpicCreateDto) JSON.deserialize(epicCreateDtoJson, EpicCreateDto.class);
            Epic__c created = EpicService.createEpic(dto);
            return new APIResponse(true, 'Epic created successfully', created);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error creating epic: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static APIResponse updateEpic(String epicUpdateDtoJson) {
        try {
            EpicUpdateDto dto = (EpicUpdateDto) JSON.deserialize(epicUpdateDtoJson, EpicUpdateDto.class);
            Epic__c updated = EpicService.updateEpic(dto);
            return new APIResponse(true, 'Epic updated successfully', updated);
        } catch (EpicException ex) {
            return new APIResponse(false, ex.getMessage());
        } catch (Exception ex) {
            return new APIResponse(false, 'Error updating epic: ' + ex.getMessage());
        }
    }
}

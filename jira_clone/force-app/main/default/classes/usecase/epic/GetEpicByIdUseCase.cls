/**
 * @description Use Case for retrieving an epic by ID
 * Handles validation and retrieval of a single epic
 */
public with sharing class GetEpicByIdUseCase {
    
    /**
     * @description Retrieve an epic by ID
     * @param epicId - The Epic__c record Id
     * @return The Epic__c object
     * @throws EpicException - If epicId is blank or other errors occur
     */
    public static Epic__c execute(String epicId) {
        try {
            if (String.isBlank(epicId)) {
                throw new EpicException('epicId is required');
            }
            
            return EpicRepository.findEpicById(epicId);
        } catch (Exception ex) {
            throw new EpicException('Error retrieving epic: ' + ex.getMessage());
        }
    }
}
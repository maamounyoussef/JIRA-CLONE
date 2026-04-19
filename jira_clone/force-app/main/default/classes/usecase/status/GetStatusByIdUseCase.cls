/**
 * @description Use Case for retrieving a status by Id
 * Handles validation and retrieval of status
 */
public with sharing class GetStatusByIdUseCase {
    
    /**
     * @description Get status by Id
     * @param statusId - The Status__c record Id
     * @return Status__c object
     * @throws StatusException - If statusId is blank or status not found
     */
    public static Status__c execute(String statusId) {
        try {
            if (String.isBlank(statusId)) {
                throw new StatusException('Status Id is required');
            }
            
            return StatusRepository.getStatusById(statusId);
        } catch (StatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new StatusException('Error retrieving status by id: ' + ex.getMessage());
        }
    }
}

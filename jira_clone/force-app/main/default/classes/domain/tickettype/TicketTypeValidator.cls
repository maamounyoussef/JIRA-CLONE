/**
 * @description Validator for TicketType__c business rules
 */
public with sharing class TicketTypeValidator {

    /**
     * @description Check if a TicketType exists by ID
     * @param ticketTypeId The TicketType ID
     * @return true if the TicketType exists, false otherwise
     */
    public static Boolean exists(String ticketTypeId) {
        if (String.isBlank(ticketTypeId)) return false;
        try {
            List<TicketType__c> ticketTypes = [
                SELECT Id
                FROM TicketType__c
                WHERE Id = :ticketTypeId
                LIMIT 1
            ];
            return !ticketTypes.isEmpty();
        } catch (Exception ex) {
            throw new TicketTypeException('Error checking ticket type existence: ' + ex.getMessage());
        }
    }
}

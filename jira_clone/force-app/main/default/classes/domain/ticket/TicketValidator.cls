/**
 * @description Validator for Ticket__c business rules
 */
public with sharing class TicketValidator {

    /**
     * @description Check if a Ticket exists by ID
     * @param ticketId The Ticket ID
     * @return true if the Ticket exists, false otherwise
     */
    public static Boolean exists(String ticketId) {
        if (String.isBlank(ticketId)) return false;
        try {
            List<Ticket__c> tickets = [
                SELECT Id
                FROM Ticket__c
                WHERE Id = :ticketId
                LIMIT 1
            ];
            return !tickets.isEmpty();
        } catch (Exception ex) {
            throw new TicketException('Error checking ticket existence: ' + ex.getMessage());
        }
    }
}

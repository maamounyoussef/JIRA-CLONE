/**
 * @description Validator for input security constraints at the controller level
 * Enforces limits and security boundaries for API operations
 */
public with sharing class InputSecurityValidator {

    public static void validateTicketDeletionLimit(List<String> ticketIds) {
        if (ticketIds != null && ticketIds.size() > 24) {
            throw new InputSecurityException('Cannot delete more than 24 tickets at a time');
        }
    }

    public class InputSecurityException extends Exception {}
}

/**
 * @description Validator for User business rules
 */
public with sharing class UserValidator {

    /**
     * @description Check if a User exists by ID
     * @param userId The User ID
     * @return true if the User exists, false otherwise
     */
    public static Boolean exists(String userId) {
        if (String.isBlank(userId)) return false;
        try {
            List<User> users = [
                SELECT Id
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];
            return !users.isEmpty();
        } catch (Exception ex) {
            throw new UserException('Error checking user existence: ' + ex.getMessage());
        }
    }
}

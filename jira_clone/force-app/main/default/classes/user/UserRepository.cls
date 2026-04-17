/**
 * @description Repository for User DB operations
 */
public with sharing class UserRepository {

    public static List<User> getActiveUsers() {
        try {
            return [SELECT Id, Name, Email FROM User WHERE IsActive = TRUE ORDER BY Name];
        } catch (Exception ex) {
            throw new UserException('Error querying users: ' + ex.getMessage());
        }
    }
}
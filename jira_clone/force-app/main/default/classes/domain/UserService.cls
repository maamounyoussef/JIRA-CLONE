/**
 * @description Service class for User operations
 * Consolidates all usecases and repository methods for User domain
 */
public with sharing class UserService {
    
    // Repository methods
    public static List<User> getActiveUsers() {
        try {
            return [SELECT Id, Name, Email FROM User WHERE IsActive = TRUE ORDER BY Name];
        } catch (Exception ex) {
            throw new Exception('Error querying users: ' + ex.getMessage());
        }
    }
    
    // Use case methods
    public static List<User> loadUsers() {
        try {
            return getActiveUsers();
        } catch (Exception ex) {
            throw new Exception('Error loading users: ' + ex.getMessage());
        }
    }
}

/**
 * @description Service class for User operations
 * Consolidates all usecases and repository methods for User domain
 */
public with sharing class UserService {
    
    public static List<User> loadUsers() {
        try {
            return [SELECT Id, Name, Email FROM User WHERE IsActive = TRUE ORDER BY Name];
        } catch (Exception ex) {
            throw new ServiceException('Error loading users: ' + ex.getMessage());
        }
    }
}

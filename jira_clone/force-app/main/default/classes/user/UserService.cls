/**
 * @description Service layer for User business logic
 */
public with sharing class UserService {

    public static List<User> loadUsers() {
        try {
            return UserRepository.getActiveUsers();
        } catch (UserException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new UserException('Error loading users: ' + ex.getMessage());
        }
    }
}
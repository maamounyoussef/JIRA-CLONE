/**
 * @description Use case to load active users
 */
public with sharing class LoadUsersUseCase {

    public static List<User> execute() {
        try {
            return UserRepository.getActiveUsers();
        } catch (UserException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new UserException('Error loading users: ' + ex.getMessage());
        }
    }
}

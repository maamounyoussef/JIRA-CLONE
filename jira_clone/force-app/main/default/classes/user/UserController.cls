/**
 * @description Simple Apex controller to load active Users for LWC selects
 */
public with sharing class UserController {

	@AuraEnabled(cacheable=true)
	public static APIResponse loadUsers() {
		try {
			List<User> users = UserService.loadUsers();
			return new APIResponse(true, 'Users loaded successfully', users);
		} catch (UserException ex) {
			return new APIResponse(false, ex.getMessage());
		} catch (Exception ex) {
			return new APIResponse(false, 'Error loading users: ' + ex.getMessage());
		}
	}

}
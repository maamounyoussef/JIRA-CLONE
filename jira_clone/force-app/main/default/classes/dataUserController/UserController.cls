/**
 * @description Simple Apex controller to load active Users for LWC selects
 */
public with sharing class UserController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadUsers() {
        try {
            List<User> users = [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name LIMIT 1000];
            return new APIResponse(true, 'Users loaded successfully', users);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading users: ' + ex.getMessage());
        }
    }

}

/**
 * @description Controller for the reusable c-choose-project splash page.
 * Exposes the projects list so the splash can render selectable cards.
 * All business logic lives in ProjectService.
 */
public with sharing class ProjectSplashController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadAllProjects() {
        try {
            List<Project__c> projects = ProjectService.loadProjects();
            return new APIResponse(true, 'Projects loaded successfully', projects);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading projects: ' + ex.getMessage());
        }
    }
}

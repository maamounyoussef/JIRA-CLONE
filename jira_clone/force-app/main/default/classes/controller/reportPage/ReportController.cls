/**
 * @description Endpoint for the Report Page.
 * Returns the report details (gallery cards + detail view) for a given project.
 */
public with sharing class ReportController {

    @AuraEnabled(cacheable=true)
    public static APIResponse loadReportDetailsByProject(String projectId) {
        try {
            if (String.isBlank(projectId)) return new APIResponse(false, 'projectId is required');

            Project__c project = DomainCorrectness.requireProjectExists(projectId);

            List<Report_Detail__c> reportDetails = ReportDetailService.getReportDetailsByProject(project);

            return new APIResponse(true, 'Report details loaded', reportDetails);
        } catch (Exception ex) {
            return new APIResponse(false, 'Error loading report details: ' + ex.getMessage());
        }
    }
}

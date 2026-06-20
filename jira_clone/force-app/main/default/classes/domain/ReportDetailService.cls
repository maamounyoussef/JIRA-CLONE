/**
 * @description Service class for Report Detail operations.
 * Owns all SOQL/DML against Report_Detail__c; callers pass a resolved
 * Project__c and receive the report details that belong to it.
 */
public with sharing class ReportDetailService {

    /**
     * Loads every report detail for a project, ordered by name.
     * One SOQL into a List — bulk-safe regardless of how many details exist.
     */
    public static List<Report_Detail__c> getReportDetailsByProject(Project__c project) {
        try {
            return [
                SELECT Id, Name, Description__c, Image_URL__c, Salesforce_Report__c, Project__c
                FROM Report_Detail__c
                WHERE Project__c = :project.Id
                ORDER BY Name ASC
            ];
        } catch (Exception ex) {
            throw new ServiceException('Error querying report details: ' + ex.getMessage());
        }
    }
}

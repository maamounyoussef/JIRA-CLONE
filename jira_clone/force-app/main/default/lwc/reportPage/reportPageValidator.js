/**
 * reportPageValidator — client-side validation for reportPage.
 *
 * NOTE: the project's OBJECT_VALIDATION_LWC_APEX.md reference file is not present
 * in the repo, and "validate the report id" is a presence/format check (not a
 * table-driven required field), so the messages below are defined directly here.
 */

// Salesforce record Id: 15 (case-sensitive) or 18 (case-safe) alphanumeric chars.
const SF_ID_PATTERN = /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/;

/**
 * Validate the Salesforce report id before building the report URL.
 * @param {string} reportId value of Report_Detail__c.Salesforce_Report__c
 * @returns {{ valid: boolean, message: string }}
 */
export function validateReportId(reportId) {
    if (!reportId) {
        return { valid: false, message: 'This report detail has no linked Salesforce report.' };
    }
    if (!SF_ID_PATTERN.test(reportId)) {
        return { valid: false, message: 'The linked Salesforce report id is not valid.' };
    }
    return { valid: true, message: '' };
}

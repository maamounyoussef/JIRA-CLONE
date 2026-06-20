/**
 * Sprint Utils
 * Utility functions for the sprint domain.
 */

/**
 * Calculates the sprint end date from start date plus duration in days.
 */
export function calcEndDate(startDate, duration) {
    if (!startDate || !duration) return '';
    const end = new Date(startDate);
    end.setDate(end.getDate() + Number(duration));
    return end.toLocaleDateString();
}

/**
 * Formats a human-readable date range label for the sprint header.
 */
export function formatSprintDateRange(sprint) {
    if (!sprint) return '';
    const start = sprint.StartDate__c ? new Date(sprint.StartDate__c).toLocaleDateString() : '';
    const end   = calcEndDate(sprint.StartDate__c, sprint.Duration__c);
    return start && end ? `${start} – ${end}` : start || end;
}

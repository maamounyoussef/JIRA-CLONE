/**
 * Sprint Utils
 * Utility functions for the sprint domain.
 */

export const PAGE_SIZE = 5;

export function calcEndDate(startDate, duration) {
    if (!startDate || !duration) return '';
    const d = new Date(startDate);
    d.setDate(d.getDate() + parseInt(duration, 10));
    return d.toISOString().split('T')[0];
}

export function emptySprintForm() {
    return { name: '', duration: null, startDate: '', goal: '' };
}

export function formatSprint(raw) {
    return {
        ...raw,
        isComplete      : raw.RecordStatus__c === 'completed',
        endDate         : calcEndDate(raw.StartDate__c, raw.Duration__c),
        chevronIcon     : 'utility:chevronright',
        isExpanded      : false,
        isLoadingTickets: false,
        tickets         : [],
        hasTickets      : false,
        offset          : 0,
        hasMore         : false,
        isFirstPage     : true,
        isLastPage      : true,
        currentPage     : 1,
        offsetLabel     : 'No tickets',
        dropTargetClass : 'sprint-container',
    };
}

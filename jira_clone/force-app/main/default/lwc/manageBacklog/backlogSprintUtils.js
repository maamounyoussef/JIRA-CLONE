/**
 * Sprint Utils
 * Utility functions for the sprint domain.
 */

export function emptySprintForm() {
    return { name: '', duration: null, startDate: '', goal: '' };
}

export function formatSprint(raw) {
    return {
        ...raw,
        isComplete: raw.RecordStatus__c === 'complete',
    };
}

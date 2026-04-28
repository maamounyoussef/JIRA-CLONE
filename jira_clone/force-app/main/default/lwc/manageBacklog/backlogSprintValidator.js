/**
 * Sprint Validator
 * Validations for the sprint domain.
 */

const SPRINT_NAME_MAX  = 80;
const DURATION_MIN     = 1;
const DURATION_MAX     = 999; // Sprint__c.Duration__c precision 3 scale 0

// Sprint__c LWC required: name, duration, goal. startDate is optional.
export function validateSprintForm({ name, duration, goal }) {
    if (!name || !name.trim()) return 'Sprint name is required.';
    if (name.trim().length > SPRINT_NAME_MAX) return `Sprint name must be ${SPRINT_NAME_MAX} characters or fewer.`;
    if (duration === '' || duration === null || duration === undefined) return 'Duration is required.';
    const dur = Number(duration);
    if (!Number.isInteger(dur) || dur < DURATION_MIN || dur > DURATION_MAX) {
        return `Duration must be a whole number between ${DURATION_MIN} and ${DURATION_MAX}.`;
    }
    if (!goal || !goal.trim()) return 'Goal is required.';
    return null;
}

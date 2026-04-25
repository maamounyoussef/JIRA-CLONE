/**
 * Sprint Validator
 * Validations for the sprint domain.
 */

export function validateSprintForm({ name, duration, startDate, goal }) {
    if (!name || !duration || !startDate || !goal) return 'All sprint fields are required.';
    return null;
}

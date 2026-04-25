/**
 * Sprint Utils
 * Utility functions for the sprint domain.
 * Add formatters, mappers, and factory functions here as the domain grows.
 */

export function calcEndDate(startDate, duration) {
    if (!startDate || !duration) return '';
    const d = new Date(startDate);
    d.setDate(d.getDate() + parseInt(duration, 10));
    return d.toISOString().split('T')[0];
}

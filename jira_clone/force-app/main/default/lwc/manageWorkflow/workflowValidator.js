/**
 * Manage Workflow Validator
 * Page-side validation run before any Apex call. Each function returns an error
 * string when invalid, or null when valid (same convention as the backlog
 * validators).
 */

export function validateStatusName(name) {
    const trimmed = (name || '').trim();
    if (!trimmed) return 'Name is required';
    if (name.length > 80) return 'Name must be 80 characters or less';
    return null;
}

export function validateTransition({ fromStatus, toStatus } = {}) {
    if (!fromStatus || !toStatus) return 'Both from and to statuses are required';
    if (fromStatus === toStatus) return 'From and To cannot be the same status';
    return null;
}

export function validateTransitionName(name) {
    if (!(name || '').trim()) return 'Transition name is required';
    return null;
}

export function validateValidationType(type) {
    if (!(type || '').trim()) return 'Validation type is required';
    return null;
}

export function validateTicketField(field) {
    if (!(field || '').trim()) return 'Ticket field is required';
    return null;
}

export function validateTransitionId(transitionId) {
    if (!(transitionId || '').trim()) return 'A transition must be selected before loading its validation details';
    return null;
}

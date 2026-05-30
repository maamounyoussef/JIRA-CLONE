export const ALLOWED_ROLES = [
    'PPO',
    'Consultant',
    'Test Factory',
    'Scrum Master',
    'Developer'
];

export function isSearchTermLongEnough(term) {
    return typeof term === 'string' && term.trim().length >= 2;
}

export function isUserNotAlreadyMember(userId, currentMembers) {
    if (!userId || !Array.isArray(currentMembers)) return false;
    return !currentMembers.some(m => m.User__c === userId);
}

export function isRoleAllowed(role) {
    return ALLOWED_ROLES.includes(role);
}

export function isDeleteConfirmed(confirmed) {
    return confirmed === true;
}

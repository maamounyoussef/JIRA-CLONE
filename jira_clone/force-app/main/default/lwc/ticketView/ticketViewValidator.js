/**
 * Ticket View Validator
 * LWC-side validation for the Ticket View screen.
 * Required fields per OBJECT_VALIDATION_LWC_APEX.md (LWC table).
 */

const REQUIRED_MSG = {
    summary:        'Summary is required.',
    currentState:   'Current State is required.',
    linkType:       'Link type is required.',
    linkedTicket:   'Linked ticket is required.',
    subtaskSummary: 'Subtask summary is required.',
    comment:        'Comment cannot be empty.'
};

export function validateTicketSummary(value) {
    const trimmed = (value || '').trim();
    if (!trimmed) return REQUIRED_MSG.summary;
    if (trimmed.length > 255) return 'Summary must be 255 characters or fewer.';
    return null;
}

export function validateTicketCurrentState(statusId) {
    if (!statusId) return REQUIRED_MSG.currentState;
    return null;
}

export function validateTicketLink({ linkType, toTicketId }) {
    if (!linkType)    return REQUIRED_MSG.linkType;
    if (!toTicketId)  return REQUIRED_MSG.linkedTicket;
    return null;
}

export function validateSubtaskSummary(value) {
    const trimmed = (value || '').trim();
    if (!trimmed) return REQUIRED_MSG.subtaskSummary;
    if (trimmed.length > 255) return 'Subtask summary must be 255 characters or fewer.';
    return null;
}

export function validateTicketComment(value) {
    const trimmed = (value || '').trim();
    if (!trimmed) return REQUIRED_MSG.comment;
    if (trimmed.length > 32768) return 'Comment must be 32768 characters or fewer.';
    return null;
}

// Returns an error string, or null when valid.

export function validateSummary(summary) {
    if (!summary) return 'Summary cannot be empty.';
    return null;
}

export function validateSubtask({ summary }) {
    if (!summary) return 'Summary is required.';
    return null;
}

export function validateEpicSelection(selectedEpicId) {
    if (!selectedEpicId) return 'Please select an epic.';
    return null;
}

export function validateNewEpic({ name, summary }) {
    if (!name)     return 'Epic Name is required.';
    if (!summary)  return 'Summary is required.';
    return null;
}

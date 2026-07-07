// Returns an error string, or null when valid.

const SUMMARY_MAX     = 255;
const EPIC_NAME_MAX   = 80;
const STORY_POINT_MAX = 99;

// Valid Story Point values: Fibonacci numbers within Number(2,0) range, 0 excluded.
const FIBONACCI_STORY_POINTS = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89];

export function validateStoryPoint(storyPoint) {
    const raw = (storyPoint == null ? '' : String(storyPoint)).trim();
    if (!raw) return 'Story Point is required.';
    const sp = Number(raw);
    if (!Number.isInteger(sp) || !FIBONACCI_STORY_POINTS.includes(sp)) {
        return 'Story Point must be a Fibonacci number: 1, 2, 3, 5, 8, 13, 21, 34, 55, 89.';
    }
    return null;
}

export function validateSummary(summary) {
    if (!summary || !summary.trim()) return 'Summary cannot be empty.';
    if (summary.trim().length > SUMMARY_MAX) return `Summary must be ${SUMMARY_MAX} characters or fewer.`;
    return null;
}

export function validateSubtask({ summary, storyPoint }) {
    if (!summary || !summary.trim()) return 'Summary is required.';
    if (summary.trim().length > SUMMARY_MAX) return `Summary must be ${SUMMARY_MAX} characters or fewer.`;
    if (storyPoint != null && storyPoint !== '') {
        const sp = Number(storyPoint);
        if (!Number.isInteger(sp) || sp < 0 || sp > STORY_POINT_MAX) {
            return `Story Point must be a whole number between 0 and ${STORY_POINT_MAX}.`;
        }
    }
    return null;
}

export function validateEpicSelection(selectedEpicId) {
    if (!selectedEpicId) return 'Please select an epic.';
    return null;
}

export function validateNewEpic({ name, summary, startDate, endDate }) {
    if (!name || !name.trim())       return 'Epic Name is required.';
    if (name.trim().length > EPIC_NAME_MAX) return `Epic Name must be ${EPIC_NAME_MAX} characters or fewer.`;
    if (!summary || !summary.trim()) return 'Summary is required.';
    if (summary.trim().length > SUMMARY_MAX) return `Summary must be ${SUMMARY_MAX} characters or fewer.`;
    if (startDate && endDate && new Date(endDate) <= new Date(startDate)) {
        return 'End Date must be after Start Date.';
    }
    return null;
}

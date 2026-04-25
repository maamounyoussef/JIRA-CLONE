export function emptySubtask() {
    return { summary: '', description: '', assigneeId: '', currentStateId: '', storyPoint: null };
}

export function enrichSubtask(sub, statusOptions, memberOptions) {
    const stateOpt     = statusOptions.find(o => o.value === sub.CurrentState__c);
    const memberOpt    = memberOptions.find(o => o.value === sub.Assignee__c);
    const assigneeName = memberOpt ? memberOpt.label : (sub.assigneeName || '');
    return {
        ...sub,
        stateName             : stateOpt ? stateOpt.label : '',
        assigneeName,
        isSelected            : false,
        isEditingSummary      : false,
        summaryDraft          : '',
        subtaskError          : null,
        subtaskComboboxOptions: buildSubtaskComboboxOptions(sub.Assignee__c, assigneeName, memberOptions),
    };
}

export function buildSubtaskComboboxOptions(assigneeId, assigneeName, allMembers) {
    if (assigneeId && assigneeName) {
        const hasCurrent = allMembers.some(o => o.value === assigneeId);
        if (!hasCurrent) return [{ label: assigneeName, value: assigneeId }, ...allMembers];
    }
    return allMembers;
}

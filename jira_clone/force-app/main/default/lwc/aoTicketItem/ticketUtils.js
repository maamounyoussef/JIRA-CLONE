export const PRIORITY_OPTIONS = [
    { label: '—',        value: ''         },
    { label: 'Low',      value: 'Low'      },
    { label: 'Medium',   value: 'Medium'   },
    { label: 'High',     value: 'High'     },
    { label: 'Critical', value: 'Critical' },
];

export function emptySubtask() {
    return { summary: '', description: '', assigneeId: '', currentStateId: '', storyPoint: null };
}

export function emptyEpic() {
    return { name: '', summary: '', description: '', startDate: '', endDate: '' };
}

export function enrichSubtask(sub, statusOptions, memberOptions) {
    const stateOpt  = statusOptions.find(o => o.value === sub.CurrentState__c);
    const memberOpt = memberOptions.find(o => o.value === sub.Assignee__c);
    return {
        ...sub,
        stateName    : stateOpt  ? stateOpt.label  : '',
        assigneeName : memberOpt ? memberOpt.label : '',
        isSelected   : false,
    };
}

export function formatMembersAsOptions(members) {
    return (members || []).map(m => ({ label: m.Name, value: m.Id }));
}

export function formatEpicsAsOptions(epics) {
    return (epics || []).map(e => ({ label: e.Name + ' - ' + e.Summary__c, value: e.Id }));
}

export function toISODateOrNull(dateStr) {
    return dateStr ? new Date(dateStr).toISOString() : null;
}

/** Returns true and calls setError(message) when res.success is falsy. */
export function failed(res, setError) {
    if (!res.success) { setError(res.message); return true; }
    return false;
}

/**
 * Ticket Utils
 * Utility functions for the ticket domain.
 */

export const PRIORITY_OPTIONS = [
    { label: '—',        value: ''         },
    { label: 'Low',      value: 'Low'      },
    { label: 'Medium',   value: 'Medium'   },
    { label: 'High',     value: 'High'     },
    { label: 'Critical', value: 'Critical' },
];

export function emptyTicket() {
    return { name: '', summary: '', description: '', storyPoint: null, ticketTypeId: '', currentStateId: '', priority: '' };
}

export function formatTicket(rawTicket, ticketTypeOptions, ticketTypeId) {
    return {
        ...rawTicket,
        epicName      : '',
        ticketTypeName: ticketTypeOptions.find(o => o.value === ticketTypeId)?.label || '',
        isSelected    : false,
    };
}

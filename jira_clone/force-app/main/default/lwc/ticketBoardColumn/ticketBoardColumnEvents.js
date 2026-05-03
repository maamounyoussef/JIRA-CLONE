/**
 * Ticket Board Column Events
 * Declares all CustomEvents dispatched by this component.
 * This is the single place to discover what this component communicates upward.
 */

/**
 * Fired when a ticket card drag begins.
 * Parent uses this to compute and highlight valid drop targets.
 */
export function dispatchTicketDragStart(component, ticketId, fromStatusId, ticketTypeId) {
    component.dispatchEvent(new CustomEvent('ticketdragstart', {
        detail: { ticketId, fromStatusId, ticketTypeId },
        bubbles:  true,
        composed: true
    }));
}

/**
 * Fired when a ticket is dropped on this column.
 * Parent validates the transition and calls Apex.
 */
export function dispatchTicketDrop(component, toStatusId) {
    component.dispatchEvent(new CustomEvent('ticketdrop', {
        detail: { toStatusId },
        bubbles:  true,
        composed: true
    }));
}

/**
 * Fired when a drag operation ends (drop or cancel).
 * Parent clears drag state and removes column highlights.
 */
export function dispatchTicketDragEnd(component, ticketId, newCurrentStatusId) {
    component.dispatchEvent(new CustomEvent('ticketdragend', {
        detail:   { ticketId, newCurrentStatusId },
        bubbles:  true,
        composed: true
    }));
}

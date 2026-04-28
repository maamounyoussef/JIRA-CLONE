import { LightningElement, api, track } from 'lwc';

function _empty() {
    return { name: '', summary: '', description: '', storyPoint: null, ticketTypeId: '', currentStateId: '', priority: '' };
}

export default class AoCreateTicketModal extends LightningElement {
    @api sprintId          = null;
    @api statusOptions     = [];
    @api ticketTypeOptions = [];
    @api priorityOptions   = [];

    @track ticket = _empty();
    error = null;

    @api
    get errors() { return this.error; }
    set errors(value) { this.error = value; }

    handleChange(event) {
        const field = event.target.dataset.field;
        const val   = event.detail ? event.detail.value : event.target.value;
        this.ticket = { ...this.ticket, [field]: val };
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSubmit() {
        if (!this.ticket.name?.trim()) { this.error = 'Name is required.';       return; }
        if (!this.ticket.ticketTypeId) { this.error = 'Ticket Type is required.'; return; }

        const { name, summary, description, storyPoint, ticketTypeId, currentStateId, priority } = this.ticket;
        this.dispatchEvent(new CustomEvent('ticketcreate', {
            detail: {
                name,
                summary      : summary      || null,
                description  : description  || null,
                storyPoint   : storyPoint   ? parseInt(storyPoint, 10) : null,
                ticketTypeId,
                currentStateId,
                priority     : priority     || null,
                sprintId     : this.sprintId || null,
                assignedToId : null,
                epicId       : null,
            }
        }));
    }
}

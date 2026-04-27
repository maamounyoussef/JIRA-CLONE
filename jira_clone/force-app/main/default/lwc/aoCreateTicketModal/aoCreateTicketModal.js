import { LightningElement, api, track } from 'lwc';
import createTicket from '@salesforce/apex/ManageBacklogController.createTicket';

function _empty() {
    return { name: '', summary: '', description: '', storyPoint: null, ticketTypeId: '', currentStateId: '', priority: '' };
}

function _format(raw, ticketTypeOptions, ticketTypeId) {
    return {
        ...raw,
        epicName      : '',
        ticketTypeName: (ticketTypeOptions || []).find(o => o.value === ticketTypeId)?.label || '',
        assigneeName  : '',
        isSelected    : false,
    };
}

export default class AoCreateTicketModal extends LightningElement {
    @api sprintId          = null;
    @api statusOptions     = [];
    @api ticketTypeOptions = [];
    @api priorityOptions   = [];

    @track ticket = _empty();
    error = null;

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
        createTicket({
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
        })
            .then(res => {
                if (!res.success) { this.error = res.message; return; }
                this.dispatchEvent(new CustomEvent('ticketcreated', {
                    detail: { ticket: _format(res.data, this.ticketTypeOptions, ticketTypeId), sprintId: this.sprintId }
                }));
            })
            .catch(err => { this.error = err.body?.message || 'Error creating ticket'; });
    }
}

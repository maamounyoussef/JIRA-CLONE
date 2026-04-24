import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import loadTicketsBySprint from '@salesforce/apex/ManageBacklogController.loadTicketsBySprint';

const PAGE_SIZE = 5;

export default class AoSprintContainer extends LightningElement {

    @api statusOptions     = [];
    @api memberOptions     = [];
    @api priorityOptions   = [];
    @api ticketTypeOptions = [];
    @api projectId         = '';
    @api epics             = [];

    @api
    set sprint(val) {
        this._sprint   = val;
        this._sprintId = val?.Id;
        this._endDate  = this._calcEndDate(val?.StartDate__c, val?.Duration__c);
    }
    get sprint() { return this._sprint; }

    @track isExpanded       = false;
    @track _tickets         = [];
    @track isLoadingTickets = true;
    @track _offset          = 0;
    @track _hasMore         = false;

    _sprint;
    _sprintId;
    _endDate     = '';
    _wiredResult = null;

    get chevronIcon() { return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
    get hasTickets()  { return this._tickets.length > 0; }
    get isFirstPage() { return this._offset === 0; }
    get isLastPage() { return this._tickets.length < PAGE_SIZE; }
    get currentPage() { return Math.floor(this._offset / PAGE_SIZE) + 1; }
    get offsetLabel() {
        const start = this._offset + 1;
        const end   = this._offset + this._tickets.length;
        return this._tickets.length === 0 ? 'No tickets' : `Showing ${start}–${end}`;
    }
    // ── Wire ─────────────────────────────────────────────────────────────────
    @wire(loadTicketsBySprint, { sprintId: '$_sprintId', offset: '$_offset', pageSize: PAGE_SIZE })
    wiredTickets(result) {
        this._wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.isLoadingTickets = false;
            if (data.success) {
                const tickets       = data.data || [];
                const epicMap       = Object.fromEntries((this.epics             || []).map(e => [e.Id,    e.Name]));
                const ticketTypeMap = Object.fromEntries((this.ticketTypeOptions || []).map(o => [o.value, o.label]));
                const memberMap     = Object.fromEntries((this.memberOptions     || []).map(m => [m.value, m.label]));
                this._tickets = tickets.map(t => ({
                    ...t,
                    epicName      : epicMap[t.Epic__c]              || '',
                    ticketTypeName: ticketTypeMap[t.Ticket_Type__c] || '',
                    assigneeName  : memberMap[t.AssignedTo__c]      || '',
                    isSelected    : false,
                }));
                this._hasMore = tickets.length === PAGE_SIZE;
            }
        } else if (error) {
            this.isLoadingTickets = false;
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────
    @api refreshTickets() {
        this.isLoadingTickets = true;
        this._offset = 0;
        return refreshApex(this._wiredResult);
    }

    @api clearSelection() {
        this._tickets = this._tickets.map(t => ({ ...t, isSelected: false }));
    }

    // ── Pagination ────────────────────────────────────────────────────────────
    handlePrevPage() {
        if (this._offset > 0) {
            this.isLoadingTickets = true;
            this._offset = this._offset - PAGE_SIZE;
        }
    }

    handleNextPage() {
        if (this._hasMore) {
            this.isLoadingTickets = true;
            this._offset = this._offset + PAGE_SIZE;
        }
    }

    // ── Expand / Collapse ─────────────────────────────────────────────────────
    handleToggle() {
        this.isExpanded = !this.isExpanded;
    }

    // ── Ticket events — intercept to keep local list in sync; events continue
    //    bubbling (composed:true) to manageBacklog automatically. ─────────────
    handleTicketDeleted(event) {
        const { ticketId } = event.detail;
        this._tickets = this._tickets.filter(t => t.Id !== ticketId);
    }

    handleTicketUpdated(event) {
        const { ticketId, field, value } = event.detail;
        this._tickets = this._tickets.map(t =>
            t.Id === ticketId ? { ...t, [field]: value } : t
        );
    }

    // ── Sprint action buttons → dispatch to parent ────────────────────────────
    _dispatch(name) {
        this.dispatchEvent(new CustomEvent(name, {
            bubbles : true,
            composed: true,
            detail  : { sprintId: this._sprintId },
        }));
    }

    handleStart()     { this._dispatch('sprintstart');    }
    handleComplete()  { this._dispatch('sprintcomplete'); }
    handleEdit()      { this._dispatch('sprintedit');     }
    handleDelete()    { this._dispatch('sprintdelete');   }
    handleAddTicket() { this._dispatch('sprintaddticket');}

    // ── Helpers ───────────────────────────────────────────────────────────────
    _calcEndDate(startDate, duration) {
        if (!startDate || !duration) return '';
        const d = new Date(startDate);
        d.setDate(d.getDate() + parseInt(duration, 10));
        return d.toISOString().split('T')[0];
    }
}

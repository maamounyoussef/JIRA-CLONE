import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import loadTicketsBySprint from '@salesforce/apex/ManageBacklogController.loadTicketsBySprint';

import { calcEndDate } from './sprintUtils';
import { enrichTickets } from './sprintTicketUtils';

const PAGE_SIZE = 5;

export default class AoSprintContainer extends LightningElement {

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║                          SPRINT SECTION                                  ║
    // ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @api
    set sprint(val) {
        this._sprint   = val;
        this._sprintId = val?.Id;
        this._endDate  = calcEndDate(val?.StartDate__c, val?.Duration__c);
    }
    get sprint() { return this._sprint; }

    @track isExpanded = false;

    _sprint;
    _sprintId;
    _endDate = '';

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleToggle()    { this.isExpanded = !this.isExpanded;          }
    handleStart()     { this._dispatch('sprintstart');               }
    handleComplete()  { this._dispatch('sprintcomplete');            }
    handleEdit()      { this._dispatch('sprintedit');                }
    handleDelete()    { this._dispatch('sprintdelete');              }
    handleAddTicket() { this._dispatch('sprintaddticket');           }

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get chevronIcon() { return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║                          TICKET SECTION                                  ║
    // ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @api statusOptions     = [];
    @api memberOptions     = [];
    @api priorityOptions   = [];
    @api ticketTypeOptions = [];
    @api projectId         = '';
    @api epics             = [];

    @track _tickets         = [];
    @track isLoadingTickets = true;
    @track _offset          = 0;
    @track _hasMore         = false;

    _wiredResult = null;

    // ─── WIRE ─────────────────────────────────────────────────────────────────
    @wire(loadTicketsBySprint, { sprintId: '$_sprintId', offset: '$_offset', pageSize: PAGE_SIZE })
    wiredTickets(result) {
        this._wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.isLoadingTickets = false;
            if (data.success) {
                const tickets  = data.data || [];
                this._tickets  = enrichTickets(tickets, this.epics, this.ticketTypeOptions, this.memberOptions);
                this._hasMore  = tickets.length === PAGE_SIZE;
            }
        } else if (error) {
            this.isLoadingTickets = false;
        }
    }

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    @api refreshTickets() {
        this.isLoadingTickets = true;
        this._offset = 0;
        return refreshApex(this._wiredResult);
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    @api clearSelection() {
        this._tickets = this._tickets.map(t => ({ ...t, isSelected: false }));
    }

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

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get hasTickets()  { return this._tickets.length > 0; }
    get isFirstPage() { return this._offset === 0; }
    get isLastPage()  { return this._tickets.length < PAGE_SIZE; }
    get currentPage() { return Math.floor(this._offset / PAGE_SIZE) + 1; }
    get offsetLabel() {
        const start = this._offset + 1;
        const end   = this._offset + this._tickets.length;
        return this._tickets.length === 0 ? 'No tickets' : `Showing ${start}–${end}`;
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║                         PRIVATE HELPERS                                  ║
    // ╚══════════════════════════════════════════════════════════════════════════╝

    _dispatch(name) {
        this.dispatchEvent(new CustomEvent(name, {
            bubbles : true,
            composed: true,
            detail  : { sprintId: this._sprintId },
        }));
    }
}

import { LightningElement, api, track } from 'lwc';

export default class TicketView extends LightningElement {

    // ── @api : ticket ────────────────────────────────────────────────────────
    // Shape:
    //   { Id, summary, description, priority, assigneeName,
    //     currentStatusId, currentStatusName,
    //     linkedTo: [{ Id, linkType, ticketName, ticketSummary,
    //                  currentStatusId, priority, assigneeName }] }
    _ticket = {};

    @api
    get ticket() { return this._ticket; }
    set ticket(value) {
        this._ticket       = value || {};
        this._summaryDraft = this._ticket.summary || '';
        this._descDraft    = this._ticket.description || '';
    }

    @api statusOptions          = [];   // [{ label, value }]
    @api ticketLinkedToType     = [];   // [{ label, value }]
    @api ticketOptions          = [];   // [{ label, value }] (Name → value, Id → key, etc.)

    // ── Local UI state ───────────────────────────────────────────────────────
    @track _summaryEdit         = false;
    @track _summaryDraft        = '';

    @track _descEdit            = false;
    @track _descDraft           = '';

    @track _linkedToExpanded    = false;
    @track _showAddLinkForm     = false;
    @track _selectedLinkType    = '';
    @track _selectedLinkTicket  = '';

    // ── Summary getters ──────────────────────────────────────────────────────
    get summaryViewMode()  { return !this._summaryEdit; }
    get summaryEditMode()  { return this._summaryEdit; }
    get summaryText()      { return this._ticket.summary || ''; }
    get summaryDraft()     { return this._summaryDraft; }

    // ── Description getters ──────────────────────────────────────────────────
    get descriptionViewMode() { return !this._descEdit; }
    get descriptionEditMode() { return this._descEdit; }
    get descriptionText()     { return this._ticket.description || ''; }
    get descriptionDraft()    { return this._descDraft; }
    get hasDescription()      { return !!(this._ticket.description && this._ticket.description.trim()); }

    // ── Status / priority / assignee getters ─────────────────────────────────
    get currentStatusId()     { return this._ticket.currentStatusId || ''; }
    get priorityText()        { return this._ticket.priority || ''; }
    get assigneeName()        { return this._ticket.assigneeName || ''; }

    // ── Linked-to getters ────────────────────────────────────────────────────
    get linkedToExpanded()    { return this._linkedToExpanded; }
    get linkedToChevron()     { return this._linkedToExpanded ? '▼' : '▶'; }
    get linkedToExpandTitle() { return this._linkedToExpanded ? 'Collapse' : 'Expand'; }

    get linkedItems()         { return Array.isArray(this._ticket.linkedTo) ? this._ticket.linkedTo : []; }
    get hasLinkedItems()      { return this.linkedItems.length > 0; }

    /** Group linked items by linkType to render the sub-label headings. */
    get linkedGroups() {
        const groups = {};
        for (const item of this.linkedItems) {
            const key = item.linkType || 'Other';
            if (!groups[key]) groups[key] = [];
            groups[key].push(item);
        }
        return Object.keys(groups).map(type => ({
            key:   type,
            label: (type || '').toLowerCase(),
            items: groups[type]
        }));
    }

    get showAddLinkForm()     { return this._showAddLinkForm; }
    get isLinkBtnDisabled()   { return !this._selectedLinkType || !this._selectedLinkTicket; }

    // ─────────────────────────────────────────────────────────────────────────
    //  SUMMARY HANDLERS
    // ─────────────────────────────────────────────────────────────────────────
    handleSummaryEditOpen() {
        this._summaryDraft = this._ticket.summary || '';
        this._summaryEdit  = true;
    }

    handleSummaryDraftChange(event) {
        this._summaryDraft = event.detail.value;
    }

    handleTicketSummaryUpdate() {
        // TODO: dispatchEvent('ticketsummaryupdate')
        console.log('dispatchEvent → ticketsummaryupdate', {
            ticketId: this._ticket.Id,
            summary:  this._summaryDraft
        });
        this._ticket = { ...this._ticket, summary: this._summaryDraft };
        this._summaryEdit = false;
    }

    handleSummaryEditCancel() {
        this._summaryDraft = this._ticket.summary || '';
        this._summaryEdit  = false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  DESCRIPTION HANDLERS
    // ─────────────────────────────────────────────────────────────────────────
    handleDescriptionEditOpen() {
        this._descDraft = this._ticket.description || '';
        this._descEdit  = true;
    }

    handleDescriptionDraftChange(event) {
        this._descDraft = event.target.value;
    }

    handleTicketDescriptionUpdate() {
        // TODO: dispatchEvent('ticketdescriptionupdate')
        console.log('dispatchEvent → ticketdescriptionupdate', {
            ticketId:    this._ticket.Id,
            description: this._descDraft
        });
        this._ticket = { ...this._ticket, description: this._descDraft };
        this._descEdit = false;
    }

    handleDescriptionEditCancel() {
        this._descDraft = this._ticket.description || '';
        this._descEdit  = false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  CURRENT STATE HANDLER
    // ─────────────────────────────────────────────────────────────────────────
    handleTicketCurrentStateUpdate(event) {
        const newStatusId = event.detail.value;
        // TODO: dispatchEvent('ticketcurrentstateupdate')
        console.log('dispatchEvent → ticketcurrentstateupdate', {
            ticketId:        this._ticket.Id,
            currentStatusId: newStatusId
        });
        this._ticket = { ...this._ticket, currentStatusId: newStatusId };
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  LINKED-TO HANDLERS
    // ─────────────────────────────────────────────────────────────────────────
    handleLinkedToExpandToggle() {
        this._linkedToExpanded = !this._linkedToExpanded;
        if (!this._linkedToExpanded) {
            this.handleLinkedToAddCancel();
        }
    }

    handleLinkedToAddOpen() {
        if (!this._linkedToExpanded) this._linkedToExpanded = true;
        this._showAddLinkForm    = true;
        this._selectedLinkType   = '';
        this._selectedLinkTicket = '';
    }

    handleLinkedToTypeSelect(event) {
        this._selectedLinkType = event.detail.value;
    }

    handleLinkedToTicketSelect(event) {
        this._selectedLinkTicket = event.detail.value;
    }

    handleTicketLinkedToCreate() {
        if (this.isLinkBtnDisabled) return;
        // TODO: dispatchEvent('ticketlinkedtocreate')
        console.log('dispatchEvent → ticketlinkedtocreate', {
            fromTicketId: this._ticket.Id,
            toTicketId:   this._selectedLinkTicket,
            linkType:     this._selectedLinkType
        });
        this.handleLinkedToAddCancel();
    }

    handleLinkedToAddCancel() {
        this._showAddLinkForm    = false;
        this._selectedLinkType   = '';
        this._selectedLinkTicket = '';
    }

    handleTicketLinkedToStatusUpdate(event) {
        const linkedTicketId = event.currentTarget.dataset.id;
        const newStatusId    = event.detail.value;
        // TODO: dispatchEvent('ticketlinkedtostatusupdate')
        console.log('dispatchEvent → ticketlinkedtostatusupdate', {
            linkedTicketId,
            currentStatusId: newStatusId
        });
    }
}

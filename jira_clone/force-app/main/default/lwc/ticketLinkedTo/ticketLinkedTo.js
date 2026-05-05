import { LightningElement, api, track } from 'lwc';



export default class TicketLinkedTo extends LightningElement {

    @api ticketId= '';
    @api ticketOptions;
    @api linkTypeOptions;

    @track _isExpanded       = false;
    @track _items            = [];
    @track _listKey          = '';
    @track _showAddForm      = false;
    @track _selectedLinkType = '';
    @track _selectedTicketId = '';

    get ticketOptionNames() {
        return this.ticketOptions.map(option => ({
            label: option.Name,
            value: option.Id
        }));
    }

    get linkTypeOptionNames() {
        return Array.isArray(this.linkTypeOptions) ? this.linkTypeOptions : [];
    }

    // ─── @api : listKey ──────────────────────────────────────────────────────
    @api
    get listKey() { return this._listKey; }
    set listKey(value) {
        if (value && value !== this._listKey) {
            this._listKey   = value;
        }
    }

    // ─── @api : linkedItems ──────────────────────────────────────────────────
    @api
    get linkedItems() { return this._items; }
    set linkedItems(value) {
        this._items     = Array.isArray(value) ? value : [];
    }

    // ─── GETTERS ─────────────────────────────────────────────────────────────
    get isExpanded()    { return this._isExpanded; }
    get hasItems()      { return this._items.length > 0; }
    get expandTitle()   { return this._isExpanded ? 'Collapse' : 'Expand'; }
    get showAddForm()   { return this._showAddForm; }
    get showEmptyState(){ return !this.hasItems && !this._showAddForm; }
    get isLinkDisabled(){ return !this._selectedLinkType || !this._selectedTicketId; }


    connectedCallback() {
    }

    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────
    handleExpandCollapse() {
        this._isExpanded = !this._isExpanded;
        if (this._isExpanded) {
            this.dispatchEvent(new CustomEvent('expandlinkedto', {
                detail:   { ticketId: this.ticketId },
                bubbles:  true,
                composed: true
            }));
        } else {
            this._showAddForm = false;
        }
    }

    handleAddLink() {
        if (!this._isExpanded) {
            this._isExpanded = true;
            this.dispatchEvent(new CustomEvent('expandlinkedto', {
                detail:   { ticketId: this.ticketId },
                bubbles:  true,
                composed: true
            }));
        }
        this._showAddForm       = true;
        this._selectedLinkType  = '';
        this._selectedTicketId  = '';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closelinkedto', {
            bubbles:  true,
            composed: true
        }));
    }

    handleOverlayClick() {
        this.handleClose();
    }

    // ─── FORM HANDLERS ───────────────────────────────────────────────────────
    handleLinkTypeChange(event) {
        this._selectedLinkType = event.target.value;
    }

    handleTicketChange(event) {
        this._selectedTicketId = event.detail.value;
    }

    handleLinkSubmit() {
        if (!this._selectedLinkType || !this._selectedTicketId) return;
        this.dispatchEvent(new CustomEvent('createticketlink', {
            bubbles:  true,
            composed: true,
            detail: {
                fromTicketId: this.ticketId,
                toTicketId:   this._selectedTicketId,
                linkType:     this._selectedLinkType
            }
        }));
        this._showAddForm      = false;
        this._selectedLinkType = '';
        this._selectedTicketId = '';
    }

    handleCreateLinkedItem() {
        if (!this._selectedLinkType || !this._selectedTicketId) return;
        this.dispatchEvent(new CustomEvent('createticketlink', {
            bubbles:  true,
            composed: true,
            detail: {
                fromTicketId: this.ticketId,
                toTicketId:   this._selectedTicketId,
                linkType:     this._selectedLinkType
            }
        }));
        this._showAddForm      = false;
        this._selectedLinkType = '';
        this._selectedTicketId = '';
    }

    handleCancelAddLink() {
        this._showAddForm      = false;
        this._selectedLinkType = '';
        this._selectedTicketId = '';
    }
}

import { LightningElement, api, track } from 'lwc';



export default class TicketLinkedTo extends LightningElement {

    @api ticketId= '';
    @api ticketOptions;
    @api linkTypeOptions;

    @track _isExpanded       = false;
    @track _isLoading        = false;
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
            this._isLoading = false;
        }
    }

    // ─── @api : linkedItems ──────────────────────────────────────────────────
    @api
    get linkedItems() { return this._items; }
    set linkedItems(value) {
        this._items     = Array.isArray(value) ? value : [];
        this._isLoading = false;
    }

    // ─── GETTERS ─────────────────────────────────────────────────────────────
    get isExpanded()    { return this._isExpanded; }
    get isLoading()     { return this._isLoading; }
    get hasItems()      { return this._items.length > 0; }
    get expandTitle()   { return this._isExpanded ? 'Collapse' : 'Expand'; }
    get showAddForm()   { return this._showAddForm; }
    get showEmptyState(){ return !this.hasItems && !this._showAddForm; }
    get isLinkDisabled(){ return !this._selectedLinkType || !this._selectedTicketId; }



    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────
    handleExpandCollapse() {
        this._isExpanded = !this._isExpanded;
        if (this._isExpanded) {
            this._isLoading = true;
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
            this._isLoading  = true;
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
        console.log('[ticketLinkedTo] link submit', {
            ticketId:        this.ticketId,
            linkType:        this._selectedLinkType,
            linkedTicketId:  this._selectedTicketId
        });
        console.log(this.ticketId);
        console.log(this._selectedLinkType);
        console.log(this._selectedTicketId);
    }

    handleCreateLinkedItem() {
        console.log('[ticketLinkedTo] create linked work item', {
            ticketId: this.ticketId,
            linkType: this._selectedLinkType
        });
    }

    handleCancelAddLink() {
        console.log('[ticketLinkedTo] cancel add link');
        this._showAddForm      = false;
        this._selectedLinkType = '';
        this._selectedTicketId = '';
    }
}

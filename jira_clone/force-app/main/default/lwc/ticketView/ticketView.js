import { LightningElement, api, track } from 'lwc';

export default class TicketView extends LightningElement {

    // ─── @api INPUTS FROM PARENT ──────────────────────────────────────────────
    @track _ticket = {
        Id:              '',
        summary:         '',
        description:     '',
        currentStatusId: '',
        linkedItems:     []
    };

    @api
    get ticket() { return this._ticket; }
    set ticket(value) {
        if (!value) return;
        // Accept either internal shape (summary / currentStatusId / description)
        // or Salesforce field names (Summary__c / CurrentState__c / Description__c).
        // linkedItems is enriched by the parent after `expandlinkedto` fires.
        this._ticket = {
            Id:              value.Id              || '',
            summary:         value.summary         || value.Summary__c        || '',
            description:     value.description     || value.Description__c    || '',
            currentStatusId: value.currentStatusId || value.CurrentState__c   || '',
            linkedItems:     Array.isArray(value.linkedItems) ? value.linkedItems : []
        };
    }

    @api statusOptions = [
        { label: 'To Do',       value: 'todo' },
        { label: 'In Progress', value: 'in-progress' },
        { label: 'In Review',   value: 'in-review' },
        { label: 'Done',        value: 'done' }
    ];

    @api linkTypeOptions = [];

    // ─── EDIT-MODE FLAGS ──────────────────────────────────────────────────────
    isSummaryEditing      = false;
    summaryDraft          = '';

    isDescriptionEditing  = false;
    descriptionDraft      = '';

    isLinkedExpanded      = false;
    showAddLinkForm       = false;
    newLinkType           = '';
    newLinkTargetId       = '';

    // TODO: replace with @api linkTargetOptions (tickets + epics)
    linkTargetOptions = [
        { label: 'TCK-201 — Profile page',     value: 'TCK-201' },
        { label: 'TCK-202 — Password reset',   value: 'TCK-202' },
        { label: 'EPIC-10 — Auth platform',    value: 'EPIC-10' },
        { label: 'EPIC-11 — User management',  value: 'EPIC-11' }
    ];

    // ─── DERIVED GETTERS ──────────────────────────────────────────────────────
    get hasDescription() {
        return !!this._ticket.description && this._ticket.description.trim() !== '';
    }

    get linkedChevronIcon() {
        return this.isLinkedExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get linkedToggleTitle() {
        return this.isLinkedExpanded ? 'Collapse' : 'Expand';
    }

    get hasLinkedItems() {
        return Array.isArray(this._ticket.linkedItems) && this._ticket.linkedItems.length > 0;
    }

    get computedLinkedItems() {
        return (this._ticket.linkedItems || []).map(item => ({ ...item, _key: item.linkId }));
    }

    get isLinkButtonDisabled() {
        return !this.newLinkType || !this.newLinkTargetId;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SUMMARY  — inline edit
    // ═══════════════════════════════════════════════════════════════════════════
    handleSummaryEditOpen() {
        this.summaryDraft     = this._ticket.summary;
        this.isSummaryEditing = true;
    }

    handleSummaryChange(event) {
        this.summaryDraft = event.detail.value;
    }

    handleSummaryConfirm() {
        const next = (this.summaryDraft || '').trim();
        if (!next) {
            this.isSummaryEditing = false;
            return;
        }
        // Spread root because we are replacing one primitive field
        this._ticket = { ...this._ticket, summary: next };
        this.isSummaryEditing = false;

        // TODO: dispatchEvent('summaryupdate', { ticketId, summary: next })
        console.log('[ticketView] summary update', { ticketId: this._ticket.Id, summary: next });
    }

    handleSummaryCancel() {
        this.isSummaryEditing = false;
        this.summaryDraft     = '';
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STATUS
    // ═══════════════════════════════════════════════════════════════════════════
    handleStatusChange(event) {
        const next = event.detail.value;
        this._ticket = { ...this._ticket, currentStatusId: next };

        // TODO: dispatchEvent('statuschange', { ticketId, statusId: next })
        console.log('[ticketView] status change', { ticketId: this._ticket.Id, statusId: next });
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DESCRIPTION — inline edit (rich text)
    // ═══════════════════════════════════════════════════════════════════════════
    handleDescriptionEditOpen() {
        this.descriptionDraft     = this._ticket.description || '';
        this.isDescriptionEditing = true;
    }

    handleDescriptionChange(event) {
        this.descriptionDraft = event.target.value;
    }

    handleDescriptionSave() {
        this._ticket = { ...this._ticket, description: this.descriptionDraft || '' };
        this.isDescriptionEditing = false;

        // TODO: dispatchEvent('descriptionupdate', { ticketId, description })
        console.log('[ticketView] description update', { ticketId: this._ticket.Id, description: this._ticket.description });
    }

    handleDescriptionCancel() {
        this.isDescriptionEditing = false;
        this.descriptionDraft     = '';
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LINKED WORK ITEMS
    // ═══════════════════════════════════════════════════════════════════════════
    handleLinkedToggle() {
        this.isLinkedExpanded = !this.isLinkedExpanded;
        if (this.isLinkedExpanded) {
            // tell the parent to fetch & enrich linkedItems for this ticket
            this.dispatchEvent(new CustomEvent('expandlinkedto', {
                bubbles:  true,
                composed: true,
                detail:   { ticketId: this._ticket.Id }
            }));
        } else {
            this.showAddLinkForm = false;
        }
    }

    handleLinkedAddOpen() {
        this.showAddLinkForm = true;
        this.newLinkType     = '';
        this.newLinkTargetId = '';
    }

    handleLinkCancel() {
        this.showAddLinkForm = false;
        this.newLinkType     = '';
        this.newLinkTargetId = '';
    }

    handleLinkTypeChange(event) {
        this.newLinkType = event.detail.value;
    }

    handleLinkTargetChange(event) {
        this.newLinkTargetId = event.detail.value;
    }

    handleLinkConfirm() {
        if (this.isLinkButtonDisabled) return;
        const payload = {
            fromTicketId: this._ticket.Id,
            linkType:     this.newLinkType,
            toItemId:     this.newLinkTargetId
        };

        // TODO: dispatchEvent('createticketlink', { ...payload })
        console.log('[ticketView] create linked item', payload);

        this.showAddLinkForm = false;
        this.newLinkType     = '';
        this.newLinkTargetId = '';
    }

    handleLinkedItemCheckboxChange(event) {
        const linkId  = event.target.dataset.linkId;
        const checked = event.detail.checked;
        // Spread root → linkedItems → matched row (per handle-state.md)
        this._ticket = {
            ...this._ticket,
            linkedItems: this._ticket.linkedItems.map(item =>
                item.linkId === linkId ? { ...item, isSelected: checked } : item
            )
        };
    }

    handleLinkedItemStatusChange(event) {
        const linkId = event.target.dataset.linkId;
        const next   = event.detail.value;
        this._ticket = {
            ...this._ticket,
            linkedItems: this._ticket.linkedItems.map(item =>
                item.linkId === linkId ? { ...item, currentStatusId: next } : item
            )
        };

        // TODO: dispatchEvent('linkedstatuschange', { linkId, statusId: next })
        console.log('[ticketView] linked item status change', { linkId, statusId: next });
    }
}

import { LightningElement, track } from 'lwc';

export default class TicketView extends LightningElement {

    // ─── TICKET STATE (single complex object — mutate per handle-state.md) ────
    @track ticket = {
        Id: 'TCK-001',
        summary: 'Implement user authentication flow',
        description: '',
        currentStatusId: 'in-progress',
        linkedItems: [
            {
                linkId:          'L1',
                Id:              'TCK-101',
                ticketName:      'TCK-101',
                summary:         'Set up login page UI',
                currentStatusId: 'todo',
                priority:        'High',
                assigneeName:    'Sam',
                isSelected:      false
            },
            {
                linkId:          'L2',
                Id:              'TCK-102',
                ticketName:      'TCK-102',
                summary:         'Wire up OAuth callback',
                currentStatusId: 'in-progress',
                priority:        'Medium',
                assigneeName:    'Alex',
                isSelected:      false
            }
        ]
    };

    // ─── EDIT-MODE FLAGS ──────────────────────────────────────────────────────
    isSummaryEditing      = false;
    summaryDraft          = '';

    isDescriptionEditing  = false;
    descriptionDraft      = '';

    isLinkedExpanded      = false;
    showAddLinkForm       = false;
    newLinkType           = '';
    newLinkTargetId       = '';

    // ─── STATIC OPTIONS (TODO: replace with @api inputs from parent) ─────────
    statusOptions = [
        { label: 'To Do',       value: 'todo' },
        { label: 'In Progress', value: 'in-progress' },
        { label: 'In Review',   value: 'in-review' },
        { label: 'Done',        value: 'done' }
    ];

    // TODO: replace with @api linkTypeOptions
    linkTypeOptions = [
        { label: 'blocks',      value: 'blocks' },
        { label: 'is blocked by', value: 'is-blocked-by' },
        { label: 'relates to',  value: 'relates-to' },
        { label: 'duplicates',  value: 'duplicates' }
    ];

    // TODO: replace with @api linkTargetOptions (tickets + epics)
    linkTargetOptions = [
        { label: 'TCK-201 — Profile page',     value: 'TCK-201' },
        { label: 'TCK-202 — Password reset',   value: 'TCK-202' },
        { label: 'EPIC-10 — Auth platform',    value: 'EPIC-10' },
        { label: 'EPIC-11 — User management',  value: 'EPIC-11' }
    ];

    // ─── DERIVED GETTERS ──────────────────────────────────────────────────────
    get hasDescription() {
        return !!this.ticket.description && this.ticket.description.trim() !== '';
    }

    get linkedChevronIcon() {
        return this.isLinkedExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get linkedToggleTitle() {
        return this.isLinkedExpanded ? 'Collapse' : 'Expand';
    }

    get hasLinkedItems() {
        return Array.isArray(this.ticket.linkedItems) && this.ticket.linkedItems.length > 0;
    }

    get computedLinkedItems() {
        return this.ticket.linkedItems.map(item => ({ ...item, _key: item.linkId }));
    }

    get isLinkButtonDisabled() {
        return !this.newLinkType || !this.newLinkTargetId;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SUMMARY  — inline edit
    // ═══════════════════════════════════════════════════════════════════════════
    handleSummaryEditOpen() {
        this.summaryDraft     = this.ticket.summary;
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
        this.ticket = { ...this.ticket, summary: next };
        this.isSummaryEditing = false;

        // TODO: dispatchEvent('summaryupdate', { ticketId, summary: next })
        console.log('[ticketView] summary update', { ticketId: this.ticket.Id, summary: next });
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
        this.ticket = { ...this.ticket, currentStatusId: next };

        // TODO: dispatchEvent('statuschange', { ticketId, statusId: next })
        console.log('[ticketView] status change', { ticketId: this.ticket.Id, statusId: next });
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DESCRIPTION — inline edit (rich text)
    // ═══════════════════════════════════════════════════════════════════════════
    handleDescriptionEditOpen() {
        this.descriptionDraft     = this.ticket.description || '';
        this.isDescriptionEditing = true;
    }

    handleDescriptionChange(event) {
        this.descriptionDraft = event.target.value;
    }

    handleDescriptionSave() {
        this.ticket = { ...this.ticket, description: this.descriptionDraft || '' };
        this.isDescriptionEditing = false;

        // TODO: dispatchEvent('descriptionupdate', { ticketId, description })
        console.log('[ticketView] description update', { ticketId: this.ticket.Id, description: this.ticket.description });
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
        if (!this.isLinkedExpanded) {
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
            fromTicketId: this.ticket.Id,
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
        const linkId = event.target.dataset.linkId;
        const checked = event.detail.checked;
        // Spread root → linkedItems → matched row (primitive isSelected just assigned)
        this.ticket = {
            ...this.ticket,
            linkedItems: this.ticket.linkedItems.map(item =>
                item.linkId === linkId ? { ...item, isSelected: checked } : item
            )
        };
    }

    handleLinkedItemStatusChange(event) {
        const linkId = event.target.dataset.linkId;
        const next   = event.detail.value;
        this.ticket = {
            ...this.ticket,
            linkedItems: this.ticket.linkedItems.map(item =>
                item.linkId === linkId ? { ...item, currentStatusId: next } : item
            )
        };

        // TODO: dispatchEvent('linkedstatuschange', { linkId, statusId: next })
        console.log('[ticketView] linked item status change', { linkId, statusId: next });
    }
}

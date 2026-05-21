import { LightningElement, api, track } from 'lwc';
import { validateSummary, validateSubtask, validateEpicSelection, validateNewEpic } from './ticketValidator';
import { emptyEpic, formatEpicsAsOptions, toISODateOrNull }                         from './ticketUtils';
import { emptySubtask, enrichSubtask }                                              from './subtaskUtils';

export default class AoTicketItem extends LightningElement {

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                            TICKET SECTION                               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ──────────────────────────────────────────────────

    @track _currentStateId = '';

    _ticket = {};
    @api
    get ticket()        { return this._ticket; }
    set ticket(value)   {
        this._ticket         = value || {};
        this._currentStateId = value?.CurrentState__c ?? '';
        // Subtasks are owned by the parent; once they arrive on the ticket the
        // loading spinner can be dropped.
        if (Array.isArray(this._ticket.subtasks)) this.isLoadingSubtasks = false;
    }

    @api variant         = 'row';
    @api statusOptions   = [];
    @api priorityOptions = [];
    @api projectId       = '';
    @api epics           = [];

    _memberOptions = [];

    @api
    get memberOptions() { return this._memberOptions; }
    set memberOptions(value) {
        // The `subtasks` getter re-derives combobox options from the current
        // member list on every read, so nothing to recompute here.
        this._memberOptions = value || [];
    }

    @track isDraggable       = false;

    @track isEditingSummary  = false;
    @track summaryDraft      = '';

    @track isEditingPriority = false;
    @track priorityDraft     = '';

    @track errorMessage = null;
    @track modalError   = null;

    @track showConfirmDialog = false;
    confirmMessage           = '';
    _pendingAction           = null;

    @track showEpicModal       = false;
    @track showCreateEpicModal = false;
    @track selectedEpicId      = '';

    newEpic = emptyEpic();

    // ─── EVENT DISPATCHERS ───────────────────────────────────────────────────

    handleSaveSummary() {
        const summary = (this.summaryDraft || '').trim();
        const error   = validateSummary(summary);
        if (error) { this.errorMessage = error; return; }
        this.isEditingSummary = false;
        this._dispatch('ticketsummaryupdate', { ticketId: this.ticket.Id, summary });
    }

    handleSavePriority() {
        this.isEditingPriority = false;
        this._dispatch('ticketpriorityupdate', { ticketId: this.ticket.Id, priority: this.priorityDraft });
    }

    handleStateChange(event) {
        this._dispatch('ticketstatechange', { ticketId: this.ticket.Id, fromStatusId: this.ticket.CurrentState__c, toStatusId: event.detail.value });
    }

    handleAssigneeChange(event) {
        this._dispatch('ticketassigneechange', { ticketId: this.ticket.Id, memberId: event.detail.value });
    }

    handleDeleteClick() {
        this._confirm('Are you sure you want to delete this ticket?', () => {
            this._dispatch('ticketdelete', { ticketId: this.ticket.Id });
        });
    }

    handleAssignEpic() {
        const error = validateEpicSelection(this.selectedEpicId);
        if (error) { this.modalError = error; return; }
        this._dispatch('ticketepicupdate', { ticketId: this.ticket.Id, epicId: this.selectedEpicId });
        this.showEpicModal = false;
        this.modalError    = null;
    }

    handleCreateEpicSubmit() {
        const error = validateNewEpic(this.newEpic);
        if (error) { this.modalError = error; return; }
        const { name, summary, description, startDate, endDate } = this.newEpic;
        this._dispatch('epiccreateforticket', {
            ticketId   : this.ticket.Id,
            name,
            summary,
            description: description || null,
            startDate  : toISODateOrNull(startDate),
            endDate    : toISODateOrNull(endDate),
        });
        this.showCreateEpicModal = false;
        this.modalError          = null;
    }

    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────

    handleToggleSubtasks() {
        this.isExpanded = !this.isExpanded;
        // The child no longer fetches subtasks itself — ask the parent to load
        // them the first time this ticket is expanded.
        if (this.isExpanded && !Array.isArray(this._ticket.subtasks)) {
            this.isLoadingSubtasks = true;
            this._dispatch('subtasksexpand', { ticketId: this.ticket.Id });
        }
    }

    handleSelect(event) {
        this._dispatch('ticketselect', { ticketId: this.ticket.Id, selected: event.detail.checked });
    }

    // -- Summary --
    handleStartEditSummary() {
        this.summaryDraft     = this.ticket.Summary__c;
        this.isEditingSummary = true;
    }

    handleSummaryDraftChange(event) { this.summaryDraft = event.detail.value; }

    handleCancelEditSummary() {
        this.isEditingSummary = false;
        this.errorMessage     = null;
    }

    // -- Priority --
    handleStartEditPriority() {
        this.priorityDraft     = this.ticket.Priority__c || '';
        this.isEditingPriority = true;
    }

    handlePriorityDraftChange(event) { this.priorityDraft = event.detail.value; }

    handleCancelEditPriority() {
        this.isEditingPriority = false;
        this.errorMessage      = null;
    }

    handleBlurPriority(event) {
        if (!event.currentTarget.contains(event.relatedTarget)) {
            this.isEditingPriority = false;
            this.errorMessage      = null;
        }
    }

    handleRowMouseDown(event) {
        if (event.button === 0) this.isDraggable = true;
    }

    handleRowMouseUp() {
        this.isDraggable = false;
    }

    handleRowClick() {
        console.log('Ticket row clicked:', this.ticket.Id, this.ticket.Name);
    }

    handleOpenTicketView(event) {
        event.stopPropagation();
        this._dispatch('ticketviewopen', { ticketId: this.ticket.Id, ticket: this.ticket });
    }

    handleDragStart(event) {
        event.dataTransfer.setData('text/plain', JSON.stringify({
            ticketId    : this.ticket.Id,
            sourceSprint: this.ticket.Sprint__c || null,
        }));
        event.dataTransfer.effectAllowed = 'move';
    }

    // -- Confirm dialog --
    handleConfirm() {
        this.showConfirmDialog = false;
        if (this._pendingAction) { this._pendingAction(); this._pendingAction = null; }
    }

    handleCancelConfirm() {
        this.showConfirmDialog = false;
        this._pendingAction    = null;
    }

    clearError() { this.errorMessage = null; }

    // -- Epic modal --
    handleOpenEpicModal() {
        this.modalError     = null;
        this.selectedEpicId = this.ticket.Epic__c || '';
        this.showEpicModal  = true;
    }

    handleCloseEpicModal() {
        this.showEpicModal = false;
        this.modalError    = null;
    }

    handleEpicSelectionChange(event) { this.selectedEpicId = event.detail.value; }

    handleOpenCreateEpicFromEmpty() {
        this.showEpicModal       = false;
        this.newEpic             = emptyEpic();
        this.modalError          = null;
        this.showCreateEpicModal = true;
    }

    handleOpenCreateEpicFromSelection() {
        this.showEpicModal       = false;
        this.newEpic             = emptyEpic();
        this.modalError          = null;
        this.showCreateEpicModal = true;
    }

    handleCloseCreateEpicModal() {
        this.showCreateEpicModal = false;
        this.modalError          = null;
        this.showEpicModal       = true;
    }

    handleNewEpicChange(event) {
        const field = event.target.dataset.field;
        const val   = event.detail ? event.detail.value : event.target.value;
        this.newEpic = { ...this.newEpic, [field]: val };
    }

    // ─── GETTERS ─────────────────────────────────────────────────────────────

    get isRowVariant()            { return this.variant === 'row'; }
    get isFullTicketCardVariant() { return this.variant === 'full-ticket-card'; }
    get isTrackingCardVariant()   { return this.variant === 'tracking-card'; }
    get cardWrapperClass()        { return 'ticket-card-wrapper' + (this.ticket.isEndStatus ? ' end-status' : ''); }
    get currentStateValue()    { return this._currentStateId || this._ticket?.CurrentState__c || ''; }
    get expandIcon()           { return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
    get hasSubtasks()          { return this.subtasks.length > 0; }
    get spLabel()              { return this.ticket.StoryPoint__c != null ? this.ticket.StoryPoint__c : '—'; }
    get priorityLabel()        { return this.ticket.Priority__c || '—'; }
    get hasEpics()             { return (this.epics || []).length > 0; }
    get epicOptions()          { return formatEpicsAsOptions(this.epics || []); }
    get epicModalTitle()       { return this.hasEpics ? 'Update Epic Parent' : 'No Epics Available'; }
    get isEpicAssignDisabled() { return !this.selectedEpicId; }
    get hasTicketType()        { return !!this.ticket.ticketTypeName; }

    get comboboxAssigneeOptions() {
        if (this.ticket.AssignedTo__c && this.ticket.assigneeName) {
            const current    = { label: this.ticket.assigneeName, value: this.ticket.AssignedTo__c };
            const hasCurrent = this._memberOptions.some(o => o.value === this.ticket.AssignedTo__c);
            if (!hasCurrent) return [current, ...this._memberOptions];
        }
        return this._memberOptions;
    }

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           SUBTASK SECTION                               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ──────────────────────────────────────────────────

    @track isExpanded             = false;
    @track isLoadingSubtasks      = false;
    @track selectedSubtaskIds     = [];
    @track showCreateSubtaskModal = false;

    // Inline-edit is single-row at a time, so a few scalars are enough — every
    // per-row flag is derived from these in the `subtasks` getter below.
    @track _editingSubtaskId   = null;
    @track _subtaskSummaryDraft = '';
    @track _subtaskError        = null;

    newSubtask = emptySubtask();

    // Subtasks are derived from the parent-owned ticket state, never stored
    // separately. Display fields are enriched and the transient edit/selection
    // flags are derived per row on each read.
    get subtasks() {
        const raw = Array.isArray(this._ticket.subtasks) ? this._ticket.subtasks : [];
        return raw.map(s => {
            const isEditing = this._editingSubtaskId === s.Id;
            return {
                ...enrichSubtask(s, this.statusOptions, this._memberOptions),
                _key            : s._key || s.Id,
                isSelected      : this.selectedSubtaskIds.includes(s.Id),
                isEditingSummary: isEditing,
                summaryDraft    : isEditing ? this._subtaskSummaryDraft : '',
                subtaskError    : isEditing ? this._subtaskError : null,
            };
        });
    }

    // ─── EVENT DISPATCHERS ───────────────────────────────────────────────────

    handleCreateSubtaskSubmit() {
        const error = validateSubtask(this.newSubtask);
        if (error) { this.modalError = error; return; }
        const { summary, description, assigneeId, currentStateId, storyPoint } = this.newSubtask;
        this._dispatch('subtaskcreate', {
            ticketId      : this.ticket.Id,
            summary,
            description   : description    || null,
            assigneeId    : assigneeId     || null,
            currentStateId: currentStateId || null,
            storyPoint    : storyPoint ? parseInt(storyPoint, 10) : null,
        });
        this.showCreateSubtaskModal = false;
        this.modalError             = null;
    }

    handleSubtaskSaveSummary(event) {
        const id      = event.currentTarget.dataset.id;
        const summary = (this._subtaskSummaryDraft || '').trim();
        const error   = validateSummary(summary);
        if (error) { this._subtaskError = error; return; }
        this._clearSubtaskEdit();
        this._dispatch('subtasksummaryupdate', { ticketId: this.ticket.Id, subtaskId: id, summary });
    }

    handleSubtaskAssigneeChange(event) {
        const id       = event.currentTarget.dataset.id;
        const memberId = event.detail.value;
        this._dispatch('subtaskassigneechange', { ticketId: this.ticket.Id, subtaskId: id, memberId });
    }

    handleSubtaskDeleteClick(event) {
        const id = event.currentTarget.dataset.id;
        this._confirm('Delete this subtask?', () => {
            this._dispatch('subtaskdelete', { ticketId: this.ticket.Id, subtaskId: id });
        });
    }

    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────

    handleSubtaskSelect(event) {
        const id      = event.currentTarget.dataset.id;
        const checked = event.detail.checked;
        this.selectedSubtaskIds = checked
            ? [...this.selectedSubtaskIds, id]
            : this.selectedSubtaskIds.filter(sid => sid !== id);
    }

    handleBulkCancelSelect() {
        this.selectedSubtaskIds = [];
    }

    handleBulkDeleteSubtasks() {
        const ids = [...this.selectedSubtaskIds];
        this._confirm(`Delete ${ids.length} subtask${ids.length > 1 ? 's' : ''}?`, () => {
            this.selectedSubtaskIds = [];
            this._dispatch('subtasksbulkdelete', { ticketId: this.ticket.Id, subtaskIds: ids });
        });
    }

    // -- Summary --
    handleSubtaskStartEditSummary(event) {
        const id  = event.currentTarget.dataset.id;
        const sub = (this._ticket.subtasks || []).find(s => s.Id === id);
        this._editingSubtaskId    = id;
        this._subtaskSummaryDraft = sub ? sub.Summary__c : '';
        this._subtaskError        = null;
    }

    handleSubtaskSummaryDraftChange(event) {
        this._subtaskSummaryDraft = event.detail.value;
    }

    handleSubtaskCancelEditSummary() {
        this._clearSubtaskEdit();
    }

    // -- Subtask modal --
    handleOpenCreateSubtaskModal() {
        this.newSubtask             = emptySubtask();
        this.modalError             = null;
        this.showCreateSubtaskModal = true;
    }

    handleCloseCreateSubtaskModal() {
        this.showCreateSubtaskModal = false;
        this.modalError             = null;
    }

    handleNewSubtaskChange(event) {
        const field = event.target.dataset.field;
        const val   = event.detail ? event.detail.value : event.target.value;
        this.newSubtask = { ...this.newSubtask, [field]: val };
    }

    // ─── GETTERS ─────────────────────────────────────────────────────────────

    get hasSelectedSubtasks()  { return this.selectedSubtaskIds.length > 0; }
    get selectedSubtaskCount() { return this.selectedSubtaskIds.length; }

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PRIVATE   HELPER                               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    _confirm(message, action) {
        this.confirmMessage    = message;
        this._pendingAction    = action;
        this.showConfirmDialog = true;
    }

    _clearSubtaskEdit() {
        this._editingSubtaskId    = null;
        this._subtaskSummaryDraft = '';
        this._subtaskError        = null;
    }

    _dispatch(name, detail) {
        this.dispatchEvent(new CustomEvent(name, { bubbles: true, composed: true, detail }));
    }
}

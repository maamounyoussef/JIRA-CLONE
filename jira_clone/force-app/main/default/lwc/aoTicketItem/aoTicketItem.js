import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import loadSubtasks    from '@salesforce/apex/ManageBacklogController.loadSubtasks';
import { validateSummary, validateSubtask, validateEpicSelection, validateNewEpic } from './ticketValidator';
import { emptyEpic, formatEpicsAsOptions, toISODateOrNull, failed }                 from './ticketUtils';
import { emptySubtask, enrichSubtask, buildSubtaskComboboxOptions }                 from './subtaskUtils';

export default class AoTicketItem extends LightningElement {

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                            TICKET SECTION                               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ──────────────────────────────────────────────────

    @api ticket          = {};
    @api statusOptions   = [];
    @api priorityOptions = [];
    @api projectId       = '';
    @api epics           = [];

    _memberOptions = [];

    @api
    get memberOptions() { return this._memberOptions; }
    set memberOptions(value) {
        this._memberOptions = value || [];
        this.subtasks = this.subtasks.map(s => ({
            ...s,
            subtaskComboboxOptions: buildSubtaskComboboxOptions(s.Assignee__c, s.assigneeName, this._memberOptions),
        }));
    }

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

    // ─── WIRE ────────────────────────────────────────────────────────────────

    @wire(loadSubtasks, { ticketId: '$ticket.Id' })
    wiredSubtasks(result) {
        this._wiredResult      = result;
        this.isLoadingSubtasks = false;

        if (result.error) {
            this.errorMessage = result.error.body?.message || 'Error loading subtasks';
            return;
        }
        if (result.data) {
            if (failed(result.data, msg => { this.errorMessage = msg; })) return;
            this.subtasks = (result.data.data || []).map(s => enrichSubtask(s, this.statusOptions, this._memberOptions));
        }
    }

    // ─── PUBLIC API ──────────────────────────────────────────────────────────

    _errors = null;

    // null → success: close whichever modal is open
    // string → error: show inside the open modal
    @api
    get errors() { return this._errors; }
    set errors(value) {
        this._errors = value;
        if (value === null) {
            if (this.showCreateSubtaskModal) this.isExpanded = true;
            this.showCreateSubtaskModal = false;
            this.showEpicModal          = false;
            this.showCreateEpicModal    = false;
            this.modalError             = null;
        } else {
            this.modalError = value;
        }
    }

    // non-modal errors from parent Apex calls (shown on the ticket row, not the page banner)
    @api
    get ticketError() { return this.errorMessage; }
    set ticketError(value) { this.errorMessage = value; }

    @api refreshSubtasks() {
        return refreshApex(this._wiredResult);
    }

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
        this._dispatch('ticketstatechange', { ticketId: this.ticket.Id, stateId: event.detail.value });
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
    }

    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────

    handleToggleSubtasks() { this.isExpanded = !this.isExpanded; }

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
    @track subtasks               = [];
    @track selectedSubtaskIds     = [];
    @track showCreateSubtaskModal = false;

    _wiredResult = null;
    newSubtask   = emptySubtask();

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
    }

    handleSubtaskSaveSummary(event) {
        const id      = event.currentTarget.dataset.id;
        const sub     = this.subtasks.find(s => s.Id === id);
        const summary = (sub.summaryDraft || '').trim();
        const error   = validateSummary(summary);
        if (error) { this._patchSubtask(id, { subtaskError: error }); return; }
        this._patchSubtask(id, { isEditingSummary: false, Summary__c: summary, subtaskError: null });
        this._dispatch('subtasksummaryupdate', { subtaskId: id, summary });
    }

    handleSubtaskAssigneeChange(event) {
        const id       = event.currentTarget.dataset.id;
        const memberId = event.detail.value;
        const selected = this._memberOptions.find(m => m.value === memberId);
        this._patchSubtask(id, { Assignee__c: memberId, assigneeName: selected ? selected.label : '' });
        this._dispatch('subtaskassigneechange', { subtaskId: id, memberId });
    }

    handleSubtaskDeleteClick(event) {
        const id = event.currentTarget.dataset.id;
        this._confirm('Delete this subtask?', () => {
            this._dispatch('subtaskdelete', { subtaskId: id });
        });
    }

    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────

    handleSubtaskSelect(event) {
        const id      = event.currentTarget.dataset.id;
        const checked = event.detail.checked;
        this._patchSubtask(id, { isSelected: checked });
        this.selectedSubtaskIds = checked
            ? [...this.selectedSubtaskIds, id]
            : this.selectedSubtaskIds.filter(sid => sid !== id);
    }

    handleBulkCancelSelect() {
        this.selectedSubtaskIds = [];
        this.subtasks = this.subtasks.map(s => ({ ...s, isSelected: false }));
    }

    handleBulkDeleteSubtasks() {
        const ids = [...this.selectedSubtaskIds];
        this._confirm(`Delete ${ids.length} subtask${ids.length > 1 ? 's' : ''}?`, () => {
            this.selectedSubtaskIds = [];
            this._dispatch('subtasksbulkdelete', { subtaskIds: ids });
        });
    }

    // -- Summary --
    handleSubtaskStartEditSummary(event) {
        const id  = event.currentTarget.dataset.id;
        const sub = this.subtasks.find(s => s.Id === id);
        this._patchSubtask(id, { isEditingSummary: true, summaryDraft: sub.Summary__c });
    }

    handleSubtaskSummaryDraftChange(event) {
        this._patchSubtask(event.currentTarget.dataset.id, { summaryDraft: event.detail.value });
    }

    handleSubtaskCancelEditSummary(event) {
        this._patchSubtask(event.currentTarget.dataset.id, { isEditingSummary: false, subtaskError: null });
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

    _patchSubtask(id, patch) {
        this.subtasks = this.subtasks.map(s => s.Id === id ? { ...s, ...patch } : s);
    }

    _dispatch(name, detail) {
        this.dispatchEvent(new CustomEvent(name, { bubbles: true, composed: true, detail }));
    }
}

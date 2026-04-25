import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import updateTicketSummary  from '@salesforce/apex/ManageBacklogController.updateTicketSummary';
import updateTicketPriority from '@salesforce/apex/ManageBacklogController.updateTicketPriority';
import updateTicketState    from '@salesforce/apex/ManageBacklogController.updateTicketState';
import updateTicketEpic     from '@salesforce/apex/ManageBacklogController.updateTicketEpic';
import assignTicket         from '@salesforce/apex/ManageBacklogController.assignTicket';
import deleteTicket         from '@salesforce/apex/ManageBacklogController.deleteTicket';
import loadSubtasks         from '@salesforce/apex/ManageBacklogController.loadSubtasks';
import createSubtask        from '@salesforce/apex/ManageBacklogController.createSubtask';
import loadMembers          from '@salesforce/apex/ManageBacklogController.loadMembers';
import createEpic           from '@salesforce/apex/ManageBacklogController.createEpic';
import { validateSummary, validateSubtask, validateEpicSelection, validateNewEpic } from './ticketValidator';
import { PRIORITY_OPTIONS, emptySubtask, emptyEpic, enrichSubtask, formatMembersAsOptions, formatEpicsAsOptions, toISODateOrNull, failed } from './ticketUtils';

export default class AoTicketItem extends LightningElement {

    // ─── PROPERTIES & STATE ──────────────────────────────────────────────────

    @api ticket          = {};
    @api statusOptions   = [];
    @api memberOptions   = [];
    @api priorityOptions = PRIORITY_OPTIONS;
    @api projectId       = '';
    @api epics           = [];

    @track isExpanded        = false;
    @track isLoadingSubtasks = false;
    @track subtasks          = [];

    @track isEditingSummary  = false;
    @track summaryDraft      = '';

    @track isEditingPriority = false;
    @track priorityDraft     = '';

    @track errorMessage          = null;
    @track modalError            = null;
    @track assigneeMemberOptions = [];
    @track isLoadingMembers      = false;
    @track hasLoadedMembers      = false;

    @track showConfirmDialog      = false;
    @track showCreateSubtaskModal = false;
    confirmMessage = '';
    _pendingAction = null;
    _wiredResult   = null;   // holds raw wire result for refreshApex

    @track showEpicModal       = false;
    @track showCreateEpicModal = false;
    @track epicOptions         = [];
    @track selectedEpicId      = '';
    @track hasEpics            = false;
    @track isLoadingEpics      = false;

    newSubtask = emptySubtask();
    newEpic    = emptyEpic();

    // ─── LIFECYCLE HOOKS ─────────────────────────────────────────────────────
    // (none)

    // ─── WIRE ────────────────────────────────────────────────────────────────

    // Fires once on connect; re-runs only when refreshApex(_wiredResult) is called.
    // Toggle expand/collapse never triggers a new server round-trip.
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
            this.subtasks   = (result.data.data || []).map(s => enrichSubtask(s, this.statusOptions, this.memberOptions));
        }
    }

    // ─── APEX CALLS ──────────────────────────────────────────────────────────

    handleSaveSummary() {
        const ticketId = this.ticket.Id;
        const summary  = this.summaryDraft;
        const error    = validateSummary(summary);
        if (error) { this.errorMessage = error; return; }
        updateTicketSummary({ ticketId, summary })
            .then(res => {
                if (failed(res, msg => { this.errorMessage = msg; })) return;
                this.isEditingSummary = false;
                this._notifyUpdate('Summary__c', summary);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating summary'; });
    }

    handleSavePriority() {
        const ticketId = this.ticket.Id;
        const priority = this.priorityDraft;
        updateTicketPriority({ ticketId, priority })
            .then(res => {
                if (failed(res, msg => { this.errorMessage = msg; })) return;
                this.isEditingPriority = false;
                this._notifyUpdate('Priority__c', priority);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating priority'; });
    }

    handleStateChange(event) {
        const ticketId = this.ticket.Id;
        const stateId  = event.detail.value;
        updateTicketState({ ticketId, stateId })
            .then(res => {
                if (failed(res, msg => { this.errorMessage = msg; })) return;
                this._notifyUpdate('CurrentState__c', stateId);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating state'; });
    }

    handleLoadMembers() {
        if (this.hasLoadedMembers || this.isLoadingMembers || !this.projectId) return;
        this.isLoadingMembers = true;
        loadMembers({ projectId: this.projectId })
            .then(res => {
                if (failed(res, msg => { this.errorMessage = msg; })) return;
                this.assigneeMemberOptions = formatMembersAsOptions(res.data);
                this.hasLoadedMembers      = true;
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error loading members'; })
            .finally(() => { this.isLoadingMembers = false; });
    }

    handleAssigneeChange(event) {
        const ticketId = this.ticket.Id;
        const memberId = event.detail.value;
        assignTicket({ ticketId, memberId })
            .then(res => {
                if (failed(res, msg => { this.errorMessage = msg; })) return;
                const selected = this.assigneeMemberOptions.find(m => m.value === memberId);
                this.ticket = { ...this.ticket, AssignedTo__c: memberId, assigneeName: selected ? selected.label : '' };
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error assigning ticket'; });
    }

    handleCreateSubtaskSubmit() {
        const { summary, description, assigneeId, currentStateId, storyPoint } = this.newSubtask;
        const error = validateSubtask(this.newSubtask);
        if (error) { this.modalError = error; return; }
        createSubtask({
            summary,
            ticketId      : this.ticket.Id,
            description   : description    || null,
            assigneeId    : assigneeId     || null,
            currentStateId: currentStateId || null,
            storyPoint    : storyPoint ? parseInt(storyPoint, 10) : null,
            startDate     : null,
        })
        .then(res => {
            if (failed(res, msg => { this.modalError = msg; })) return;
            this.showCreateSubtaskModal = false;
            this.isExpanded             = true;
            return refreshApex(this._wiredResult);
        })
        .catch(err => { this.modalError = err.body?.message || 'Error creating subtask'; });
    }

    //  INCLUDE PATHER CALL
    handleDeleteClick() {
        this._confirm('Are you sure you want to delete this ticket?', () => {
            deleteTicket({ ticketId: this.ticket.Id })
                .then(res => {
                    if (failed(res, msg => { this.errorMessage = msg; })) return;
                    this.dispatchEvent(new CustomEvent('ticketdeleted', {
                        bubbles  : true,
                        composed : true,
                        detail   : { ticketId: this.ticket.Id },
                    }));
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error deleting ticket'; });
        });
    }

    handleAssignEpic() {
        const error = validateEpicSelection(this.selectedEpicId);
        if (error) { this.modalError = error; return; }
        const ticketId = this.ticket.Id;
        const epicId   = this.selectedEpicId;
        updateTicketEpic({ ticketId, epicId })
            .then(res => {
                if (failed(res, msg => { this.modalError = msg; })) return;
                const selected = this.epicOptions.find(e => e.value === epicId);
                this.ticket = { ...this.ticket, Epic__c: epicId, epicName: selected ? selected.label.split(' - ')[0] : '' };
                this.showEpicModal = false;
                this._notifyUpdate('Epic__c', epicId);
            })
            .catch(err => { this.modalError = err.body?.message || 'Error updating epic parent'; });
    }

    handleCreateEpicSubmit() {
        const { name, summary, description, startDate, endDate } = this.newEpic;
        const error = validateNewEpic(this.newEpic);
        if (error) { this.modalError = error; return; }
        createEpic({
            name,
            summary,
            projectId  : this.projectId,
            description: description || null,
            startDate  : toISODateOrNull(startDate),
            endDate    : toISODateOrNull(endDate),
        })
        .then(res => {
            if (failed(res, msg => { this.modalError = msg; })) return;
            return updateTicketEpic({ ticketId: this.ticket.Id, epicId: res.data.Id });
        })
        .then(res => {
            if (res && failed(res, msg => { this.modalError = msg; })) return;
            if (res) {
                this.ticket = { ...this.ticket, Epic__c: res.data.Epic__c, epicName: this.newEpic.name };
                this.showCreateEpicModal = false;
                this._notifyUpdate('Epic__c', res.data.Epic__c);
            }
        })
        .catch(err => { this.modalError = err.body?.message || 'Error creating epic'; });
    }

    // ─── EVENT HANDLERS ──────────────────────────────────────────────────────

    handleToggleSubtasks() {
        this.isExpanded = !this.isExpanded;
    }

    //  INCLUDE PATHER CALL
    handleSelect(event) {
        this.dispatchEvent(new CustomEvent('ticketselect', {
            bubbles  : true,
            composed : true,
            detail   : { ticketId: this.ticket.Id, selected: event.target.checked },
        }));
    }

    // -- Summary --
    handleStartEditSummary() {
        this.summaryDraft     = this.ticket.Summary__c;
        this.isEditingSummary = true;
    }

    handleSummaryDraftChange(event) { this.summaryDraft = event.target.value; }

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

    // -- Subtask events (bubbled from aoSubtaskItem) --
    handleSubtaskDeleted() {
        refreshApex(this._wiredResult);
    }

    handleSubtaskUpdated(event) {
        const { subtaskId, field, value } = event.detail;
        this.subtasks = this.subtasks.map(s => {
            if (s.Id !== subtaskId) return s;
            const updated = { ...s, [field]: value };
            if (field === 'Assignee__c') {
                const opt        = this.memberOptions.find(o => o.value === value);
                updated.assigneeName = opt ? opt.label : '';
            }
            return updated;
        });
    }

    // -- Epic modal --
    handleOpenEpicModal() {
        this.modalError     = null;
        this.selectedEpicId = this.ticket.Epic__c || '';
        const epics         = this.epics || [];
        this.hasEpics       = epics.length > 0;
        this.epicOptions    = formatEpicsAsOptions(epics);
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
        if (this.epicOptions.length > 0 || !this.hasEpics) {
            this.showEpicModal = true;
        }
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
    get epicModalTitle()       { return this.hasEpics ? 'Update Epic Parent' : 'No Epics Available'; }
    get isEpicAssignDisabled() { return !this.selectedEpicId; }

    get comboboxAssigneeOptions() {
        if (this.ticket.AssignedTo__c && this.ticket.assigneeName) {
            const current    = { label: this.ticket.assigneeName, value: this.ticket.AssignedTo__c };
            const hasCurrent = this.assigneeMemberOptions.some(o => o.value === this.ticket.AssignedTo__c);
            if (!hasCurrent) return [current, ...this.assigneeMemberOptions];
        }
        return this.assigneeMemberOptions;
    }

    // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

    _confirm(message, action) {
        this.confirmMessage    = message;
        this._pendingAction    = action;
        this.showConfirmDialog = true;
    }

    //  INCLUDE PATHER CALL
    _notifyUpdate(field, value) {
        this.dispatchEvent(new CustomEvent('ticketupdated', {
            bubbles  : true,
            composed : true,
            detail   : { ticketId: this.ticket.Id, field, value },
        }));
    }
}

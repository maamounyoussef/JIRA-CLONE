import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import updateTicketSummary  from '@salesforce/apex/ManageBacklogController.updateTicketSummary';
import updateTicketPriority from '@salesforce/apex/ManageBacklogController.updateTicketPriority';
import updateTicketState    from '@salesforce/apex/ManageBacklogController.updateTicketState';
import assignTicket         from '@salesforce/apex/ManageBacklogController.assignTicket';
import deleteTicket         from '@salesforce/apex/ManageBacklogController.deleteTicket';
import loadSubtasks         from '@salesforce/apex/ManageBacklogController.loadSubtasks';
import createSubtask        from '@salesforce/apex/ManageBacklogController.createSubtask';
import loadMembers          from '@salesforce/apex/ManageBacklogController.loadMembers';

const PRIORITY_OPTIONS = [
    { label: '—',        value: ''         },
    { label: 'Low',      value: 'Low'      },
    { label: 'Medium',   value: 'Medium'   },
    { label: 'High',     value: 'High'     },
    { label: 'Critical', value: 'Critical' },
];

export default class AoTicketItem extends LightningElement {

    // ── API props passed from parent (manageBacklog) ─────────────────────────
    @api ticket          = {};
    @api statusOptions   = [];
    @api memberOptions   = [];
    @api priorityOptions = PRIORITY_OPTIONS;
    @api projectId       = '';

    // ── Internal state ────────────────────────────────────────────────────────
    @track isExpanded          = false;
    @track isLoadingSubtasks   = false;
    @track subtasks            = [];

    @track isEditingSummary    = false;
    @track summaryDraft        = '';

    @track isEditingPriority   = false;
    @track priorityDraft       = '';

    @track errorMessage        = null;
    @track modalError          = null;
    @track assigneeMemberOptions = [];
    @track isLoadingMembers    = false;
    @track hasLoadedMembers    = false;

    @track showConfirmDialog      = false;
    @track showCreateSubtaskModal = false;
    confirmMessage  = '';
    _pendingAction  = null;
    _wiredResult    = null;   // holds the raw wire result for refreshApex
    _hasLoaded      = false;  // true after the first successful wire load

    newSubtask = this._emptySubtask();

    // ── Computed ──────────────────────────────────────────────────────────────
    get expandIcon()    { return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright'; }
    get hasSubtasks()   { return this.subtasks.length > 0; }
    get spLabel()       { return this.ticket.StoryPoint__c != null ? this.ticket.StoryPoint__c : '—'; }
    get priorityLabel() { return this.ticket.Priority__c  || '—'; }

    // ── Helpers ───────────────────────────────────────────────────────────────
    _emptySubtask() {
        return { summary: '', description: '', assigneeId: '', currentStateId: '', storyPoint: null };
    }

    _enrichSubtask(sub) {
        const stateOpt  = this.statusOptions.find(o => o.value === sub.CurrentState__c);
        const memberOpt = this.memberOptions.find(o => o.value === sub.Assignee__c);
        return {
            ...sub,
            stateName    : stateOpt  ? stateOpt.label  : '',
            assigneeName : memberOpt ? memberOpt.label : '',
            isSelected   : false,
        };
    }

    // ── Wire: load subtasks ───────────────────────────────────────────────────
    // The wire fires once when the component connects (ticketId is available).
    // After that it only re-runs when refreshApex(_wiredResult) is called,
    // which happens after every create / delete mutation.
    // Toggle expand/collapse NEVER triggers a new server request.
    @wire(loadSubtasks, { ticketId: '$ticket.Id' })
    wiredSubtasks(result) {
        this._wiredResult      = result;   // save for refreshApex calls
        this.isLoadingSubtasks = false;

        if (result.error) {
            this.errorMessage = result.error.body?.message || 'Error loading subtasks';
            return;
        }
        if (result.data) {
            if (!result.data.success) { this.errorMessage = result.data.message; return; }
            this.subtasks  = (result.data.data || []).map(s => this._enrichSubtask(s));
            this._hasLoaded = true;
        }
    }

    // ── Expand / collapse ─────────────────────────────────────────────────────
    // Toggle only controls visibility.
    // subtasks are already populated by the wire on component mount,
    // so no extra server call is ever needed here.
    handleToggleSubtasks() {
        this.isExpanded = !this.isExpanded;
    }

    // ── Confirm dialog ────────────────────────────────────────────────────────
    _confirm(message, action) {
        this.confirmMessage    = message;
        this._pendingAction    = action;
        this.showConfirmDialog = true;
    }

    handleConfirm() {
        this.showConfirmDialog = false;
        if (this._pendingAction) { this._pendingAction(); this._pendingAction = null; }
    }

    handleCancelConfirm() {
        this.showConfirmDialog = false;
        this._pendingAction    = null;
    }

    clearError() { this.errorMessage = null; }

    // ── Select ────────────────────────────────────────────────────────────────
    handleSelect(event) {
        this.dispatchEvent(new CustomEvent('ticketselect', {
            bubbles  : true,
            composed : true,
            detail   : { ticketId: this.ticket.Id, selected: event.target.checked },
        }));
    }

    // ── Summary inline edit ───────────────────────────────────────────────────
    handleStartEditSummary() {
        this.summaryDraft     = this.ticket.Summary__c;
        this.isEditingSummary = true;
    }

    handleSummaryDraftChange(event) {
        this.summaryDraft = event.target.value;
    }

    handleSaveSummary() {
        const ticketId = this.ticket.Id;
        const summary  = this.summaryDraft;
        if (!summary) { this.errorMessage = 'Summary cannot be empty.'; return; }
        updateTicketSummary({ ticketId, summary })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.isEditingSummary = false;
                this._notifyUpdate('Summary__c', summary);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating summary'; });
    }

    handleCancelEditSummary() {
        this.isEditingSummary = false;
        this.errorMessage     = null;
    }

    // ── Priority inline edit ──────────────────────────────────────────────────
    handleStartEditPriority() {
        this.priorityDraft     = this.ticket.Priority__c || '';
        this.isEditingPriority = true;
    }

    handlePriorityDraftChange(event) {
        this.priorityDraft = event.detail.value;
    }

    handleSavePriority() {
        const ticketId = this.ticket.Id;
        const priority = this.priorityDraft;
        updateTicketPriority({ ticketId, priority })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.isEditingPriority = false;
                this._notifyUpdate('Priority__c', priority);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating priority'; });
    }

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

    // ── State change ──────────────────────────────────────────────────────────
    handleStateChange(event) {
        const ticketId = this.ticket.Id;
        const stateId  = event.detail.value;
        updateTicketState({ ticketId, stateId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this._notifyUpdate('CurrentState__c', stateId);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating state'; });
    }

    // ── Assignee lazy loading & change ────────────────────────────────────────
    get comboboxAssigneeOptions() {
        if (this.ticket.AssignedTo__c && this.ticket.assigneeName) {
            const currentAssignee = { label: this.ticket.assigneeName, value: this.ticket.AssignedTo__c };
            const hasCurrent = this.assigneeMemberOptions.some(o => o.value === this.ticket.AssignedTo__c);
            if (!hasCurrent) return [currentAssignee, ...this.assigneeMemberOptions];
        }
        return this.assigneeMemberOptions;
    }

    handleLoadMembers() {
        if (this.hasLoadedMembers || this.isLoadingMembers || !this.projectId) return;
        this.isLoadingMembers = true;
        loadMembers({ projectId: this.projectId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.assigneeMemberOptions = (res.data || []).map(m => ({ label: m.Name, value: m.Id }));
                this.hasLoadedMembers = true;
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error loading members'; })
            .finally(() => { this.isLoadingMembers = false; });
    }

    handleAssigneeChange(event) {
        const ticketId = this.ticket.Id;
        const memberId = event.detail.value;
        assignTicket({ ticketId, memberId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const selectedMember = this.assigneeMemberOptions.find(m => m.value === memberId);
                this.ticket = { ...this.ticket, AssignedTo__c: memberId, assigneeName: selectedMember ? selectedMember.label : '' };
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error assigning ticket'; });
    }

    // ── Create subtask ────────────────────────────────────────────────────────
    handleOpenCreateSubtaskModal() {
        this.newSubtask = this._emptySubtask();
        this.modalError = null;
        this.showCreateSubtaskModal = true;
    }

    handleCloseCreateSubtaskModal() {
        this.showCreateSubtaskModal = false;
        this.modalError = null;
    }

    handleNewSubtaskChange(event) {
        const field = event.target.dataset.field;
        const val   = event.detail ? event.detail.value : event.target.value;
        this.newSubtask = { ...this.newSubtask, [field]: val };
    }

    handleCreateSubtaskSubmit() {
        const { summary, description, assigneeId, currentStateId, storyPoint } = this.newSubtask;
        if (!summary) { this.modalError = 'Summary is required.'; return; }
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
            if (!res.success) { this.modalError = res.message; return; }
            this.showCreateSubtaskModal = false;
            this.isExpanded             = true;
            // refreshApex re-runs the wire → subtasks array updates automatically
            return refreshApex(this._wiredResult);
        })
        .catch(err => { this.modalError = err.body?.message || 'Error creating subtask'; });
    }

    // ── Delete ticket ─────────────────────────────────────────────────────────
    handleDeleteClick() {
        this._confirm('Are you sure you want to delete this ticket?', () => {
            const ticketId = this.ticket.Id;
            deleteTicket({ ticketId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.dispatchEvent(new CustomEvent('ticketdeleted', {
                        bubbles  : true,
                        composed : true,
                        detail   : { ticketId: this.ticket.Id },
                    }));
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error deleting ticket'; });
        });
    }

    // ── Subtask event handlers (bubbled from aoSubtaskItem) ───────────────────
    handleSubtaskDeleted() {
        // refreshApex re-runs the wire → subtasks array updates automatically
        refreshApex(this._wiredResult);
    }

    handleSubtaskUpdated(event) {
        const { subtaskId, field, value } = event.detail;
        this.subtasks = this.subtasks.map(s => {
            if (s.Id !== subtaskId) return s;
            const updated = { ...s, [field]: value };
            if (field === 'Assignee__c') {
                const memberOpt = this.memberOptions.find(o => o.value === value);
                updated.assigneeName = memberOpt ? memberOpt.label : '';
            }
            return updated;
        });
    }

    // ── Notify parent of field update ─────────────────────────────────────────
    _notifyUpdate(field, value) {
        this.dispatchEvent(new CustomEvent('ticketupdated', {
            bubbles  : true,
            composed : true,
            detail   : { ticketId: this.ticket.Id, field, value },
        }));
    }
}
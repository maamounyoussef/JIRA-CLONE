import { LightningElement, api, track } from 'lwc';
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
    @api ticket        = {};   // enriched with assigneeName
    @api statusOptions  = [];
    @api memberOptions  = [];  // pre-loaded members for create subtask modal
    @api priorityOptions = PRIORITY_OPTIONS;
    @api projectId      = '';  // for lazy-loading members in assignee dropdown

    // ── Internal state ────────────────────────────────────────────────────────
    @track isExpanded        = false;
    @track isLoadingSubtasks = false;
    @track subtasks          = [];

    @track isEditingSummary  = false;
    @track summaryDraft      = '';

    @track isEditingPriority = false;
    @track priorityDraft     = '';

    @track errorMessage      = null;
    @track modalError        = null;
    @track assigneeMemberOptions = [];   // lazy-loaded for assignee combobox
    @track isLoadingMembers   = false;
    @track hasLoadedMembers   = false;

    @track showConfirmDialog    = false;
    @track showCreateSubtaskModal = false;
    confirmMessage = '';
    _pendingAction = null;

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
        // Build stateName from statusOptions available in parent scope
        const stateOpt = this.statusOptions.find(o => o.value === sub.CurrentState__c);
        // Build assigneeName from memberOptions (pre-loaded for create subtask modal)
        const memberOpt = this.memberOptions.find(o => o.value === sub.Assignee__c);
        return {
            ...sub,
            stateName: stateOpt ? stateOpt.label : '',
            assigneeName: memberOpt ? memberOpt.label : '',
            isSelected: false
        };
    }

    // ── Confirm ───────────────────────────────────────────────────────────────
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

    // ── Expand / load subtasks ────────────────────────────────────────────────
    handleToggleSubtasks() {
        if (!this.isExpanded) {
            this.isExpanded        = true;
            this.isLoadingSubtasks = true;
            loadSubtasks({ ticketId: this.ticket.Id })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.subtasks = (res.data || []).map(s => this._enrichSubtask(s));
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error loading subtasks'; })
                .finally(() => { this.isLoadingSubtasks = false; });
        } else {
            this.isExpanded = false;
        }
    }

    // ── Summary inline edit ───────────────────────────────────────────────────
    handleStartEditSummary() {
        this.summaryDraft    = this.ticket.Summary__c;
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
        this.priorityDraft    = this.ticket.Priority__c || '';
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
        // Check if related target is within the edit container
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

    // ── Assignee lazy loading & change ───────────────────────────────────────
    get comboboxAssigneeOptions() {
        // Always include current assignee if exists (so combobox displays it correctly)
        if (this.ticket.AssignedTo__c && this.ticket.assigneeName) {
            const currentAssignee = { label: this.ticket.assigneeName, value: this.ticket.AssignedTo__c };
            // Avoid duplicates if already loaded
            const hasCurrent = this.assigneeMemberOptions.some(o => o.value === this.ticket.AssignedTo__c);
            if (!hasCurrent) {
                return [currentAssignee, ...this.assigneeMemberOptions];
            }
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
                // Update local assignee name for display
                const selectedMember = this.assigneeMemberOptions.find(m => m.value === memberId);
                this.ticket.assigneeName = selectedMember ? selectedMember.label : '';
                this._notifyUpdate('AssignedTo__c', memberId);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error assigning ticket'; });
    }

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
            description   : description   || null,
            assigneeId    : assigneeId    || null,
            currentStateId: currentStateId || null,
            storyPoint    : storyPoint ? parseInt(storyPoint, 10) : null,
            startDate     : null,
        })
            .then(res => {
                if (!res.success) { this.modalError = res.message; return; }
                const newSub = this._enrichSubtask(res.data);
                this.subtasks = [...this.subtasks, newSub];
                // Auto-expand to show new subtask
                this.isExpanded             = true;
                this.showCreateSubtaskModal = false;
                this.newSubtask             = this._emptySubtask();
            })
            .catch(err => { this.modalError = err.body?.message || 'Error creating subtask'; });
    }

    // ── Delete ticket ─────────────────────────────────────────────────────────
    handleDeleteClick() {
        this._confirm('Are you sure you want to delete this ticket?', () => {
            const ticketId = this.ticket.Id;
            deleteTicket({ ticketId })
                .then(res => {
                    if (!res.success) {
                        this.errorMessage = res.message;
                        return;
                    }
                    // Notify parent to remove this ticket from the list
                    this.dispatchEvent(new CustomEvent('ticketdeleted', {
                        bubbles: true,
                        composed: true,
                        detail: { ticketId: this.ticket.Id }
                    }));
                })
                .catch(err => {
                    this.errorMessage = err.body?.message || 'Error deleting ticket';
                });
        });
    }

    // ── Subtask event handlers (bubbled from aoSubtaskItem) ───────────────────
    handleSubtaskDeleted(event) {
        const { subtaskId } = event.detail;
        this.subtasks = this.subtasks.filter(s => s.Id !== subtaskId);
    }

    handleSubtaskUpdated(event) {
        const { subtaskId, field, value } = event.detail;
        this.subtasks = this.subtasks.map(s => {
            if (s.Id !== subtaskId) return s;
            const updated = { ...s, [field]: value };
            // If assignee changed, update the display name from memberOptions
            if (field === 'Assignee__c') {
                const memberOpt = this.memberOptions.find(o => o.value === value);
                updated.assigneeName = memberOpt ? memberOpt.label : '';
            }
            return updated;
        });
    }

    // ── Notify parent of field update (so parent list stays in sync) ───
    _notifyUpdate(field, value) {
        this.dispatchEvent(new CustomEvent('ticketupdated', {
            bubbles  : true,
            composed : true,
            detail   : { ticketId: this.ticket.Id, field, value },
        }));
    }
}
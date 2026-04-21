import { LightningElement, api, track } from 'lwc';
import updateSubtaskSummary from '@salesforce/apex/ManageBacklogController.updateSubtaskSummary';
import assignSubtask        from '@salesforce/apex/ManageBacklogController.assignSubtask';
import deleteSubtask        from '@salesforce/apex/ManageBacklogController.deleteSubtask';
import loadMembers          from '@salesforce/apex/ManageBacklogController.loadMembers';

export default class AoSubtaskItem extends LightningElement {

    // ── API props passed from parent (aoTicketItem) ─────────────────────────
    @api subtask      = {};   // enriched subtask object (with assigneeName)
    @api projectId    = '';   // for lazy-loading members

    // ── Internal state ───────────────────────────────────────────────────────
    @track isEditingSummary  = false;
    @track summaryDraft      = '';
    @track errorMessage      = null;
    @track showConfirmDialog = false;
    @track memberOptions     = [];   // lazy-loaded when user opens assignee dropdown
    @track isLoadingMembers  = false;
    @track hasLoadedMembers   = false;
    confirmMessage           = 'Delete this subtask?';
    _pendingAction           = null;

    // ── Confirm helpers ──────────────────────────────────────────────────────
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

    // ── Select ───────────────────────────────────────────────────────────────
    handleSelect(event) {
        // Bubble selection change up to parent ticket
        this.dispatchEvent(new CustomEvent('subtaskselect', {
            bubbles  : true,
            composed : true,
            detail   : { subtaskId: this.subtask.Id, selected: event.target.checked },
        }));
    }

    // ── Summary inline edit ──────────────────────────────────────────────────
    handleStartEditSummary() {
        this.summaryDraft     = this.subtask.Summary__c;
        this.isEditingSummary = true;
    }

    handleSummaryDraftChange(event) {
        this.summaryDraft = event.target.value;
    }

    handleSaveSummary() {
        const subtaskId = this.subtask.Id;
        const summary   = this.summaryDraft;
        if (!summary) { this.errorMessage = 'Summary cannot be empty.'; return; }
        updateSubtaskSummary({ subtaskId, summary })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.isEditingSummary = false;
                // Notify parent to update its data
                this.dispatchEvent(new CustomEvent('subtaskupdated', {
                    bubbles  : true,
                    composed : true,
                    detail   : { subtaskId, field: 'Summary__c', value: summary },
                }));
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error updating summary'; });
    }

    handleCancelEditSummary() {
        this.isEditingSummary = false;
        this.errorMessage     = null;
    }

    // ── Assignee lazy loading ────────────────────────────────────────────────
    get comboboxMemberOptions() {
        // Always include current assignee if exists (so combobox displays it correctly)
        if (this.subtask.Assignee__c && this.subtask.assigneeName) {
            const currentAssignee = { label: this.subtask.assigneeName, value: this.subtask.Assignee__c };
            // Avoid duplicates if already loaded
            const hasCurrent = this.memberOptions.some(o => o.value === this.subtask.Assignee__c);
            if (!hasCurrent) {
                return [currentAssignee, ...this.memberOptions];
            }
        }
        return this.memberOptions;
    }

    handleLoadMembers() {
        if (this.hasLoadedMembers || this.isLoadingMembers || !this.projectId) return;
        this.isLoadingMembers = true;
        loadMembers({ projectId: this.projectId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.memberOptions = (res.data || []).map(m => ({ label: m.Name, value: m.Id }));
                this.hasLoadedMembers = true;
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error loading members'; })
            .finally(() => { this.isLoadingMembers = false; });
    }

    handleAssigneeChange(event) {
        const memberId  = event.detail.value;
        const subtaskId = this.subtask.Id;
        assignSubtask({ subtaskId, memberId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                // Update local assignee name for display
                const selectedMember = this.memberOptions.find(m => m.value === memberId);
                this.subtask.assigneeName = selectedMember ? selectedMember.label : '';
                this.dispatchEvent(new CustomEvent('subtaskupdated', {
                    bubbles  : true,
                    composed : true,
                    detail   : { subtaskId, field: 'Assignee__c', value: memberId },
                }));
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error assigning subtask'; });
    }

    // ── Delete ───────────────────────────────────────────────────────────────
    handleDeleteClick() {
        this._confirm('Delete this subtask?', () => {
            const subtaskId = this.subtask.Id;
            deleteSubtask({ subtaskId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.dispatchEvent(new CustomEvent('subtaskdeleted', {
                        bubbles  : true,
                        composed : true,
                        detail   : { subtaskId },
                    }));
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error deleting subtask'; });
        });
    }
}

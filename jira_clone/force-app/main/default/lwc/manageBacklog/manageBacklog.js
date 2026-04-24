import { LightningElement, track } from 'lwc';
import loadBacklogData  from '@salesforce/apex/ManageBacklogController.loadBacklogData';
import deleteTickets    from '@salesforce/apex/ManageBacklogController.deleteTickets';
import createTicket     from '@salesforce/apex/ManageBacklogController.createTicket';
import createSprint     from '@salesforce/apex/ManageBacklogController.createSprint';
import updateSprint     from '@salesforce/apex/ManageBacklogController.updateSprint';
import completeSprint   from '@salesforce/apex/ManageBacklogController.completeSprint';
import deleteSprint     from '@salesforce/apex/ManageBacklogController.deleteSprint';
import startSprint      from '@salesforce/apex/ManageBacklogController.startSprint';

const PRIORITY_OPTIONS = [
    { label: '—',        value: ''         },
    { label: 'Low',      value: 'Low'      },
    { label: 'Medium',   value: 'Medium'   },
    { label: 'High',     value: 'High'     },
    { label: 'Critical', value: 'Critical' },
];

export default class ManageBacklog extends LightningElement {

    // ── Shared lookup data ────────────────────────────────────────────────────
    @track sprints           = [];
    @track backlogTickets    = [];
    @track statusOptions     = [];
    @track memberOptions     = [];
    @track ticketTypeOptions = [];
    @track epics             = [];
    priorityOptions          = PRIORITY_OPTIONS;

    // ── Page state ────────────────────────────────────────────────────────────
    isLoading    = false;
    errorMessage = null;
    modalError   = null;
    _projectId   = null;

    // ── Confirm dialog ────────────────────────────────────────────────────────
    @track showConfirmDialog = false;
    confirmMessage           = '';
    _pendingAction           = null;

    // ── Create Ticket modal ───────────────────────────────────────────────────
    @track showCreateTicketModal = false;
    newTicket          = this._emptyTicket();
    _newTicketSprintId = null;

    // ── Sprint modal (create / edit) ──────────────────────────────────────────
    @track showSprintModal       = false;
    sprintModalTitle             = 'Create Sprint';
    sprintModalSubmitLabel       = 'Create';
    sprintForm                   = this._emptySprintForm();
    _editingSprintId             = null;

    // ── Bulk selection tracking ───────────────────────────────────────────────
    _selectedTicketIds = new Set();

    // ── Computed ──────────────────────────────────────────────────────────────
    get hasSelectedTickets() { return this._selectedTicketIds.size > 0; }
    get selectedCount()      { return this._selectedTicketIds.size; }
    get hasBacklogTickets()  { return this.backlogTickets.length > 0; }
    get hasSprints()         { return this.sprints.length > 0; }

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    connectedCallback() {
        const projectId = localStorage.getItem('projectId');
        if (!projectId) {
            this.errorMessage = 'No project selected. Please select a project first.';
            return;
        }
        this._projectId = projectId;
        this._loadData();
    }

    // ── Data loading ──────────────────────────────────────────────────────────
    _loadData() {
        this.isLoading = true;
        loadBacklogData({ projectId: this._projectId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }

                const { sprints = [], status = [], members = [], epics = [], ticketTypes = [] } = res.data;

                this.epics             = epics;
                this.statusOptions     = status.map(s => ({ label: s.Name, value: s.Id }));
                this.memberOptions     = members.map(m => ({ label: m.Name, value: m.Id }));
                this.ticketTypeOptions = ticketTypes.map(t => ({ label: t.Name, value: t.Id }));

                this.sprints = sprints.map(s => ({
                    ...s,
                    isComplete: s.RecordStatus__c === 'complete',
                }));

                this.backlogTickets = [];
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Failed to load backlog data'; })
            .finally(() => { this.isLoading = false; });
    }

    _emptyTicket() {
        return { name: '', summary: '', description: '', storyPoint: null, ticketTypeId: '', currentStateId: '', priority: '' };
    }

    _emptySprintForm() {
        return { name: '', duration: null, startDate: '', goal: '' };
    }

    clearError() { this.errorMessage = null; }

    // ── Ticket events bubbled from c-ao-sprint-container / c-ao-ticket-item ───

    handleTicketSelect(event) {
        const { ticketId, selected } = event.detail;
        if (selected) {
            this._selectedTicketIds.add(ticketId);
        } else {
            this._selectedTicketIds.delete(ticketId);
        }
        this._selectedTicketIds = new Set(this._selectedTicketIds);
    }

    handleTicketDeleted(event) {
        const { ticketId } = event.detail;
        this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
        this._selectedTicketIds.delete(ticketId);
        this._selectedTicketIds = new Set(this._selectedTicketIds);
    }

    handleTicketUpdated(event) {
        const { ticketId, field, value } = event.detail;
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, [field]: value } : t
        );
    }

    // ── Bulk delete ───────────────────────────────────────────────────────────
    handleClearSelection() {
        this._selectedTicketIds = new Set();
        this.backlogTickets = this.backlogTickets.map(t => ({ ...t, isSelected: false }));
        this.template.querySelectorAll('c-ao-sprint-container').forEach(c => c.clearSelection());
    }

    handleBulkDelete() {
        this._confirm(`Delete ${this._selectedTicketIds.size} ticket(s)?`, () => {
            const ids = [...this._selectedTicketIds];
            deleteTickets({ ticketIds: ids })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.backlogTickets = this.backlogTickets.filter(t => !ids.includes(t.Id));
                    this._selectedTicketIds = new Set();
                    this.template.querySelectorAll('c-ao-sprint-container').forEach(c => c.refreshTickets());
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error deleting tickets'; });
        });
    }

    // ── Confirm helpers ───────────────────────────────────────────────────────
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

    // ── Create Ticket ─────────────────────────────────────────────────────────
    handleOpenCreateTicketForBacklog() {
        this._newTicketSprintId    = null;
        this.newTicket             = this._emptyTicket();
        this.modalError            = null;
        this.showCreateTicketModal = true;
    }

    handleCloseCreateTicketModal() {
        this.showCreateTicketModal = false;
    }

    handleNewTicketChange(event) {
        const field = event.target.dataset.field;
        const val   = event.detail ? event.detail.value : event.target.value;
        this.newTicket = { ...this.newTicket, [field]: val };
    }

    handleCreateTicketSubmit() {
        const { name, summary, description, storyPoint, ticketTypeId, currentStateId, priority } = this.newTicket;
        if (!name)         { this.modalError = 'Name is required.';        return; }
        if (!ticketTypeId) { this.modalError = 'Ticket Type is required.'; return; }

        createTicket({
            name,
            summary       : summary       || null,
            description   : description   || null,
            storyPoint    : storyPoint    ? parseInt(storyPoint, 10) : null,
            ticketTypeId,
            currentStateId,
            priority      : priority      || null,
            sprintId      : this._newTicketSprintId || null,
            assignedToId  : null,
            epicId        : null,
        })
            .then(res => {
                if (!res.success) { this.modalError = res.message; return; }
                if (!this._newTicketSprintId) {
                    const enriched = {
                        ...res.data,
                        epicName      : '',
                        ticketTypeName: this.ticketTypeOptions.find(o => o.value === ticketTypeId)?.label || '',
                        isSelected    : false,
                    };
                    this.backlogTickets = [...this.backlogTickets, enriched];
                } else {
                    const sid = this._newTicketSprintId;
                    const container = this.template.querySelector(`[data-sprint-id="${sid}"]`);
                    if (container) container.refreshTickets();
                }
                this.showCreateTicketModal = false;
                this.newTicket             = this._emptyTicket();
            })
            .catch(err => { this.modalError = err.body?.message || 'Error creating ticket'; });
    }

    // ── Sprint events from c-ao-sprint-container ──────────────────────────────
    handleSprintAddTicket(event) {
        this._newTicketSprintId    = event.detail.sprintId;
        this.newTicket             = this._emptyTicket();
        this.modalError            = null;
        this.showCreateTicketModal = true;
    }

    handleSprintEdit(event) {
        const sprintId = event.detail.sprintId;
        const sprint   = this.sprints.find(s => s.Id === sprintId);
        if (!sprint) return;
        this._editingSprintId       = sprintId;
        this.sprintModalTitle       = 'Edit Sprint';
        this.sprintModalSubmitLabel = 'Update';
        this.sprintForm = {
            name     : sprint.Name,
            duration : sprint.Duration__c,
            startDate: sprint.StartDate__c,
            goal     : sprint.Goal__c || '',
        };
        this.modalError      = null;
        this.showSprintModal = true;
    }

    handleSprintDelete(event) {
        const sprintId = event.detail.sprintId;
        this._confirm('Delete this sprint? Tickets will be moved to backlog.', () => {
            deleteSprint({ sprintId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._loadData();
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error deleting sprint'; });
        });
    }

    handleSprintComplete(event) {
        const sprintId = event.detail.sprintId;
        this._confirm('Mark this sprint as complete?', () => {
            completeSprint({ sprintId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.sprints = this.sprints.map(s =>
                        s.Id === sprintId ? { ...s, RecordStatus__c: 'complete', isComplete: true } : s
                    );
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error completing sprint'; });
        });
    }

    handleSprintStart(event) {
        const sprintId = event.detail.sprintId;
        this._confirm('Start this sprint?', () => {
            startSprint({ sprintId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error starting sprint'; });
        });
    }

    // ── Create Sprint ─────────────────────────────────────────────────────────
    handleOpenCreateSprint() {
        this._editingSprintId       = null;
        this.sprintModalTitle       = 'Create Sprint';
        this.sprintModalSubmitLabel = 'Create';
        this.sprintForm             = this._emptySprintForm();
        this.modalError             = null;
        this.showSprintModal        = true;
    }

    handleCloseSprintModal() {
        this.showSprintModal = false;
    }

    handleSprintFormChange(event) {
        const field = event.target.dataset.field;
        const val   = event.detail ? event.detail.value : event.target.value;
        this.sprintForm = { ...this.sprintForm, [field]: val };
    }

    handleSprintSubmit() {
        const { name, duration, startDate, goal } = this.sprintForm;
        if (!name || !duration || !startDate || !goal) {
            this.modalError = 'All sprint fields are required.';
            return;
        }
        if (this._editingSprintId) {
            updateSprint({
                sprintId : this._editingSprintId,
                name,
                duration : parseInt(duration, 10),
                startDate,
                goal,
            })
                .then(res => {
                    if (!res.success) { this.modalError = res.message; return; }
                    const sid = this._editingSprintId;
                    this.sprints = this.sprints.map(s =>
                        s.Id === sid
                            ? { ...s, Name: name, Duration__c: duration, StartDate__c: startDate, Goal__c: goal }
                            : s
                    );
                    this.showSprintModal = false;
                })
                .catch(err => { this.modalError = err.body?.message || 'Error updating sprint'; });
        } else {
            createSprint({
                name,
                duration : parseInt(duration, 10),
                startDate,
                goal,
                projectId: this._projectId,
            })
                .then(res => {
                    if (!res.success) { this.modalError = res.message; return; }
                    this.sprints = [...this.sprints, {
                        ...res.data,
                        isComplete: false,
                    }];
                    this.showSprintModal = false;
                    this.sprintForm      = this._emptySprintForm();
                })
                .catch(err => { this.modalError = err.body?.message || 'Error creating sprint'; });
        }
    }
}

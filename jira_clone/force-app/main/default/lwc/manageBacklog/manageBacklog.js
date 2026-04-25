import { LightningElement, track } from 'lwc';
import loadBacklogData from '@salesforce/apex/ManageBacklogController.loadBacklogData';
import deleteTickets   from '@salesforce/apex/ManageBacklogController.deleteTickets';
import createTicket    from '@salesforce/apex/ManageBacklogController.createTicket';
import createSprint    from '@salesforce/apex/ManageBacklogController.createSprint';
import updateSprint    from '@salesforce/apex/ManageBacklogController.updateSprint';
import completeSprint  from '@salesforce/apex/ManageBacklogController.completeSprint';
import deleteSprint    from '@salesforce/apex/ManageBacklogController.deleteSprint';
import startSprint     from '@salesforce/apex/ManageBacklogController.startSprint';

import { validateTicketName, validateTicketType } from './backlogTicketValidator';
import { validateSprintForm }                     from './backlogSprintValidator';

import { emptyTicket, formatTicket, PRIORITY_OPTIONS } from './backlogTicketUtils';
import { emptySprintForm, formatSprint }               from './backlogSprintUtils';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PAGE SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

export default class ManageBacklog extends LightningElement {

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    _projectId   = null;
    isLoading    = false;
    errorMessage = null;

    @track sprints           = [];
    @track backlogTickets    = [];
    @track statusOptions     = [];
    @track memberOptions     = [];
    @track ticketTypeOptions = [];
    @track epics             = [];
    priorityOptions          = PRIORITY_OPTIONS;

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    connectedCallback() {
        const projectId = localStorage.getItem('projectId');
        if (!projectId) {
            this.errorMessage = 'No project selected. Please select a project first.';
            return;
        }
        this._projectId = projectId;
        this._loadData();
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    clearError() { this.errorMessage = null; }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          TICKET SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @track showCreateTicketModal = false;
    newTicket          = emptyTicket();
    _newTicketSprintId = null;
    modalError         = null;  // shared by ticket and sprint modals — owned here as first consumer

    _selectedTicketIds = new Set();

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    // -- Bulk Delete --
    _executeBulkDelete() {
        const ids = [...this._selectedTicketIds];
        deleteTickets({ ticketIds: ids })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.backlogTickets = this.backlogTickets.filter(t => !ids.includes(t.Id));
                this._selectedTicketIds = new Set();
                this.template.querySelectorAll('c-ao-sprint-container').forEach(c => c.refreshTickets());
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error deleting tickets'; });
    }

    // -- Create Ticket --
    _executeCreateTicket() {
        const { name, summary, description, storyPoint, ticketTypeId, currentStateId, priority } = this.newTicket;
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
                    this.backlogTickets = [...this.backlogTickets, formatTicket(res.data, this.ticketTypeOptions, ticketTypeId)];
                } else {
                    const container = this.template.querySelector(`[data-sprint-id="${this._newTicketSprintId}"]`);
                    if (container) container.refreshTickets();
                }
                this.showCreateTicketModal = false;
                this.newTicket             = emptyTicket();
            })
            .catch(err => { this.modalError = err.body?.message || 'Error creating ticket'; });
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    // -- Ticket Bubble Events --
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

    // -- Bulk Selection --
    handleClearSelection() {
        this._selectedTicketIds = new Set();
        this.backlogTickets = this.backlogTickets.map(t => ({ ...t, isSelected: false }));
        this.template.querySelectorAll('c-ao-sprint-container').forEach(c => c.clearSelection());
    }

    handleBulkDelete() {
        this._confirm(`Delete ${this._selectedTicketIds.size} ticket(s)?`, () => this._executeBulkDelete());
    }

    // -- Create Ticket Modal --
    handleOpenCreateTicketForBacklog() {
        this._newTicketSprintId    = null;
        this.newTicket             = emptyTicket();
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
        const nameError = validateTicketName(this.newTicket.name);
        if (nameError) { this.modalError = nameError; return; }

        const typeError = validateTicketType(this.newTicket.ticketTypeId);
        if (typeError) { this.modalError = typeError; return; }

        this._executeCreateTicket();
    }

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get hasSelectedTickets() { return this._selectedTicketIds.size > 0; }
    get selectedCount()      { return this._selectedTicketIds.size; }
    get hasBacklogTickets()  { return this.backlogTickets.length > 0; }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          SPRINT SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @track showSprintModal  = false;
    sprintModalTitle        = 'Create Sprint';
    sprintModalSubmitLabel  = 'Create';
    sprintForm              = emptySprintForm();
    _editingSprintId        = null;

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    // -- Update Sprint --
    _executeUpdateSprint() {
        const { name, duration, startDate, goal } = this.sprintForm;
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
    }

    // -- Create Sprint --
    _executeCreateSprint() {
        const { name, duration, startDate, goal } = this.sprintForm;
        createSprint({
            name,
            duration : parseInt(duration, 10),
            startDate,
            goal,
            projectId: this._projectId,
        })
            .then(res => {
                if (!res.success) { this.modalError = res.message; return; }
                this.sprints     = [...this.sprints, formatSprint(res.data)];
                this.showSprintModal = false;
                this.sprintForm      = emptySprintForm();
            })
            .catch(err => { this.modalError = err.body?.message || 'Error creating sprint'; });
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    // -- Sprint Bubble Events --
    handleSprintAddTicket(event) {
        this._newTicketSprintId    = event.detail.sprintId;
        this.newTicket             = emptyTicket();
        this.modalError            = null;
        this.showCreateTicketModal = true;
    }

    handleSprintEdit(event) {
        const sprint = this.sprints.find(s => s.Id === event.detail.sprintId);
        if (!sprint) return;
        this._editingSprintId       = sprint.Id;
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

    // -- Sprint Modal --
    handleOpenCreateSprint() {
        this._editingSprintId       = null;
        this.sprintModalTitle       = 'Create Sprint';
        this.sprintModalSubmitLabel = 'Create';
        this.sprintForm             = emptySprintForm();
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
        const error = validateSprintForm(this.sprintForm);
        if (error) { this.modalError = error; return; }

        if (this._editingSprintId) {
            this._executeUpdateSprint();
        } else {
            this._executeCreateSprint();
        }
    }

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get hasSprints() { return this.sprints.length > 0; }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         CONFIRM SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @track showConfirmDialog = false;
    confirmMessage           = '';
    _pendingAction           = null;

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleConfirm() {
        this.showConfirmDialog = false;
        if (this._pendingAction) { this._pendingAction(); this._pendingAction = null; }
    }

    handleCancelConfirm() {
        this.showConfirmDialog = false;
        this._pendingAction    = null;
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         PRIVATE HELPERS                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

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
                this.sprints           = sprints.map(formatSprint);
                this.backlogTickets    = [];
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Failed to load backlog data'; })
            .finally(() => { this.isLoading = false; });
    }

    _confirm(message, action) {
        this.confirmMessage    = message;
        this._pendingAction    = action;
        this.showConfirmDialog = true;
    }
}

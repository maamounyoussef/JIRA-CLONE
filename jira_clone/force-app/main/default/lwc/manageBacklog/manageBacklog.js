import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import createTicket          from '@salesforce/apex/ManageBacklogController.createTicket';
import loadBacklogData       from '@salesforce/apex/ManageBacklogController.loadBacklogData';
import loadBacklogTickets    from '@salesforce/apex/ManageBacklogController.loadBacklogTickets';
import moveTicketToSprint    from '@salesforce/apex/ManageBacklogController.moveTicketToSprint';
import moveTicketToBacklog   from '@salesforce/apex/ManageBacklogController.moveTicketToBacklog';
import deleteTickets         from '@salesforce/apex/ManageBacklogController.deleteTickets';
import createSprint          from '@salesforce/apex/ManageBacklogController.createSprint';
import updateSprint          from '@salesforce/apex/ManageBacklogController.updateSprint';
import completeSprint        from '@salesforce/apex/ManageBacklogController.completeSprint';
import deleteSprint          from '@salesforce/apex/ManageBacklogController.deleteSprint';
import startSprint           from '@salesforce/apex/ManageBacklogController.startSprint';
import loadTicketsBySprint   from '@salesforce/apex/ManageBacklogController.loadTicketsBySprint';
import deleteTicket          from '@salesforce/apex/ManageBacklogController.deleteTicket';
import updateTicketSummary   from '@salesforce/apex/ManageBacklogController.updateTicketSummary';
import updateTicketPriority  from '@salesforce/apex/ManageBacklogController.updateTicketPriority';
import changeTicketState     from '@salesforce/apex/ManageBacklogController.changeTicketState';
import assignTicket          from '@salesforce/apex/ManageBacklogController.assignTicket';
import updateTicketEpic      from '@salesforce/apex/ManageBacklogController.updateTicketEpic';
import createEpic            from '@salesforce/apex/ManageBacklogController.createEpic';
import createSubtask         from '@salesforce/apex/ManageBacklogController.createSubtask';
import updateSubtaskSummary  from '@salesforce/apex/ManageBacklogController.updateSubtaskSummary';
import assignSubtask         from '@salesforce/apex/ManageBacklogController.assignSubtask';
import deleteSubtask         from '@salesforce/apex/ManageBacklogController.deleteSubtask';
import deleteSubtasks        from '@salesforce/apex/ManageBacklogController.deleteSubtasks';
import aoThemeResource       from '@salesforce/resourceUrl/aoTheme';

import { validateSprintForm }        from './backlogSprintValidator';
import { validatePriorityForUpdate } from './backlogTicketValidator';

import { enrichTickets, formatTicket } from './backlogTicketUtils';
import { emptySprintForm, formatSprint, calcEndDate, PAGE_SIZE } from './backlogSprintUtils';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PAGE SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

export default class ManageBacklog extends LightningElement {

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    _projectId          = null;
    isLoading           = false;
    errorMessage        = null;
    _isBacklogDragOver  = false;
    _draggingFromSprint = false;
    _dragSourceSprintId = null;
    _dragTargetSprintId = null;

    @track _isSmallScreen = false;
    _mqList    = null;
    _mqHandler = null;

    @track sprints           = [];
    @track backlogTickets    = [];
    @track statusOptions     = [];
    @track memberOptions     = [];
    @track ticketTypeOptions = [];
    @track epics             = [];
    @track priorityOptions   = [];

    _statuses = [];

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    connectedCallback() {
        loadStyle(this, aoThemeResource);
        const projectId = localStorage.getItem('projectId');
        if (!projectId) {
            this.errorMessage = 'No project selected. Please select a project first.';
            return;
        }
        this._projectId = projectId;
        this._loadData();

        this._mqList        = window.matchMedia('(max-width: 767px)');
        this._isSmallScreen = this._mqList.matches;
        this._mqHandler     = (e) => { this._isSmallScreen = e.matches; };
        this._mqList.addEventListener('change', this._mqHandler);
    }

    disconnectedCallback() {
        if (this._mqList) {
            this._mqList.removeEventListener('change', this._mqHandler);
        }
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    clearError() { this.errorMessage = null; }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          TICKET SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    showSprintTicketModal  = false;
    showBacklogTicketModal = false;
    _activeSprintId        = null;

    @track
    _selectedTicketIds = new Set();

    backlogOffset     = 0;
    backlogHasMore    = false;
    backlogIsLoading  = false;
    get backlogIsFirstPage() { return this.backlogOffset === 0; }
    get backlogIsLastPage()  { return !this.backlogHasMore; }
    get backlogCurrentPage() { return Math.floor(this.backlogOffset / PAGE_SIZE) + 1; }
    get backlogOffsetLabel() {
        const count = this.backlogTickets.length;
        return count === 0 ? 'No tickets' : `Showing ${this.backlogOffset + 1}–${this.backlogOffset + count}`;
    }

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    // -- Bulk Delete --
    _executeBulkDelete() {
        const ids = [...this._selectedTicketIds];
        deleteTickets({ ticketIds: ids })
            .then(res => {
                this.isLoading = true;
                if (!res.success) { this.errorMessage = res.message; return; }
                this.backlogTickets     = this.backlogTickets.filter(t => !ids.includes(t.Id));
                this._selectedTicketIds = new Set();
                const updatedSprints = res.data?.updatedSprints || [];
                this._enrichSprintsWithoutTickets(ids, updatedSprints);
                this._showSuccess('Tickets deleted');
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error deleting tickets'; })
            .finally(() => { this.isLoading = false; });

        }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────

    // -- UI Events --
    handleTicketSelect(event) {
        const { ticketId, selected } = event.detail;
        if (selected) {
            this._selectedTicketIds.add(ticketId);
        } else {
            this._selectedTicketIds.delete(ticketId);
        }
        this._selectedTicketIds = new Set(this._selectedTicketIds);
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, isSelected: selected } : t
        );
        this._enrichSprintsWithTicketSelection(ticketId, selected);
    }

    // -- Ticket Bubble Events from c-ao-ticket-item --

    // from c-ao-ticket-item
    handleTicketDelete(event) {
        const { ticketId } = event.detail;
        const ticketItem   = event.target;
        deleteTicket({ ticketId })
            .then(res => {
                this.isLoading = true;
                if (!res.success) { ticketItem.ticketError = res.message; return; }
                this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
                this._selectedTicketIds.delete(ticketId);
                this._selectedTicketIds = new Set(this._selectedTicketIds);
                const updatedSprint = res.data?.updatedSprint;
                this._enrichSprintsWithoutTicket(ticketId, updatedSprint);
                this._showSuccess('Ticket deleted');
            })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error deleting ticket'; })
            .finally(() => { this.isLoading = false; });

    }

    // from c-ao-ticket-item
    handleTicketSummaryUpdate(event) {
        const { ticketId, summary } = event.detail;
        const ticketItem            = event.target;
        updateTicketSummary({ ticketId, summary })
            .then(res => {
                this.isLoading = true;
                if (!res.success) { ticketItem.ticketError = res.message; return; }
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Summary__c: summary } : t
                );
                this._enrichSprintsWithTicketSummary(ticketId, summary);
                this._showSuccess('Summary updated');
            })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error updating summary'; })
            .finally(() => { this.isLoading = false; });

        }

    // from c-ao-ticket-item
    handleTicketPriorityUpdate(event) {
        const { ticketId, priority } = event.detail;
        const ticketItem             = event.target;
        const error = validatePriorityForUpdate(priority);
        if (error) { ticketItem.ticketError = error; return; }
        updateTicketPriority({ ticketId, priority })
            .then(res => {
                this.isLoading = true;
                if (!res.success) { ticketItem.ticketError = res.message; return; }
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Priority__c: priority } : t
                );
                this._enrichSprintsWithTicketPriority(ticketId, priority);
                this._showSuccess('Priority updated');
            })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error updating priority'; })
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketStateChange(event) {
        const { ticketId, fromStatusId, toStatusId } = event.detail;
        changeTicketState({ ticketId, fromStatusId, toStatusId })
            .then(res => {
                this.isLoading = true;
                if (!res.success) {
                    this._reKeyTicket(ticketId);
                    this.errorMessage = res.message;
                    return;
                }
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, CurrentState__c: toStatusId } : t
                );
                this._enrichSprintsWithTicketState(ticketId, toStatusId);
                if (res.data && res.data.isEndStatus) {
                    this.dispatchEvent(new ShowToastEvent({
                        title  : 'Final Status Reached',
                        message: 'This ticket has no further transitions available.',
                        variant: 'success'
                    }));
                } else {
                    this._showSuccess('State updated');
                }
            })
            .catch(err => {
                this._reKeyTicket(ticketId);
                this.errorMessage = err.body?.message || 'Error updating state';
            })
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketAssigneeChange(event) {
        const { ticketId, memberId } = event.detail;
        const ticketItem             = event.target;
        assignTicket({ ticketId, memberId })
            .then(res => {
                if (!res.success) { ticketItem.ticketError = res.message; return; }
                const found        = this.memberOptions.find(m => m.value === memberId);
                const assigneeName = found ? found.label : '';
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, AssignedTo__c: memberId, assigneeName } : t
                );
                this._enrichSprintsWithTicketAssignee(ticketId, memberId, assigneeName);
                this._showSuccess('Assignee updated');
            })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error assigning ticket'; });
    }

    // from c-ao-ticket-item
    handleTicketEpicUpdate(event) {
        const { ticketId, epicId } = event.detail;
        const ticketItem = event.target;
        updateTicketEpic({ ticketId, epicId })
            .then(res => {
                if (!res.success) { ticketItem.errors = res.message; return; }
                ticketItem.errors = null;
                const found    = this.epics.find(e => e.Id === epicId);
                const epicName = found ? found.Name : '';
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Epic__c: epicId, epicName } : t
                );
                this._enrichSprintsWithTicketEpic(ticketId, epicId, epicName);
                this._showSuccess('Epic updated');
            })
            .catch(err => { ticketItem.errors = err.body?.message || 'Error updating epic'; });
    }

    // from c-ao-ticket-item
    handleEpicCreateForTicket(event) {
        const { ticketId, name, summary, description, startDate, endDate } = event.detail;
        const ticketItem = event.target;
        let createdEpic;
        createEpic({ name, summary, projectId: this._projectId, description, startDate, endDate })
            .then(res => {
                if (!res.success) { ticketItem.errors = res.message; return; }
                createdEpic = res.data;
                return updateTicketEpic({ ticketId, epicId: createdEpic.Id });
            })
            .then(res => {
                if (!createdEpic) return;
                if (res && !res.success) { ticketItem.errors = res.message; return; }
                if (res) {
                    ticketItem.errors = null;
                    if (!this.epics.some(e => e.Id === createdEpic.Id)) {
                        this.epics = [...this.epics, createdEpic];
                    }
                    this.backlogTickets = this.backlogTickets.map(t =>
                        t.Id === ticketId ? { ...t, Epic__c: createdEpic.Id, epicName: createdEpic.Name } : t
                    );
                    this._enrichSprintsWithTicketEpic(ticketId, createdEpic.Id, createdEpic.Name);
                    this._showSuccess('Epic created and assigned');
                }
            })
            .catch(err => { ticketItem.errors = err.body?.message || 'Error creating epic'; });
    }

    // -- Subtask Bubble Events from c-ao-ticket-item --

    // from c-ao-ticket-item
    handleSubtaskCreate(event) {
        const { ticketId, summary, description, assigneeId, currentStateId, storyPoint } = event.detail;
        const ticketItem = event.target;
        createSubtask({ summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate: null })
            .then(res => {
                if (!res.success) { ticketItem.errors = res.message; return; }
                ticketItem.errors = null;
                ticketItem.refreshSubtasks();
                this._showSuccess('Subtask created');
            })
            .catch(err => { ticketItem.errors = err.body?.message || 'Error creating subtask'; });
    }

    // from c-ao-ticket-item
    handleSubtaskSummaryUpdate(event) {
        const { subtaskId, summary } = event.detail;
        const ticketItem             = event.target;
        updateSubtaskSummary({ subtaskId, summary })
            .then(() => { this._showSuccess('Subtask summary updated'); })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error updating subtask summary'; });
    }

    // from c-ao-ticket-item
    handleSubtaskAssigneeChange(event) {
        const { subtaskId, memberId } = event.detail;
        const ticketItem              = event.target;
        assignSubtask({ subtaskId, memberId })
            .then(() => { this._showSuccess('Subtask assignee updated'); })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error assigning subtask'; });
    }

    // from c-ao-ticket-item
    handleSubtaskDelete(event) {
        const { subtaskId } = event.detail;
        const ticketItem    = event.target;
        deleteSubtask({ subtaskId })
            .then(res => {
                if (!res.success) { ticketItem.ticketError = res.message; return; }
                ticketItem.refreshSubtasks();
                this._showSuccess('Subtask deleted');
            })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error deleting subtask'; });
    }

    // from c-ao-ticket-item
    handleSubtasksBulkDelete(event) {
        const { subtaskIds } = event.detail;
        const ticketItem     = event.target;
        deleteSubtasks({ subtaskIds })
            .then(res => {
                if (!res.success) { ticketItem.ticketError = res.message; return; }
                ticketItem.refreshSubtasks();
                this._showSuccess('Subtasks deleted');
            })
            .catch(err => { ticketItem.ticketError = err.body?.message || 'Error deleting subtasks'; });
    }

    // -- Bulk Selection --
    handleClearSelection() {
        this._selectedTicketIds = new Set();
        this.backlogTickets = this.backlogTickets.map(t => ({ ...t, isSelected: false }));
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => ({ ...t, isSelected: false })),
        }));
    }

    handleBulkDelete() {
        this._confirm(`Delete ${this._selectedTicketIds.size} ticket(s)?`, () => this._executeBulkDelete());
    }

    // -- Create Ticket Modal --
    handleOpenCreateTicketForBacklog() {
        this.showBacklogTicketModal = true;
    }

    handleSprintTicketCreate(event) {
        const data        = event.detail;
        const ticketModal = event.target;
        createTicket(data)
            .then(res => {
                if (!res.success) { ticketModal.errors = res.message; return; }
                const ticket = formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId);
                this._enrichSprintWithAddedTicket(data.sprintId, ticket);
                this.showSprintTicketModal = false;
                this._showSuccess('Ticket added to sprint');
            })
            .catch(err => { ticketModal.errors = err.body?.message || 'Error creating ticket'; });
    }

    handleBacklogTicketCreate(event) {
        const data        = event.detail;
        const ticketModal = event.target;
        createTicket(data)
            .then(res => {
                if (!res.success) { ticketModal.errors = res.message; return; }
                this.backlogTickets         = [...this.backlogTickets, formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId)];
                this.showBacklogTicketModal = false;
                this._showSuccess('Ticket created');
            })
            .catch(err => { ticketModal.errors = err.body?.message || 'Error creating ticket'; });
    }

    handleCreateTicketCancel() {
        this.showSprintTicketModal  = false;
        this.showBacklogTicketModal = false;
    }

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get hasSelectedTickets() { return this._selectedTicketIds.size > 0; }
    get selectedCount()      { return this._selectedTicketIds.size; }
    get hasBacklogTickets()  { return this.backlogTickets.length > 0; }
    get ticketVariant()      { return this._isSmallScreen ? 'full-ticket-card' : 'row'; }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          SPRINT SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @track showSprintModal  = false;
    sprintModalTitle        = 'Create Sprint';
    sprintModalSubmitLabel  = 'Create';
    sprintForm              = emptySprintForm();
    _editingSprintId        = null;
    @track modalError = null;

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    // -- Update Sprint --
    _executeUpdateSprint() {
        this.isLoading = true;
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
                        ? { ...s, Name: name, Duration__c: duration, StartDate__c: startDate, Goal__c: goal, endDate: calcEndDate(startDate, duration) }
                        : s
                );
                this.showSprintModal = false;
                this._showSuccess('Sprint updated');
            })
            .catch(err => { this.modalError = err.body?.message || 'Error updating sprint'; })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // -- Create Sprint --
    _executeCreateSprint() {
        this.isLoading = true;
        const { name, duration, startDate, goal } = this.sprintForm;
        createSprint({
            name,
            duration: parseInt(duration, 10),
            startDate,
            goal,
            projectId: this._projectId,
        })
        .then(res => {
            if (!res.success) {
                this.modalError = res.message;
                return;
            }
            this.sprints = [...this.sprints, formatSprint(res.data)];
            this.showSprintModal = false;
            this.sprintForm = emptySprintForm();
            this._showSuccess('Sprint created');
        })
        .catch(err => {
            this.modalError = err.body?.message || 'Error creating sprint';
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    // -- Sprint Toggle & Pagination --
    handleToggle(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this.sprints = this.sprints.map(s => {
            if (s.Id !== sprintId) return s;
            const isExpanded  = !s.isExpanded;
            const chevronIcon = isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            if (isExpanded && s.tickets.length === 0 && !s.isLoadingTickets) {
                this._loadSprintTickets(sprintId, 0);
            }
            return { ...s, isExpanded, chevronIcon };
        });
    }

    handleSprintPrevPage(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        const sprint   = this.sprints.find(s => s.Id === sprintId);
        if (!sprint || sprint.offset === 0) return;
        this._loadSprintTickets(sprintId, sprint.offset - PAGE_SIZE);
    }

    handleSprintNextPage(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        const sprint   = this.sprints.find(s => s.Id === sprintId);
        if (!sprint || !sprint.hasMore) return;
        this._loadSprintTickets(sprintId, sprint.offset + PAGE_SIZE);
    }

    // -- Sprint Action Buttons --
    handleSprintAddTicket(event) {
        this._activeSprintId       = event.currentTarget.dataset.sprintId;
        this.showSprintTicketModal = true;
    }

    handleSprintEdit(event) {
        const sprint = this.sprints.find(s => s.Id === event.currentTarget.dataset.sprintId);
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
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Delete this sprint? Tickets will be moved to backlog.', () => {
            deleteSprint({ sprintId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._loadData();
                    this._showSuccess('Sprint deleted');
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error deleting sprint'; });

            });
    }

    handleSprintComplete(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Mark this sprint as complete?', () => {
            completeSprint({ sprintId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._showSuccess('Sprint completed');
                })
                .catch(err => { this.errorMessage = err.body?.message || 'Error completing sprint'; });
        });
    }

    handleSprintStart(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Start this sprint?', () => {
            startSprint({ sprintId })
                .then(res => {
                    if (!res.success) { this.errorMessage = res.message; return; }
                    this._showSuccess('Sprint started');
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
        if(this.isLoading) return;
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
// ║                         DRAG & DROP SECTION                               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get backlogDropClass() {
        return 'backlog-container' + (this._isBacklogDragOver ? ' drop-target-active' : '');
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handlePageDragStart(event) {
        // getData returns empty string during dragstart — use DOM traversal instead
        const sprintEl           = event.target.closest('[data-sprint-id]');
        this._draggingFromSprint = !!sprintEl;
        this._dragSourceSprintId = sprintEl ? sprintEl.dataset.sprintId : null;
        this._dragTargetSprintId = null;
    }

    handlePageDragEnd() {
        this._draggingFromSprint = false;
        this._isBacklogDragOver  = false;
        this._dragSourceSprintId = null;
        this._dragTargetSprintId = null;
        this.sprints = this.sprints.map(s => ({ ...s, dropTargetClass: 'sprint-container' }));
    }

    handleDragOver(event) {
        event.preventDefault();
        const overSprint = !!event.currentTarget.dataset.sprintId;
        //dropEffect tells the browser what the cursor/UX should look like and what kind of drop is allowed
        event.dataTransfer.dropEffect = (this._draggingFromSprint && overSprint) ? 'none' : 'move';
    }

    handleDragEnterSprint(event) {
        if (this._draggingFromSprint) return;
        const sprintId = event.currentTarget.dataset.sprintId;
        this._dragTargetSprintId = sprintId;
        this._enrichSprintWithDragOver(sprintId);
        this._isBacklogDragOver = false;
    }

    handleDragLeaveSprint(event) {
        if (!event.currentTarget.contains(event.relatedTarget)) {
            const sprintId = event.currentTarget.dataset.sprintId;
            this._enrichSprintWithDragReset(sprintId);
        }
    }

    handleDragEnterBacklog() {
        this._isBacklogDragOver  = true;
        this._dragTargetSprintId = null;
        this.sprints = this.sprints.map(s => ({ ...s, dropTargetClass: 'sprint-container' }));
    }

    handleDragLeaveBacklog(event) {
        if (!event.currentTarget.contains(event.relatedTarget)) {
            this._isBacklogDragOver = false;
        }
    }

    handleDropOnSprint(event) {
        event.preventDefault();
        const targetSprintId = event.currentTarget.dataset.sprintId;
        this._enrichSprintWithDragReset(targetSprintId);
        if (this._draggingFromSprint) return;
        const raw = event.dataTransfer.getData('text/plain');
        if (!raw) return;
        const { ticketId } = JSON.parse(raw);
        this._executeMoveTicketToSprint(ticketId, targetSprintId);
    }

    handleDropOnBacklog(event) {
        event.preventDefault();
        this._isBacklogDragOver = false;
        if (!this._draggingFromSprint) return;
        const raw = event.dataTransfer.getData('text/plain');
        if (!raw) return;
        const { ticketId } = JSON.parse(raw);
        const sprint = this.sprints.find(s => s.Id === this._dragSourceSprintId);
        const ticket = sprint?.tickets.find(t => t.Id === ticketId);
        if (!ticket) return;
        this._executeMoveTicketToBacklog(ticket);
    }

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    _executeMoveTicketToSprint(ticketId, sprintId) {
        moveTicketToSprint({ ticketId, sprintId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const movedTicket = this.backlogTickets.find(t => t.Id === ticketId);
                this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
                if (movedTicket) {
                    const sprint = this.sprints.find(s => s.Id === sprintId);
                    if (sprint && sprint.isExpanded) {
                        this._enrichSprintWithAddedTicket(sprintId, { ...movedTicket, isSelected: false });
                    }
                }
                this._showSuccess('Ticket moved to sprint');
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error moving ticket to sprint'; });
    }

    _executeMoveTicketToBacklog(ticket) {
        moveTicketToBacklog({ ticketId: ticket.Id })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this._enrichSprintsWithoutTicket(ticket.Id);
                this.backlogTickets = [...this.backlogTickets, { ...ticket, isSelected: false }];
                this._showSuccess('Ticket moved to backlog');
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error moving ticket to backlog'; });
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         PRIVATE HELPERS                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    _loadData() {
        this.isLoading = true;
        loadBacklogData({ projectId: this._projectId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }

                const { sprints = [], status = [], members = [], epics = [], ticketTypes = [], backlogTickets = [], priorityOptions = [] } = res.data;

                this.epics             = epics;
                this.priorityOptions   = priorityOptions;
                this._statuses         = status;
                this.statusOptions     = status.map(s => ({ label: s.Name, value: s.Id }));
                this.memberOptions     = members.map(m => ({ label: m.Name, value: m.Id }));
                this.ticketTypeOptions = ticketTypes.map(t => ({ label: t.Name, value: t.Id }));
                this.sprints           = sprints.map(formatSprint);
                this.backlogOffset     = 0;
                this.backlogHasMore    = backlogTickets.length === PAGE_SIZE;
                this.backlogTickets    = enrichTickets(backlogTickets, epics, this.ticketTypeOptions, this.memberOptions);
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Failed to load backlog data'; })
            .finally(() => { this.isLoading = false; });
    }

    _confirm(message, action) {
        this.confirmMessage    = message;
        this._pendingAction    = action;
        this.showConfirmDialog = true;
    }

    _loadSprintTickets(sprintId, offset) {
        this._enrichSprintWithLoadingTicketState(sprintId, true);
        loadTicketsBySprint({ sprintId, offset, pageSize: PAGE_SIZE })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const rawTickets = res.data || [];
                const tickets    = enrichTickets(rawTickets, this.epics, this.ticketTypeOptions, this.memberOptions);
                const hasMore    = rawTickets.length === PAGE_SIZE;

                this._enrichSprintWithLoadedTickets(sprintId, {
                    tickets,
                    offset,
                    hasMore
                });
            })
            .catch(err => {
                this._enrichSprintWithLoadingTicketState(sprintId, false);
                this.errorMessage = err.body?.message || 'Error loading sprint tickets';
            })

    }

    handleBacklogPrevPage() {
        if (this.backlogOffset === 0) return;
        this._loadBacklogTickets(this.backlogOffset - PAGE_SIZE);
    }

    handleBacklogNextPage() {
        if (!this.backlogHasMore) return;
        this._loadBacklogTickets(this.backlogOffset + PAGE_SIZE);
    }

    _loadBacklogTickets(offset) {
        this.backlogIsLoading = true;
        loadBacklogTickets({ projectId: this._projectId, offset, pageSize: PAGE_SIZE })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const rawTickets = res.data || [];
                this.backlogTickets   = enrichTickets(rawTickets, this.epics, this.ticketTypeOptions, this.memberOptions);
                this.backlogOffset    = offset;
                this.backlogHasMore   = rawTickets.length === PAGE_SIZE;
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error loading backlog tickets'; })
            .finally(() => { this.backlogIsLoading = false; });
    }

    // -- Sprint enrichers (single sprint) --
    _enrichSprintWithAddedTicket(sprintId, ticket) {
        this.sprints = this.sprints.map(s => {
            if (s.Id !== sprintId) return s;
            const tickets = [...s.tickets, ticket];
            return { ...s, tickets, hasTickets: true };
        });
    }

    _enrichSprintWithDragOver(sprintId) {
        this.sprints = this.sprints.map(s =>
            s.Id === sprintId ? { ...s, dropTargetClass: 'sprint-container drop-target-active' } : s
        );
    }

    _enrichSprintWithDragReset(sprintId) {
        this.sprints = this.sprints.map(s =>
            s.Id === sprintId ? { ...s, dropTargetClass: 'sprint-container' } : s
        );
    }

    _enrichSprintWithLoadingTicketState(sprintId, isLoadingTickets) {
        this.sprints = this.sprints.map(s =>
            s.Id === sprintId ? { ...s, isLoadingTickets } : s
        );
    }

    _enrichSprintWithLoadedTickets(sprintId, payload) {
        const { tickets, offset, hasMore} = payload;
        this.sprints = this.sprints.map(s => {
            if (s.Id !== sprintId) return s;
            return {
                ...s,
                isLoadingTickets: false,
                tickets,
                hasTickets      : tickets.length > 0,
                offset,
                hasMore,
                isFirstPage     : offset === 0,
                isLastPage      : tickets.length < PAGE_SIZE,
                currentPage     : Math.floor(offset / PAGE_SIZE) + 1,
                offsetLabel     : tickets.length === 0 ? 'No tickets' : `Showing ${offset + 1}–${offset + tickets.length}`
            };
        });
    }

    // -- Ticket-in-sprints enrichers (all sprints) --
    _enrichSprintsWithTicketSelection(ticketId, isSelected) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, isSelected } : t),
        }));
    }

    _enrichSprintsWithoutTicket(ticketId, updatedSprint) {
        this.sprints = this.sprints.map(s => {
            const tickets = s.tickets.filter(t => t.Id !== ticketId);
            if (s.Id === updatedSprint?.Id) {
                return {
                    ...s,
                    tickets,
                    hasTickets: tickets.length > 0,
                    totalStoryPoints: updatedSprint.TotalStoryPoint__c
                };
            }
            return { ...s, tickets, hasTickets: tickets.length > 0 };
        });
    }

    _enrichSprintsWithoutTickets(ticketIds, updatedSprints) {
        const updatedSprintMap = {};
        updatedSprints.forEach(sprint => {
            updatedSprintMap[sprint.Id] = sprint;
        });

        this.sprints = this.sprints.map(s => {
            const tickets = s.tickets.filter(t => !ticketIds.includes(t.Id));
            const updatedSprint = updatedSprintMap[s.Id];

            if (updatedSprint) {
                return {
                    ...s,
                    tickets,
                    hasTickets: tickets.length > 0,
                    totalStoryPoints: updatedSprint.TotalStoryPoint__c
                };
            }
            return { ...s, tickets, hasTickets: tickets.length > 0 };
        });
    }

    _enrichSprintsWithTicketSummary(ticketId, summary) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Summary__c: summary } : t),
        }));
    }

    _enrichSprintsWithTicketPriority(ticketId, priority) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Priority__c: priority } : t),
        }));
    }

    _enrichSprintsWithTicketState(ticketId, statusId) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, CurrentState__c: statusId } : t),
        }));
    }

    _enrichSprintsWithTicketAssignee(ticketId, memberId, assigneeName) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, AssignedTo__c: memberId, assigneeName } : t),
        }));
    }

    _enrichSprintsWithTicketEpic(ticketId, epicId, epicName) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Epic__c: epicId, epicName } : t),
        }));
    }

    _enrichSprintsWithTicketRekey(ticketId, key) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, _key: key } : t),
        }));
    }

    _reKeyTicket(ticketId) {
        const newKey = Math.random().toString(36).slice(2);
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, _key: newKey } : t
        );
        this._enrichSprintsWithTicketRekey(ticketId, newKey);
    }

    _showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
    }
}

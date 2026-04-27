import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import createTicket        from '@salesforce/apex/ManageBacklogController.createTicket';
import loadBacklogData     from '@salesforce/apex/ManageBacklogController.loadBacklogData';
import loadBacklogTickets  from '@salesforce/apex/ManageBacklogController.loadBacklogTickets';
import moveTicketToSprint  from '@salesforce/apex/ManageBacklogController.moveTicketToSprint';
import moveTicketToBacklog from '@salesforce/apex/ManageBacklogController.moveTicketToBacklog';
import deleteTickets       from '@salesforce/apex/ManageBacklogController.deleteTickets';
import createSprint        from '@salesforce/apex/ManageBacklogController.createSprint';
import updateSprint        from '@salesforce/apex/ManageBacklogController.updateSprint';
import completeSprint      from '@salesforce/apex/ManageBacklogController.completeSprint';
import deleteSprint        from '@salesforce/apex/ManageBacklogController.deleteSprint';
import startSprint         from '@salesforce/apex/ManageBacklogController.startSprint';
import loadTicketsBySprint from '@salesforce/apex/ManageBacklogController.loadTicketsBySprint';
import aoThemeResource     from '@salesforce/resourceUrl/aoTheme';

import { validateSprintForm } from './backlogSprintValidator';

import { enrichTickets, formatTicket } from './backlogTicketUtils';
import { emptySprintForm, formatSprint, calcEndDate, PAGE_SIZE }      from './backlogSprintUtils';

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

    @track sprints           = [];
    @track backlogTickets    = [];
    @track statusOptions     = [];
    @track memberOptions     = [];
    @track ticketTypeOptions = [];
    @track epics             = [];
    @track priorityOptions   = [];

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
                if (!res.success) { this.errorMessage = res.message; return; }
                this.backlogTickets     = this.backlogTickets.filter(t => !ids.includes(t.Id));
                this._selectedTicketIds = new Set();
                this.sprints = [...this.sprints.map(s => {
                    const tickets = s.tickets.filter(t => !ids.includes(t.Id));
                    return { ...s, tickets, hasTickets: tickets.length > 0 };
                })];
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error deleting tickets'; });
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
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, isSelected: selected } : t
        );
        this._updateTicketInSprints(ticketId, { isSelected: selected });
    }

    handleBacklogTicketDeleted(event) {
        const { ticketId } = event.detail;
        this.backlogTickets = [...this.backlogTickets.filter(t => t.Id !== ticketId)];
        this._selectedTicketIds.delete(ticketId);
        this._selectedTicketIds = new Set(this._selectedTicketIds);
    }

    handleSprintTicketDeleted(event) {
        const { ticketId } = event.detail;
        this._selectedTicketIds.delete(ticketId);
        this._selectedTicketIds = new Set(this._selectedTicketIds);
        this._updateTicketInSprints(ticketId, null);
    }

    handleTicketSummaryUpdated(event) {
        const { ticketId, Summary__c } = event.detail;
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, Summary__c } : t
        );
        this._updateTicketInSprints(ticketId, { Summary__c });
    }

    handleTicketPriorityUpdated(event) {
        const { ticketId, Priority__c } = event.detail;
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, Priority__c } : t
        );
        this._updateTicketInSprints(ticketId, { Priority__c });
    }

    handleTicketStateUpdated(event) {
        const { ticketId, CurrentState__c } = event.detail;
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, CurrentState__c } : t
        );
        this._updateTicketInSprints(ticketId, { CurrentState__c });
    }

    handleCreateEpicForTicketModal(event) {
        const { ticketId, epic } = event.detail;
        if (!this.epics.some(e => e.Id === epic.Id)) {
            this.epics = [...this.epics, epic];
        }
        const updates = { Epic__c: epic.Id, epicName: epic.Name };
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, ...updates } : t
        );
        this._updateTicketInSprints(ticketId, updates);
    }

    handleUpdateTicket(event) {
        const { ticketId, epicId } = event.detail;
        const found    = this.epics.find(e => e.Id === epicId);
        const epicName = found ? found.Name : '';
        const updates  = { Epic__c: epicId, epicName };
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, ...updates } : t
        );
        this._updateTicketInSprints(ticketId, updates);
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
        const data = event.detail;
        createTicket(data)
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const ticket = formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId);
                const sprint = this.sprints.find(s => s.Id === data.sprintId);
                if (sprint) {
                    this._updateSprint(data.sprintId, { tickets: [...sprint.tickets, ticket], hasTickets: true });
                }
                this.showSprintTicketModal = false;
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error creating ticket'; });
    }

    handleBacklogTicketCreate(event) {
        const data = event.detail;
        createTicket(data)
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this.backlogTickets         = [...this.backlogTickets, formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId)];
                this.showBacklogTicketModal = false;
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error creating ticket'; });
    }

    handleCreateTicketCancel() {
        this.showSprintTicketModal  = false;
        this.showBacklogTicketModal = false;
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
                        ? { ...s, Name: name, Duration__c: duration, StartDate__c: startDate, Goal__c: goal, endDate: calcEndDate(startDate, duration) }
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
                this.sprints        = [...this.sprints, formatSprint(res.data)];
                this.showSprintModal = false;
                this.sprintForm      = emptySprintForm();
            })
            .catch(err => { this.modalError = err.body?.message || 'Error creating sprint'; });
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
                    this.sprints = this.sprints.map(s =>
                        s.Id === sprintId ? { ...s, RecordStatus__c: 'complete', isComplete: true } : s
                    );
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
        this._updateSprint(sprintId, { dropTargetClass: 'sprint-container drop-target-active' });
        this._isBacklogDragOver = false;
    }

    handleDragLeaveSprint(event) {
        if (!event.currentTarget.contains(event.relatedTarget)) {
            const sprintId = event.currentTarget.dataset.sprintId;
            this._updateSprint(sprintId, { dropTargetClass: 'sprint-container' });
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
        this._updateSprint(targetSprintId, { dropTargetClass: 'sprint-container' });
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
                        this._updateSprint(sprintId, {
                            tickets   : [...sprint.tickets, { ...movedTicket, isSelected: false }],
                            hasTickets: true,
                        });
                    }
                }
            })
            .catch(err => { this.errorMessage = err.body?.message || 'Error moving ticket to sprint'; });
    }

    _executeMoveTicketToBacklog(ticket) {
        moveTicketToBacklog({ ticketId: ticket.Id })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this._updateTicketInSprints(ticket.Id, null);
                this.backlogTickets = [...this.backlogTickets, { ...ticket, isSelected: false }];
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
        this._updateSprint(sprintId, { isLoadingTickets: true });
        loadTicketsBySprint({ sprintId, offset, pageSize: PAGE_SIZE })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const rawTickets = res.data || [];
                const tickets    = enrichTickets(rawTickets, this.epics, this.ticketTypeOptions, this.memberOptions);
                const hasMore    = rawTickets.length === PAGE_SIZE;
                this._updateSprint(sprintId, {
                    isLoadingTickets: false,
                    tickets,
                    hasTickets      : tickets.length > 0,
                    offset,
                    hasMore,
                    isFirstPage     : offset === 0,
                    isLastPage      : tickets.length < PAGE_SIZE,
                    currentPage     : Math.floor(offset / PAGE_SIZE) + 1,
                    offsetLabel     : tickets.length === 0 ? 'No tickets' : `Showing ${offset + 1}–${offset + tickets.length}`,
                });
            })
            .catch(err => {
                this._updateSprint(sprintId, { isLoadingTickets: false });
                this.errorMessage = err.body?.message || 'Error loading sprint tickets';
            });
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

    _updateSprint(sprintId, updates) {
        this.sprints = this.sprints.map(s => s.Id === sprintId ? { ...s, ...updates } : s);
    }

    _updateTicketInSprints(ticketId, updates) {
        this.sprints = this.sprints.map(s => {
            const tickets = updates === null
                ? s.tickets.filter(t => t.Id !== ticketId)
                : s.tickets.map(t => t.Id === ticketId ? { ...t, ...updates } : t);
            return { ...s, tickets, hasTickets: tickets.length > 0 };
        });
    }
}

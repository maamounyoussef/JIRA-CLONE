import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import loadTicketLinkedTo  from '@salesforce/apex/ManageBacklogController.loadTicketLinkedTo';
import loadTicketLinkTypes from '@salesforce/apex/ManageTicketTrackingController.loadTicketLinkTypes';
import createTicketFromSprint          from '@salesforce/apex/ManageBacklogController.createTicketFromSprint';
import createTicketFromBacklog          from '@salesforce/apex/ManageBacklogController.createTicketFromBacklog';
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

    @track openedTicket = null;
    @track linkTypeOptions = [];

    // ─── WIRE ─────────────────────────────────────────────────────────────────
    @wire(loadTicketLinkTypes, { projectId: '$_projectId' })
    handleLinkTypesWire({ data }) {
        if (data && data.success) {
            this.linkTypeOptions = (data.data && data.data.ticketLinkTypes) || [];
        }
    }

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
        this.isLoading = true;
        deleteTickets({ ticketIds: ids })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting tickets');
                this.backlogTickets     = this.backlogTickets.filter(t => !ids.includes(t.Id));
                this._selectedTicketIds = new Set();
                const updatedSprints = (res.data?.updatedSprints || []).map(formatSprint);
                this._deleteTicketsFromSprints(ids, updatedSprints);
                this._showSuccess('Tickets deleted');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error deleting tickets'))
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
        this._updateSprintsTicketSelection(ticketId, selected);
    }

    // -- Ticket Bubble Events from c-ao-ticket-item --

    // from c-ao-ticket-item — row click opens the ticket view modal
    handleTicketOpen(event) {
        console.log('[manageBacklog] handleTicketOpen', event.detail);
        this.openedTicket = event.detail.ticket || null;
    }

    handleCloseTicketView() {
        this.openedTicket = null;
    }

    // from c-ticket-view — user expanded the "Linked work items" section
    handleExpandLinkedTo(event) {
        const { ticketId } = event.detail;
        if (!ticketId || !this.openedTicket || this.openedTicket.Id !== ticketId) return;
        loadTicketLinkedTo({ ticketId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error loading linked items');
                const linkedItems = (res.data && res.data.ticketLinkTo) || [];
                // enrich the currently-open ticket so c-ticket-view re-renders with the data
                this.openedTicket = { ...this.openedTicket, linkedItems };
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error loading linked items'));
    }

    // from c-ao-ticket-item
    handleTicketDelete(event) {
        const { ticketId } = event.detail;
        this.isLoading = true;
        deleteTicket({ ticketId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting ticket');
                this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
                this._selectedTicketIds.delete(ticketId);
                this._selectedTicketIds = new Set(this._selectedTicketIds);
                const updatedSprint = res.data?.updatedSprint ? formatSprint(res.data.updatedSprint) : null;
                this._deleteTicketFromSprints(ticketId, updatedSprint);
                this._showSuccess('Ticket deleted');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error deleting ticket'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketSummaryUpdate(event) {
        const { ticketId, summary } = event.detail;
        this.isLoading = true;
        updateTicketSummary({ ticketId, summary })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating ticket summary');
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Summary__c: summary } : t
                );
                this._updateSprintsTicketSummary(ticketId, summary);
                this._showSuccess('Summary updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating ticket summary'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketPriorityUpdate(event) {
        const { ticketId, priority } = event.detail;
        const error = validatePriorityForUpdate(priority);
        if (error) { this._showError(error); return; }
        this.isLoading = true;
        updateTicketPriority({ ticketId, priority })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating ticket priority');
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Priority__c: priority } : t
                );
                this._updateSprintsTicketPriority(ticketId, priority);
                this._showSuccess('Priority updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating ticket priority'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketStateChange(event) {
        const { ticketId, fromStatusId, toStatusId } = event.detail;
        this.isLoading = true;
        changeTicketState({ ticketId, fromStatusId, toStatusId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating ticket state');
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, CurrentState__c: toStatusId } : t
                );
                this._updateSprintsTicketState(ticketId, toStatusId);
                const isEndStatus   = res.data?.isEndStatus;
                const updatedSprint = res.data?.updatedSprint ? formatSprint(res.data.updatedSprint) : null;
                if (isEndStatus) {
                    if (updatedSprint) {
                        this._updateSprintStoryPoints(updatedSprint);
                    }
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
                this._showError(err.body?.message || err.message || 'Error updating ticket state');
            })
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketAssigneeChange(event) {
        const { ticketId, memberId } = event.detail;
        assignTicket({ ticketId, memberId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error assigning ticket');
                const found        = this.memberOptions.find(m => m.value === memberId);
                const assigneeName = found ? found.label : '';
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, AssignedTo__c: memberId, assigneeName } : t
                );
                this._updateSprintsTicketAssignee(ticketId, memberId, assigneeName);
                this._showSuccess('Assignee updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error assigning ticket'));
    }

    // from c-ao-ticket-item
    handleTicketEpicUpdate(event) {
        const { ticketId, epicId } = event.detail;
        updateTicketEpic({ ticketId, epicId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating ticket epic');
                const found    = this.epics.find(e => e.Id === epicId);
                const epicName = found ? found.Name : '';
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Epic__c: epicId, epicName } : t
                );
                this._updateSprintsTicketEpic(ticketId, epicId, epicName);
                this._showSuccess('Epic updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating ticket epic'));
    }

    // from c-ao-ticket-item
    handleEpicCreateForTicket(event) {
        const { ticketId, name, summary, description, startDate, endDate } = event.detail;
        let createdEpic;
        createEpic({ name, summary, projectId: this._projectId, description, startDate, endDate })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating epic');
                createdEpic = res.data;
                return updateTicketEpic({ ticketId, epicId: createdEpic.Id });
            })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error assigning epic to ticket');
                if (!this.epics.some(e => e.Id === createdEpic.Id)) {
                    this.epics = [...this.epics, createdEpic];
                }
                this.backlogTickets = this.backlogTickets.map(t =>
                    t.Id === ticketId ? { ...t, Epic__c: createdEpic.Id, epicName: createdEpic.Name } : t
                );
                this._updateSprintsTicketEpic(ticketId, createdEpic.Id, createdEpic.Name);
                this._showSuccess('Epic created and assigned');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating epic'));
    }

    // -- Subtask Bubble Events from c-ao-ticket-item --

    // from c-ao-ticket-item
    handleSubtaskCreate(event) {
        const { ticketId, summary, description, assigneeId, currentStateId, storyPoint } = event.detail;
        const ticketItem = event.target;
        createSubtask({ summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate: null })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating subtask');
                ticketItem.refreshSubtasks();
                this._showSuccess('Subtask created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating subtask'));
    }

    // from c-ao-ticket-item
    handleSubtaskSummaryUpdate(event) {
        const { subtaskId, summary } = event.detail;
        updateSubtaskSummary({ subtaskId, summary })
            .then(res => {
                if (res && !res.success) throw new Error(res.message || 'Error updating subtask summary');
                this._showSuccess('Subtask summary updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating subtask summary'));
    }

    // from c-ao-ticket-item
    handleSubtaskAssigneeChange(event) {
        const { subtaskId, memberId } = event.detail;
        assignSubtask({ subtaskId, memberId })
            .then(res => {
                if (res && !res.success) throw new Error(res.message || 'Error assigning subtask');
                this._showSuccess('Subtask assignee updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error assigning subtask'));
    }

    // from c-ao-ticket-item
    handleSubtaskDelete(event) {
        const { subtaskId } = event.detail;
        const ticketItem    = event.target;
        deleteSubtask({ subtaskId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting subtask');
                ticketItem.refreshSubtasks();
                this._showSuccess('Subtask deleted');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error deleting subtask'));
    }

    // from c-ao-ticket-item
    handleSubtasksBulkDelete(event) {
        const { subtaskIds } = event.detail;
        const ticketItem     = event.target;
        deleteSubtasks({ subtaskIds })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting subtasks');
                ticketItem.refreshSubtasks();
                this._showSuccess('Subtasks deleted');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error deleting subtasks'));
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
        createTicketFromSprint(data)
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating ticket from sprint');
                const ticket        = formatTicket(res.data.createdTicket, this.ticketTypeOptions, data.ticketTypeId);
                const updatedSprint = formatSprint(res.data.updatedSprint);
                this._enrichSprintWithAddedTicket(updatedSprint, ticket);
                this.showSprintTicketModal = false;
                this._showSuccess('Ticket added to sprint');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from sprint'));
    }

    handleBacklogTicketCreate(event) {
        const data = event.detail;
        createTicketFromBacklog(data)
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating ticket from backlog');
                this._enrichBacklogWithTicket(formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId));
                this.showBacklogTicketModal = false;
                this._showSuccess('Ticket created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from backlog'));
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
                if (!res.success) throw new Error(res.message || 'Error updating sprint');
                const sid = this._editingSprintId;
                this.sprints = this.sprints.map(s =>
                    s.Id === sid
                        ? { ...s, Name: name, Duration__c: duration, StartDate__c: startDate, Goal__c: goal, endDate: calcEndDate(startDate, duration) }
                        : s
                );
                this.showSprintModal = false;
                this._showSuccess('Sprint updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating sprint'))
            .finally(() => { this.isLoading = false; });
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
                if (!res.success) throw new Error(res.message || 'Error creating sprint');
                this.sprints         = [...this.sprints, formatSprint(res.data)];
                this.showSprintModal = false;
                this.sprintForm      = emptySprintForm();
                this._showSuccess('Sprint created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating sprint'))
            .finally(() => { this.isLoading = false; });
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
                    if (!res.success) throw new Error(res.message || 'Error deleting sprint');
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._loadData();
                    this._showSuccess('Sprint deleted');
                })
                .catch(err => this._showError(err.body?.message || err.message || 'Error deleting sprint'));
        });
    }

    handleSprintComplete(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Mark this sprint as complete?', () => {
            completeSprint({ sprintId })
                .then(res => {
                    if (!res.success) throw new Error(res.message || 'Error completing sprint');
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._showSuccess('Sprint completed');
                })
                .catch(err => this._showError(err.body?.message || err.message || 'Error completing sprint'));
        });
    }

    handleSprintStart(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Start this sprint?', () => {
            startSprint({ sprintId })
                .then(res => {
                    if (!res.success) throw new Error(res.message || 'Error starting sprint');
                    this._showSuccess('Sprint started');
                })
                .catch(err => this._showError(err.body?.message || err.message || 'Error starting sprint'));
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
        this._updateSprintDragOver(sprintId);
        this._isBacklogDragOver = false;
    }

    handleDragLeaveSprint(event) {
        if (!event.currentTarget.contains(event.relatedTarget)) {
            const sprintId = event.currentTarget.dataset.sprintId;
            this._updateSprintDragReset(sprintId);
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
        this._updateSprintDragReset(targetSprintId);
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
                if (!res.success) throw new Error(res.message || 'Error moving ticket to sprint');
                const movedTicket   = this._deleteBacklogTicket(ticketId);
                const updatedSprint = formatSprint(res.data?.updatedSprint);

                if (movedTicket && updatedSprint) {
                    const sprint = this.sprints.find(s => s.Id === sprintId);
                    if (sprint && sprint.isExpanded) {
                        this._enrichSprintWithAddedTicket(updatedSprint, { ...movedTicket, isSelected: false });
                    }
                }
                this._showSuccess('Ticket moved to sprint');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error moving ticket to sprint'));
    }

    _executeMoveTicketToBacklog(ticket) {
        moveTicketToBacklog({ ticketId: ticket.Id })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error moving ticket to backlog');
                const updatedSprint = res.data?.updatedSprint ? formatSprint(res.data.updatedSprint) : null;
                this._deleteTicketFromSprints(ticket.Id, updatedSprint);
                this._enrichBacklogWithTicket(ticket);
                this._showSuccess('Ticket moved to backlog');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error moving ticket to backlog'));
    }


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         PRIVATE HELPERS                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    _loadData() {
        this.isLoading = true;
        loadBacklogData({ projectId: this._projectId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Failed to load backlog data');

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
            .catch(err => this._showError(err.body?.message || err.message || 'Failed to load backlog data'))
            .finally(() => { this.isLoading = false; });
    }

    _confirm(message, action) {
        this.confirmMessage    = message;
        this._pendingAction    = action;
        this.showConfirmDialog = true;
    }

    _loadSprintTickets(sprintId, offset) {
        this._updateSprintLoadingTicketState(sprintId, true);
        loadTicketsBySprint({ sprintId, offset, pageSize: PAGE_SIZE })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error loading sprint tickets');
                const rawTickets = res.data || [];
                const tickets    = enrichTickets(rawTickets, this.epics, this.ticketTypeOptions, this.memberOptions);
                const hasMore    = rawTickets.length === PAGE_SIZE;

                this._updateSprintWithLoadedTickets(sprintId, {
                    tickets,
                    offset,
                    hasMore
                });
            })
            .catch(err => {
                this._updateSprintLoadingTicketState(sprintId, false);
                this._showError(err.body?.message || err.message || 'Error loading sprint tickets');
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
                if (!res.success) throw new Error(res.message || 'Error loading backlog tickets');
                const rawTickets    = res.data || [];
                this.backlogTickets = enrichTickets(rawTickets, this.epics, this.ticketTypeOptions, this.memberOptions);
                this.backlogOffset  = offset;
                this.backlogHasMore = rawTickets.length === PAGE_SIZE;
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error loading backlog tickets'))
            .finally(() => { this.backlogIsLoading = false; });
    }

    // -- Backlog mutators --
    _deleteBacklogTicket(ticketId) {
        const ticket = this.backlogTickets.find(t => t.Id === ticketId);
        this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
        return ticket;
    }

    _enrichBacklogWithTicket(ticket) {
        this.backlogTickets = [...this.backlogTickets, { ...ticket, isSelected: false }];
    }

    // -- Sprint mutators (single sprint) --
    _enrichSprintWithAddedTicket(updatedSprint, ticket) {
        this.sprints = this.sprints.map(s => {
            if (s.Id !== updatedSprint.Id) return s;
            const tickets = [...s.tickets, ticket];
            return {
                ...s,
                tickets,
                hasTickets        : true,
                totalStoryPoints  : updatedSprint.totalStoryPoints,
                endedStoryPoints  : updatedSprint.endedStoryPoints,
                storyPointsPercent: updatedSprint.storyPointsPercent,
            };
        });
    }

    _updateSprintStoryPoints(updatedSprint) {
        this.sprints = this.sprints.map(s => {
            if (s.Id !== updatedSprint.Id) return s;
            return {
                ...s,
                totalStoryPoints: updatedSprint.totalStoryPoints,
                endedStoryPoints: updatedSprint.endedStoryPoints
            };
        });
    }

    _updateSprintDragOver(sprintId) {
        this.sprints = this.sprints.map(s =>
            s.Id === sprintId ? { ...s, dropTargetClass: 'sprint-container drop-target-active' } : s
        );
    }

    _updateSprintDragReset(sprintId) {
        this.sprints = this.sprints.map(s =>
            s.Id === sprintId ? { ...s, dropTargetClass: 'sprint-container' } : s
        );
    }

    _updateSprintLoadingTicketState(sprintId, isLoadingTickets) {
        this.sprints = this.sprints.map(s =>
            s.Id === sprintId ? { ...s, isLoadingTickets } : s
        );
    }

    _updateSprintWithLoadedTickets(sprintId, payload) {
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

    // -- Ticket-in-sprints mutators (all sprints) --
    _updateSprintsTicketSelection(ticketId, isSelected) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, isSelected } : t),
        }));
    }

    _deleteTicketFromSprints(ticketId, updatedSprint) {
        this.sprints = this.sprints.map(s => {
            const tickets = s.tickets.filter(t => t.Id !== ticketId);
            if (s.Id === updatedSprint?.Id) {
                return {
                    ...s,
                    tickets,
                    hasTickets: tickets.length > 0,
                    totalStoryPoints: updatedSprint.totalStoryPoints,
                    endedStoryPoints: updatedSprint.endedStoryPoints,
                    storyPointsPercent: updatedSprint.storyPointsPercent
                };
            }
            return { ...s, tickets, hasTickets: tickets.length > 0 };
        });
    }

    _deleteTicketsFromSprints(ticketIds, updatedSprints) {
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
                    totalStoryPoints: updatedSprint.totalStoryPoints,
                    endedStoryPoints: updatedSprint.endedStoryPoints,
                    storyPointsPercent: updatedSprint.storyPointsPercent
                };
            }
            return { ...s, tickets, hasTickets: tickets.length > 0 };
        });
    }

    _updateSprintsTicketSummary(ticketId, summary) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Summary__c: summary } : t),
        }));
    }

    _updateSprintsTicketPriority(ticketId, priority) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Priority__c: priority } : t),
        }));
    }

    _updateSprintsTicketState(ticketId, statusId) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, CurrentState__c: statusId } : t),
        }));
    }

    _updateSprintsTicketAssignee(ticketId, memberId, assigneeName) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, AssignedTo__c: memberId, assigneeName } : t),
        }));
    }

    _updateSprintsTicketEpic(ticketId, epicId, epicName) {
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, Epic__c: epicId, epicName } : t),
        }));
    }

    _updateSprintsTicketRekey(ticketId, key) {
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
        this._updateSprintsTicketRekey(ticketId, newKey);
    }

    _showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
    }

    _showError(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: message || 'An error occurred', variant: 'error' }));
    }
}

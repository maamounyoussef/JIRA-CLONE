import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import createTicketFromSprint          from '@salesforce/apex/ManageBacklogController.createTicketFromSprint';
import createTicketFromBacklog          from '@salesforce/apex/ManageBacklogController.createTicketFromBacklog';
import loadBacklogData       from '@salesforce/apex/ManageBacklogController.loadBacklogData';
import loadBacklogTickets    from '@salesforce/apex/ManageBacklogController.loadBacklogTickets';
import moveTicketToSprint    from '@salesforce/apex/ManageBacklogController.moveTicketToSprint';
import moveTicketToBacklog   from '@salesforce/apex/ManageBacklogController.moveTicketToBacklog';
import moveTicketPosition    from '@salesforce/apex/ManageBacklogController.moveTicketPosition';
import deleteTickets         from '@salesforce/apex/ManageBacklogController.deleteTickets';
import createSprint          from '@salesforce/apex/ManageBacklogController.createSprint';
import updateSprint          from '@salesforce/apex/ManageBacklogController.updateSprint';
import completeSprint        from '@salesforce/apex/ManageBacklogController.completeSprint';
import deleteSprint          from '@salesforce/apex/ManageBacklogController.deleteSprint';
import startSprint           from '@salesforce/apex/ManageBacklogController.startSprint';
import loadTicketsBySprint   from '@salesforce/apex/ManageBacklogController.loadTicketsBySprint';
import deleteTicket          from '@salesforce/apex/ManageBacklogController.deleteTicket';
import updateTicketSummary   from '@salesforce/apex/ManageBacklogController.updateTicketSummary';
import updateTicketDescription from '@salesforce/apex/ManageBacklogController.updateTicketDescription';
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
import loadTicketLinkedToType from '@salesforce/apex/ManageBacklogController.loadTicketLinkedToType';
import loadTicketLinkedTo     from '@salesforce/apex/ManageBacklogController.loadTicketLinkedTo';
import loadSubtasks           from '@salesforce/apex/ManageBacklogController.loadSubtasks';
import loadTicketBySearchTerm from '@salesforce/apex/ManageBacklogController.loadTicketBySearchTerm';
import linkToTicket          from '@salesforce/apex/ManageBacklogController.linkToTicket';
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
    @track _showChooseProject = false;
    isLoading           = false;
    errorMessage        = null;
    _isBacklogDragOver  = false;
    _draggingFromSprint = false;
    _dragSourceSprintId = null;
    _dragTargetSprintId = null;
    _dragSourceTicketId  = null;
    _dragSourceContainer = null;  // 'backlog' or sprintId
    _activeDropTicketId  = null;
    _activeDropTopZone   = null;  // 'backlog' or sprintId
    @track _showBacklogTopDropZone = false;

    @track _isSmallScreen = false;
    _mqList    = null;
    _mqHandler = null;

    /*
     * {
     *   sprints: [
     *     {
     *       Id: '0061x00000Sprint1',
     *       Name: 'Sprint 12',
     *       Duration__c: 2,
     *       StartDate__c: '2026-05-01',
     *       Goal__c: 'Ship OAuth flow',
     *       endDate: '2026-05-15',
     *       TotalStoryPoint__c: 21,
     *       TotalEndedStoryPoint__c: 8,
     *       storyPointsPercent: 38,
     *       isExpanded: true,
     *       chevronIcon: 'utility:chevrondown',
     *       isLoadingTickets: false,
     *       offset: 0,
     *       hasMore: false,
     *       isFirstPage: true,
     *       isLastPage: true,
     *       currentPage: 1,
     *       offsetLabel: 'Showing 1–3',
     *       dropTargetClass: 'sprint-container',
     *       hasTickets: true,
     *       tickets: [
     *         {
     *           Id: '0061x00000ABcDeFGHI',
     *           Name: 'TIC-00042',
     *           Summary__c: 'Add OAuth login',
     *           Description__c: 'Support Google and GitHub sign-in flows',
     *           Priority__c: 'High',
     *           CurrentState__c: '0061x00000Status01',
     *           AssignedTo__c: '0051x00000User01',
     *           Epic__c: '0061x00000Epic01',
     *           Ticket_Type__c: '0061x00000Type01',
     *           StoryPoint__c: 5,
     *           assigneeName: 'Jane Doe',
     *           epicName: 'Authentication revamp',
     *           ticketTypeName: 'Story',
     *           isSelected: false,
     *           _key: 'k2x9q7p1',
     *           linkedTo: [
                    {
                        "linkId": "a0Bd200000qgR5tEAE",
                        "type": "Blocks",
                        "recordStatus": "active",
                        "ticketFromId": "a0Cd200001EShGIEA1",
                        "linkedToTicket": {
                            "Id": "a0Cd200001EShOtherEA1",
                            "Name": "new Ticket",
                            "Summary__c": "aaaaaaa",
                            "Priority__c": "Low",
                            "CurrentState__c": "a02d200000YKyncAAD",
                            "AssignedTo__c": "a01...",
                            "Ticket_Type__c": "a05d200000P51DBAAZ"
                        }
                    }
                    ]
     *         }
     *       ]
     *     }
     *   ],
     *   backlogTickets: [
     *     {
     *       Id: '0061x00000XyZ',
     *       Name: 'TIC-00099',
     *       Summary__c: 'Spike: rate limiting',
     *       Description__c: 'Investigate Redis token bucket',
     *       Priority__c: 'Medium',
     *       CurrentState__c: '0061x00000Status01',
     *       AssignedTo__c: '0051x00000User02',
     *       Epic__c: '0061x00000Epic02',
     *       Ticket_Type__c: '0061x00000Type02',
     *       StoryPoint__c: 3,
     *       assigneeName: 'John Smith',
     *       epicName: 'Platform hardening',
     *       ticketTypeName: 'Spike',
     *       isSelected: false,
     *       _key: 'a8b2c4d6',
     *       linkedTo: []
     *     }
     *   ]
     * }
     */
    @track sprints           = [];
    @track backlogTickets    = [];
    @track statusOptions     = [];
    @track memberOptions     = [];
    @track ticketTypeOptions = [];
    @track epics             = [];
    @track priorityOptions   = [];

    _statuses = [];

    // ─── TICKET VIEW STATE ────────────────────────────────────────────────────
    @track _activeTicketViewId        = null;
    @track _ticketLinkedToTypeOptions = [];
    @track _ticketViewSearchOptions   = [];
    _ticketViewSearchTerm = '';

    @wire(loadTicketLinkedToType)
    wiredTicketLinkedToType({ data }) {
        if (data && data.success) {
            this._ticketLinkedToTypeOptions = (data.data || []).map(t => ({
                label: t.label || t.Name || t.value || '',
                value: t.value || t.Id || ''
            }));
        }
    }

    @wire(loadTicketBySearchTerm, { projectId: '$_projectId', searchTerm: '$_ticketViewSearchTerm' })
    wiredTicketViewSearch({ data }) {
        if (data && data.success) {
            this._ticketViewSearchOptions = (data.data || []).map(t => ({
                label: `${t.Name} — ${t.Summary__c || ''}`,
                value: t.Id
            }));
        }
    }


    @track _linkedToTargetTicketId = null;
    @wire(loadTicketLinkedTo, { ticketId: '$_linkedToTargetTicketId' })
    wiredTicketLinkedTo(result) {
        if (!this._linkedToTargetTicketId) return;
        if (result.data && result.data.success) {
            const linkedTo = result.data.data?.ticketLinkTo || [];
            this._patchTicketEverywhere(this._linkedToTargetTicketId, { linkedTo });
        }
        this.isLoading = false;
    }

    @track _subtasksTargetTicketId = null;
    @wire(loadSubtasks, { ticketId: '$_subtasksTargetTicketId' })
    wiredTicketViewSubtasks(result) {
        if (!this._subtasksTargetTicketId) return;
        if (result.data && result.data.success) {
            const subtasks = result.data.data || [];
            this._patchTicketEverywhere(this._subtasksTargetTicketId, { subtasks });
        }
        this.isLoading = false;
    }

    get isTicketViewOpen()           { return this._activeTicketViewId !== null; }
    get activeTicketViewModel() {
        if (!this._activeTicketViewId) return null;
        return this._findTicketById(this._activeTicketViewId);
    }
    get ticketLinkedToTypeOptions()  { return this._ticketLinkedToTypeOptions; }
    get ticketViewSearchOptions()    { return this._ticketViewSearchOptions; }

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    connectedCallback() {
        loadStyle(this, aoThemeResource);

        this._mqList        = window.matchMedia('(max-width: 767px)');
        this._isSmallScreen = this._mqList.matches;
        this._mqHandler     = (e) => { this._isSmallScreen = e.matches; };
        this._mqList.addEventListener('change', this._mqHandler);

        const projectId = localStorage.getItem('projectId');
        if (!projectId) {
            this._showChooseProject = true;
            return;
        }
        this._projectId = projectId;
        this._loadData();
    }

    handleProjectChosen(event) {
        const { projectId } = event.detail || {};
        if (!projectId) return;
        this._projectId         = projectId;
        this._showChooseProject = false;
        this._loadData();
    }

    get showChooseProject() { return this._showChooseProject; }

    disconnectedCallback() {
        if (this._mqList) {
            this._mqList.removeEventListener('change', this._mqHandler);
        }
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    clearError() { this.errorMessage = null; }

    // ─── TICKET VIEW HANDLERS ─────────────────────────────────────────────────
    handleOpenTicketView(event) {
        const t = event.detail.ticket || {};
        if (!t.Id) return;
        this._activeTicketViewId = t.Id;
    }

    handleCloseTicketView() {
        this._activeTicketViewId = null;
    }

    handleTicketViewSummaryUpdate(event) {
        const { ticketId, summary } = event.detail;
        this.isLoading = true;
        updateTicketSummary({ ticketId, summary })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating summary');
                this._updateTicketSummaryEverywhere(ticketId, summary);
                this._showSuccess('Summary updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating summary'))
            .finally(() => { this.isLoading = false; });
    }

    handleTicketViewStatusChange(event) {
        const { ticketId, fromStatusId, toStatusId } = event.detail;
        this.isLoading = true;
        changeTicketState({ ticketId, fromStatusId, toStatusId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating status');
                this._updateTicketStateEverywhere(ticketId, toStatusId);
                this._showSuccess('Status updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating status'))
            .finally(() => { this.isLoading = false; });
    }

    handleTicketViewDescriptionUpdate(event) {
        const { ticketId, description } = event.detail;
        this.isLoading = true;
        updateTicketDescription({ ticketId, description })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating description');
                this._updateTicketDescriptionEverywhere(ticketId, description);
                this._showSuccess('Description updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating description'))
            .finally(() => { this.isLoading = false; });
    }

    handleTicketSearch(event) {
        const term = (event.detail.searchTerm || '').trim();
        this._ticketViewSearchTerm = term ;
    }

    handleTicketLinkedToExpand(event) {
        const { ticketId } = event.detail;
        this.isLoading = true;
        this._linkedToTargetTicketId = ticketId;
    }

    handleTicketLinkCreate(event) {
        const { fromTicketId, toTicketId, linkType } = event.detail;
        this.isLoading = true;
        linkToTicket({ fromTicketId, toTicketId, linkType })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error linking ticket');
                const newLink = res.data?.ticketLink;
                if (!newLink) throw new Error('Error linking ticket');
                this._addLinkedTicketToTicket(fromTicketId, newLink);
                this._showSuccess('Ticket linked');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error linking ticket'))
            .finally(() => { this.isLoading = false; });
    }

    handleTicketViewSubtasksExpand(event) {
        const { ticketId } = event.detail;
        this.isLoading = true;
        this._subtasksTargetTicketId = ticketId;
    }

    handleTicketViewSubtaskCreate(event) {
        const { ticketId, summary, description, assigneeId, currentStateId, startDate, storyPoint } = event.detail;
        this.isLoading = true;
        createSubtask({ summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating subtask');
                const created = res.data;
                this._addSubtaskToTicket(ticketId, created);
                this._showSuccess('Subtask created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating subtask'))
            .finally(() => { this.isLoading = false; });
    }

    _findTicketById(ticketId) {
        const fromBacklog = this.backlogTickets.find(t => t.Id === ticketId);
        if (fromBacklog) return fromBacklog;
        for (const sprint of this.sprints) {
            const found = sprint.tickets.find(t => t.Id === ticketId);
            if (found) return found;
        }
        return null;
    }

    _patchTicketEverywhere(ticketId, patch) {
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, ...patch } : t
        );
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, ...patch } : t)
        }));
    }

    // Update one subtask in a ticket's subtasks list, giving it a fresh key so
    // the child row re-renders (and resets any cached combobox state).
    _patchSubtask(ticketId, subtaskId, patch) {
        const ticket = this._findTicketById(ticketId);
        if (!ticket) return;
        const subtasks = (ticket.subtasks || []).map(s =>
            s.Id === subtaskId ? { ...s, ...patch, _key: this._newKey() } : s
        );
        this._patchTicketEverywhere(ticketId, { subtasks });
    }

    _removeSubtasks(ticketId, subtaskIds) {
        const ticket = this._findTicketById(ticketId);
        if (!ticket) return;
        const subtasks = (ticket.subtasks || []).filter(s => !subtaskIds.includes(s.Id));
        this._patchTicketEverywhere(ticketId, { subtasks });
    }

    _newKey() {
        return Math.random().toString(36).slice(2);
    }


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
        this._updateTicketSelectionEverywhere(ticketId, selected);
    }

    // -- Ticket Bubble Events from c-ao-ticket-item --

    // from c-ao-ticket-item
    handleTicketDelete(event) {
        const { ticketId } = event.detail;
        this.isLoading = true;
        deleteTicket({ ticketId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting ticket');
                this._removeTicketFromBacklog(ticketId);
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
                this._updateTicketSummaryEverywhere(ticketId, summary);
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
                this._updateTicketPriorityEverywhere(ticketId, priority);
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
                this._updateTicketStateEverywhere(ticketId, toStatusId);
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
        this.isLoading = true;
        assignTicket({ ticketId, memberId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error assigning ticket');
                const found = this.memberOptions.find(m => m.value === memberId);
                const assigneeName = found ? found.label : '';
                this._updateTicketAssigneeEverywhere(ticketId, memberId, assigneeName);
                this._showSuccess('Assignee updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error assigning ticket'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleTicketEpicUpdate(event) {
        const { ticketId, epicId } = event.detail;
        this.isLoading = true;
        updateTicketEpic({ ticketId, epicId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating ticket epic');
                const found = this.epics.find(e => e.Id === epicId);
                const epicName = found ? found.Name : '';
                this._updateTicketEpicEverywhere(ticketId, epicId, epicName);
                this._showSuccess('Epic updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating ticket epic'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleEpicCreateForTicket(event) {
        const { ticketId, name, summary, description, startDate, endDate } = event.detail;
        let createdEpic;
        this.isLoading = true;
        createEpic({ name, summary, projectId: this._projectId, description, startDate, endDate })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating epic');
                createdEpic = res.data;
                return updateTicketEpic({ ticketId, epicId: createdEpic.Id });
            })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error assigning epic to ticket');
                this._addEpic(createdEpic);
                this._updateTicketEpicEverywhere(ticketId, createdEpic.Id, createdEpic.Name);
                this._showSuccess('Epic created and assigned');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating epic'))
            .finally(() => { this.isLoading = false; });
    }

    // -- Subtask Bubble Events from c-ao-ticket-item --

    // from c-ao-ticket-item
    handleSubtaskCreate(event) {
        const { ticketId, summary, description, assigneeId, currentStateId, storyPoint } = event.detail;
        this.isLoading = true;
        createSubtask({ summary, ticketId, description, assigneeId, currentStateId, storyPoint, startDate: null })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating subtask');
                const created = res.data;
                this._addSubtaskToTicket(ticketId, created);
                this._showSuccess('Subtask created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating subtask'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleSubtaskSummaryUpdate(event) {
        const { ticketId, subtaskId, summary } = event.detail;
        this.isLoading = true;
        updateSubtaskSummary({ subtaskId, summary })
            .then(res => {
                if (res && !res.success) throw new Error(res.message || 'Error updating subtask summary');
                this._patchSubtask(ticketId, subtaskId, { Summary__c: summary });
                this._showSuccess('Subtask summary updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error updating subtask summary'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleSubtaskAssigneeChange(event) {
        const { ticketId, subtaskId, memberId } = event.detail;
        this.isLoading = true;
        assignSubtask({ subtaskId, memberId })
            .then(res => {
                if (res && !res.success) throw new Error(res.message || 'Error assigning subtask');
                const found        = this.memberOptions.find(m => m.value === memberId);
                const assigneeName = found ? found.label : '';
                this._patchSubtask(ticketId, subtaskId, { Assignee__c: memberId, assigneeName });
                this._showSuccess('Subtask assignee updated');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error assigning subtask'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleSubtaskDelete(event) {
        const { ticketId, subtaskId } = event.detail;
        this.isLoading = true;
        deleteSubtask({ subtaskId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting subtask');
                this._removeSubtasks(ticketId, [subtaskId]);
                this._showSuccess('Subtask deleted');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error deleting subtask'))
            .finally(() => { this.isLoading = false; });
    }

    // from c-ao-ticket-item
    handleSubtasksBulkDelete(event) {
        const { ticketId, subtaskIds } = event.detail;
        this.isLoading = true;
        deleteSubtasks({ subtaskIds })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error deleting subtasks');
                this._removeSubtasks(ticketId, subtaskIds);
                this._showSuccess('Subtasks deleted');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error deleting subtasks'))
            .finally(() => { this.isLoading = false; });
    }

    // -- Bulk Selection --
    handleClearSelection() {
        this._selectedTicketIds = new Set();
        this._clearAllTicketSelection();
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
        if(this.isLoading)
            return;
        this.isLoading = true;
        createTicketFromSprint(data)
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating ticket from sprint');
                const ticket        = formatTicket(res.data.createdTicket, this.ticketTypeOptions, data.ticketTypeId);
                const updatedSprint = formatSprint(res.data.updatedSprint);
                this._enrichSprintWithAddedTicket(updatedSprint, ticket);
                this.showSprintTicketModal = false;
                this._showSuccess('Ticket added to sprint');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from sprint'))
            .finally(() => { this.isLoading = false; });
    }

    handleBacklogTicketCreate(event) {
        const data = event.detail;
        if (this.isLoading) return;
        this.isLoading = true;
        createTicketFromBacklog(data)
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error creating ticket from backlog');
                const ticket = formatTicket(res.data, this.ticketTypeOptions, data.ticketTypeId);
                this._addBacklogTicket(ticket);
                this.showBacklogTicketModal = false;
                this._showSuccess('Ticket created');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error creating ticket from backlog'))
            .finally(() => { this.isLoading = false; });
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
        const { duration, startDate, goal } = this.sprintForm;
        updateSprint({
            sprintId : this._editingSprintId,
            duration : parseInt(duration, 10),
            startDate,
            goal,
        })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error updating sprint');
                const sid = this._editingSprintId;
                this.sprints = this.sprints.map(s =>
                    s.Id === sid
                        ? { ...s, Duration__c: duration, StartDate__c: startDate, Goal__c: goal, endDate: calcEndDate(startDate, duration) }
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
        const { duration, startDate, goal } = this.sprintForm;
        createSprint({
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
            this.isLoading = true;
            deleteSprint({ sprintId })
                .then(res => {
                    if (!res.success) throw new Error(res.message || 'Error deleting sprint');
                    const deletedSprint = this.sprints.find(s => s.Id === sprintId);
                    this._moveSprintTicketsToBacklog(deletedSprint);
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._showSuccess('Sprint deleted');
                })
                .catch(err => this._showError(err.body?.message || err.message || 'Error deleting sprint'))
                .finally(() => { this.isLoading = false; });
        });
    }

    handleSprintComplete(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Mark this sprint as complete?', () => {
            this.isLoading = true;
            completeSprint({ sprintId })
                .then(res => {
                    if (!res.success) throw new Error(res.message || 'Error completing sprint');
                    this.sprints = this.sprints.filter(s => s.Id !== sprintId);
                    this._showSuccess('Sprint completed');
                })
                .catch(err => this._showError(err.body?.message || err.message || 'Error completing sprint'))
                .finally(() => { this.isLoading = false; });
        });
    }

    handleSprintStart(event) {
        const sprintId = event.currentTarget.dataset.sprintId;
        this._confirm('Start this sprint?', () => {
            this.isLoading = true;
            startSprint({ sprintId })
                .then(res => {
                    if (!res.success) throw new Error(res.message || 'Error starting sprint');
                    this._showSuccess('Sprint started');
                })
                .catch(err => this._showError(err.body?.message || err.message || 'Error starting sprint'))
                .finally(() => { this.isLoading = false; });
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

    get showBacklogTopDropZone() {
        return this._showBacklogTopDropZone;
    }

    get backlogTopDropZoneClass() {
        return this._activeDropTopZone === 'backlog'
            ? 'top-drop-zone top-drop-zone--active'
            : 'top-drop-zone';
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handlePageDragStart(event) {
        // getData returns empty string during dragstart — use DOM traversal instead
        const sprintEl           = event.target.closest('[data-sprint-id]');
        const ticketEl           = event.target.closest('[data-ticket-id]');
        this._draggingFromSprint = !!sprintEl;
        this._dragSourceSprintId = sprintEl ? sprintEl.dataset.sprintId : null;
        this._dragSourceTicketId = ticketEl ? ticketEl.dataset.ticketId : null;
        this._dragSourceContainer = sprintEl ? sprintEl.dataset.sprintId : 'backlog';
        this._dragTargetSprintId = null;
        this._showSourceTopDropZone(this._dragSourceContainer);
    }

    handlePageDragEnd() {
        this._draggingFromSprint = false;
        this._isBacklogDragOver  = false;
        this._dragSourceSprintId = null;
        this._dragTargetSprintId = null;
        this._dragSourceTicketId = null;
        this._dragSourceContainer = null;
        this._clearDropFeedback();
        this._hideAllTopDropZones();
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

    // -- Same-container reorder handlers (ticket wrappers + top zones) --
    handleDropZoneDragOver(event) {
        // Same-container only: allow drop, else fall through to outer handlers.
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        event.preventDefault();
        event.stopPropagation();
        event.dataTransfer.dropEffect = 'move';
    }

    handleTicketDragEnter(event) {
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        const targetTicketId = event.currentTarget.dataset.ticketId;
        if (!targetTicketId || targetTicketId === this._dragSourceTicketId) return;
        event.stopPropagation();
        this._setActiveDropTicket(targetTicketId);
    }

    handleTicketDragLeave(event) {
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        if (event.currentTarget.contains(event.relatedTarget)) return;
        const targetTicketId = event.currentTarget.dataset.ticketId;
        if (this._activeDropTicketId === targetTicketId) {
            this._setActiveDropTicket(null);
        }
    }

    handleDropOnTicket(event) {
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        const beforeTicketId = event.currentTarget.dataset.ticketId;
        const sourceTicketId = this._dragSourceTicketId;
        if (!sourceTicketId || !beforeTicketId || sourceTicketId === beforeTicketId) {
            return;
        }
        event.preventDefault();
        event.stopPropagation();
        this._clearDropFeedback();
        this._executeMoveTicketPosition(sourceTicketId, beforeTicketId, targetContainer);
    }

    handleTopZoneDragEnter(event) {
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        event.stopPropagation();
        this._setActiveTopZone(targetContainer);
    }

    handleTopZoneDragLeave(event) {
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        if (event.currentTarget.contains(event.relatedTarget)) return;
        if (this._activeDropTopZone === targetContainer) {
            this._setActiveTopZone(null);
        }
    }

    handleDropOnTopZone(event) {
        const targetContainer = event.currentTarget.dataset.container;
        if (targetContainer !== this._dragSourceContainer) return;
        const sourceTicketId = this._dragSourceTicketId;
        if (!sourceTicketId) return;
        event.preventDefault();
        event.stopPropagation();
        this._clearDropFeedback();
        this._executeMoveTicketPosition(sourceTicketId, null, targetContainer);
    }

    // ─── APEX CALLS ───────────────────────────────────────────────────────────
    _executeMoveTicketPosition(movedTicketId, beforeTicketId, container) {
        this.isLoading = true;
        moveTicketPosition({ movedTicketId, beforeTicketId })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error reordering ticket');
                const updated = res.data?.movedTicket || null;
                this._reorderTicketInContainer(container, movedTicketId, beforeTicketId, updated);
                this._showSuccess('Ticket reordered');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error reordering ticket'))
            .finally(() => { this.isLoading = false; });
    }

    _executeMoveTicketToSprint(ticketId, sprintId) {
        this.isLoading = true;
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
            .catch(err => this._showError(err.body?.message || err.message || 'Error moving ticket to sprint'))
            .finally(() => { this.isLoading = false; });
    }

    _executeMoveTicketToBacklog(ticket) {
        this.isLoading = true;
        moveTicketToBacklog({ ticketId: ticket.Id })
            .then(res => {
                if (!res.success) throw new Error(res.message || 'Error moving ticket to backlog');
                const updatedSprint = res.data?.updatedSprint ? formatSprint(res.data.updatedSprint) : null;
                this._deleteTicketFromSprints(ticket.Id, updatedSprint);
                this._enrichBacklogWithTicket(ticket);
                this._showSuccess('Ticket moved to backlog');
            })
            .catch(err => this._showError(err.body?.message || err.message || 'Error moving ticket to backlog'))
            .finally(() => { this.isLoading = false; });
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

    // ─── PRINCIPAL STATE MUTATORS ──────────────────────────────────────────────
    _patchTicketEverywhere(ticketId, patch) {
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, ...patch } : t
        );
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, ...patch } : t)
        }));
    }

    _updateTicketSummaryEverywhere(ticketId, summary) {
        this._patchTicketEverywhere(ticketId, { Summary__c: summary });
    }

    _updateTicketPriorityEverywhere(ticketId, priority) {
        this._patchTicketEverywhere(ticketId, { Priority__c: priority });
    }

    _updateTicketStateEverywhere(ticketId, stateId) {
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, CurrentState__c: stateId } : t
        );
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => t.Id === ticketId ? { ...t, CurrentState__c: stateId } : t)
        }));
    }

    _updateTicketDescriptionEverywhere(ticketId, description) {
        this._patchTicketEverywhere(ticketId, { Description__c: description });
    }

    _updateTicketAssigneeEverywhere(ticketId, memberId, assigneeName) {
        this._patchTicketEverywhere(ticketId, { AssignedTo__c: memberId, assigneeName });
    }

    _updateTicketEpicEverywhere(ticketId, epicId, epicName) {
        this._patchTicketEverywhere(ticketId, { Epic__c: epicId, epicName });
    }

    _addLinkedTicketToTicket(ticketId, newLink) {
        const ticket = this._findTicketById(ticketId);
        const existing = ticket?.linkedTo || [];
        this._patchTicketEverywhere(ticketId, { linkedTo: [...existing, newLink] });
    }

    _addSubtaskToTicket(ticketId, subtask) {
        const ticket = this._findTicketById(ticketId);
        const existing = ticket?.subtasks || [];
        this._patchTicketEverywhere(ticketId, { subtasks: [...existing, subtask] });
    }

    _updateTicketSelectionEverywhere(ticketId, selected) {
        this.backlogTickets = this.backlogTickets.map(t =>
            t.Id === ticketId ? { ...t, isSelected: selected } : t
        );
        this._updateSprintsTicketSelection(ticketId, selected);
    }

    _clearAllTicketSelection() {
        this.backlogTickets = this.backlogTickets.map(t => ({ ...t, isSelected: false }));
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => ({ ...t, isSelected: false }))
        }));
    }

    _addEpic(epic) {
        if (!this.epics.some(e => e.Id === epic.Id)) {
            this.epics = [...this.epics, epic];
        }
    }

    _addBacklogTicket(ticket) {
        this.backlogTickets = [...this.backlogTickets, { ...ticket, isSelected: false }];
    }

    _removeTicketFromBacklog(ticketId) {
        this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
    }

    // -- Backlog mutators --
    _deleteBacklogTicket(ticketId) {
        const ticket = this.backlogTickets.find(t => t.Id === ticketId);
        this.backlogTickets = this.backlogTickets.filter(t => t.Id !== ticketId);
        return ticket;
    }

    _enrichBacklogWithTicket(ticket) {
        this._addBacklogTicket(ticket);
    }

    // When a sprint is deleted its tickets lose their Sprint__c server-side, so
    // move the loaded ones into the backlog list (de-selected, no sprint link).
    _moveSprintTicketsToBacklog(sprint) {
        const tickets = sprint?.tickets || [];
        if (tickets.length === 0) return;
        const movedTickets = tickets.map(t => ({ ...t, Sprint__c: null, isSelected: false }));
        const existingIds = new Set(this.backlogTickets.map(ticket => ticket.Id));
        const toAdd = movedTickets.filter(ticket => !existingIds.has(ticket.Id));
        this.backlogTickets = [...this.backlogTickets, ...toAdd];
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
                TotalStoryPoint__c     : updatedSprint.TotalStoryPoint__c,
                TotalEndedStoryPoint__c: updatedSprint.TotalEndedStoryPoint__c,
                storyPointsPercent     : updatedSprint.storyPointsPercent,
            };
        });
    }

    _updateSprintStoryPoints(updatedSprint) {
        this.sprints = this.sprints.map(s => {
            if (s.Id !== updatedSprint.Id) return s;
            return {
                ...s,
                TotalStoryPoint__c: updatedSprint.TotalStoryPoint__c,
                TotalEndedStoryPoint__c: updatedSprint.TotalEndedStoryPoint__c
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
                    TotalStoryPoint__c: updatedSprint.TotalStoryPoint__c,
                    TotalEndedStoryPoint__c: updatedSprint.TotalEndedStoryPoint__c,
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
                    TotalStoryPoint__c: updatedSprint.TotalStoryPoint__c,
                    TotalEndedStoryPoint__c: updatedSprint.TotalEndedStoryPoint__c,
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

    // -- Drag-and-drop reorder helpers --
    _setActiveDropTicket(ticketId) {
        if (this._activeDropTicketId === ticketId) return;
        this._activeDropTicketId = ticketId;
        if (ticketId !== null) {
            this._activeDropTopZone = null;
        }
        this._applyDropIndicatorClasses();
        this._applyTopZoneClasses();
    }

    _setActiveTopZone(container) {
        if (this._activeDropTopZone === container) return;
        this._activeDropTopZone = container;
        if (container !== null) {
            this._activeDropTicketId = null;
        }
        this._applyDropIndicatorClasses();
        this._applyTopZoneClasses();
    }

    _clearDropFeedback() {
        if (this._activeDropTicketId === null && this._activeDropTopZone === null) return;
        this._activeDropTicketId = null;
        this._activeDropTopZone = null;
        this._applyDropIndicatorClasses();
        this._applyTopZoneClasses();
    }

    _applyDropIndicatorClasses() {
        const activeId = this._activeDropTicketId;
        const classFor = (id) => (id === activeId ? 'drop-indicator drop-indicator--active' : 'drop-indicator');
        this.backlogTickets = this.backlogTickets.map(t => {
            const cls = classFor(t.Id);
            return t.dropIndicatorClass === cls ? t : { ...t, dropIndicatorClass: cls };
        });
        this.sprints = this.sprints.map(s => ({
            ...s,
            tickets: s.tickets.map(t => {
                const cls = classFor(t.Id);
                return t.dropIndicatorClass === cls ? t : { ...t, dropIndicatorClass: cls };
            })
        }));
    }

    _applyTopZoneClasses() {
        this.sprints = this.sprints.map(s => {
            const cls = this._activeDropTopZone === s.Id
                ? 'top-drop-zone top-drop-zone--active'
                : 'top-drop-zone';
            return s.topDropZoneClass === cls ? s : { ...s, topDropZoneClass: cls };
        });
    }

    _showSourceTopDropZone(container) {
        if (container === 'backlog') {
            this._showBacklogTopDropZone = true;
            return;
        }
        this.sprints = this.sprints.map(s =>
            s.Id === container && !s.showTopDropZone ? { ...s, showTopDropZone: true } : s
        );
    }

    _hideAllTopDropZones() {
        this._showBacklogTopDropZone = false;
        this.sprints = this.sprints.map(s =>
            s.showTopDropZone ? { ...s, showTopDropZone: false } : s
        );
    }

    _reorderTicketInContainer(container, sourceTicketId, beforeTicketId, updatedTicket) {
        const newScore = updatedTicket?.Score__c;
        const reorder = (arr) => {
            const sourceIdx = arr.findIndex(t => t.Id === sourceTicketId);
            if (sourceIdx === -1) return arr;
            const moved = newScore !== undefined && newScore !== null
                ? { ...arr[sourceIdx], Score__c: newScore }
                : arr[sourceIdx];
            const without = arr.filter((_, i) => i !== sourceIdx);
            let insertIdx;
            if (!beforeTicketId) {
                insertIdx = 0;
            } else {
                const targetIdx = without.findIndex(t => t.Id === beforeTicketId);
                if (targetIdx === -1) return arr;
                insertIdx = targetIdx + 1;
            }
            return [...without.slice(0, insertIdx), moved, ...without.slice(insertIdx)];
        };

        if (container === 'backlog') {
            this.backlogTickets = reorder(this.backlogTickets);
            return;
        }
        this.sprints = this.sprints.map(s =>
            s.Id === container ? { ...s, tickets: reorder(s.tickets) } : s
        );
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

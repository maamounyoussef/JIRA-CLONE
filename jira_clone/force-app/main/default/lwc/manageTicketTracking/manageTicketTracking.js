import { LightningElement, track, wire } from 'lwc';
import { loadStyle }    from 'lightning/platformResourceLoader';
import { refreshApex }  from '@salesforce/apex';
import loadManageTicketTrackingPage from '@salesforce/apex/ManageTicketTrackingController.loadManageTicketTrackingPage';
import changeTicketState            from '@salesforce/apex/ManageTicketTrackingController.changeTicketState';
import loadTicketLinkedTo           from '@salesforce/apex/ManageTicketTrackingController.loadTicketLinkedTo';
import loadTicketLinkTypes          from '@salesforce/apex/ManageTicketTrackingController.loadTicketLinkTypes';
import aoThemeResource              from '@salesforce/resourceUrl/aoTheme';

import { validateChangeTicketState }                        from './manageTicketTrackingValidator';
import { buildColumns, enrichTicketsWithTypeName, enrichTicketsWithAssigneeName } from './ticketUtils';
import { getValidTargetStatusIds, findTransitionId } from './workflowUtils';
import { formatSprintDateRange }                            from './sprintUtils';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PAGE SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

export default class ManageTicketTracking extends LightningElement {

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    _projectId      = null;
    isLoading       = false;
    errorMessage    = null;

    @track columns         = [];
    @track memberOptions   = [];
    @track statusOptions   = [];
    @track epics           = [];
    @track priorityOptions = [];



    _sprint              = null;
    _ticketTypes         = [];
    _workflowTransitions = [];
    _statuses            = [];
    _sprintTickets       = [];

    // Drag state
    _dragTicketId     = null;
    _dragFromStatusId = null;
    _dragTicketTypeId = null;
    _dragToStatusId   = null;

    // Linked-to popup state
    _ticketLinkTypes        = [];
    _linkedToTicketId       = null;
    _showLinkedToPopup      = false;
    _linkedToWireId         = '';       // reactive param — empty string prevents wire from firing
    _linkedToItems          = [];
    _linkedToListKey        = '';
    _wiredLinkedItemsResult = null;     // stored for refreshApex

    // ─── WIRE ─────────────────────────────────────────────────────────────────
    @wire(loadTicketLinkedTo, { ticketId: '$_linkedToWireId' })
    handleLinkedItemsWire(wireResult) {
        if (!this._linkedToWireId) return;
        this._wiredLinkedItemsResult = wireResult;
        const { data } = wireResult;
        if (data && data.success) {
            this._linkedToItems   = (data.data && data.data.ticketLinkTo) || [];
            this._linkedToListKey = String(Date.now());
        }
    }

    @wire(loadTicketLinkTypes, { projectId: '$_projectId' })
    handleLinkedTypeTicketWire({ data }) {
        if (data && data.success) {
            this._ticketLinkTypes = (data.data && data.data.ticketLinkTypes) || [];
        }
    }

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get sprint()              { return this._sprint; }
    get projectId()           { return this._projectId; }
    get showLinkedToPopup()   { return this._showLinkedToPopup; }
    get linkedToTicketId()    { return this._linkedToTicketId; }
    get linkedToItems()       { return this._linkedToItems; }
    get linkedToListKey()     { return this._linkedToListKey; }
    get ticketLinkTypes()  { return this._ticketLinkTypes || []; }
    get tickets() {return this._sprintTickets || [];}

    get sprintDateRange() {
        return formatSprintDateRange(this._sprint);
    }

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

    _loadData() {
        this.isLoading = true;
        loadManageTicketTrackingPage({ projectId: this._projectId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const response = res.data;
                this._sprint              = response.sprint || null;
                this._ticketTypes         = response.ticketTypes || [];
                this._workflowTransitions = response.workflows   || [];
                this._statuses            = response.status        || [];
                const endStatusSet        = new Set(response.ticketsAtEndStatus || []);
                this._sprintTickets       = (response.sprint_tickets || []).map(t => ({
                    ...t,
                    isEndStatus: endStatusSet.has(t.Id)
                }));
                this.epics                = response.epics          || [];
                this.priorityOptions      = response.priorityOptions || [];
                this.statusOptions        = this._statuses.map(s => ({ label: s.Name, value: s.Id }));
                this.memberOptions        = (response.members || []).map(m => ({
                    label: (m.User__r && m.User__r.Name) || m.Name || '',
                    value: m.Id,
                }));
                this._sprintTickets = enrichTicketsWithTypeName(this._sprintTickets, this._ticketTypes);
                this._sprintTickets = enrichTicketsWithAssigneeName(this._sprintTickets, response.members);
                this.columns = buildColumns(this._statuses, this._sprintTickets);
            })
            .catch(err => { this.errorMessage = (err.body && err.body.message) || 'Error loading page'; })
            .finally(() => { this.isLoading = false; });
    }

    _callChangeTicketState(ticketId, fromStatusId, toStatusId) {
        changeTicketState({ ticketId, fromStatusId, toStatusId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                const isEndStatus = res.data && res.data.isEndStatus;
                this._sprintTickets = this._sprintTickets.map(ticket =>
                    ticket.Id === ticketId
                        ? {
                            ...ticket,
                            CurrentState__c: toStatusId,
                            currentStatuses: this._statuses.find(s => s.statusId === toStatusId) || null,
                            isEndStatus:     isEndStatus || false
                          }
                        : ticket
                );
                if (isEndStatus) {
                    this.columns = this.columns.map(col => ({
                        ...col,
                        tickets: col.tickets.map(t =>
                            t.Id === ticketId
                                ? { ...t, isEndStatus: true, _renderKey: t.Id + '_' + Date.now() }
                                : t
                        )
                    }));
                }
            })
            .catch(err => { this.errorMessage = (err.body && err.body.message) || 'Error changing ticket state'; })
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    clearError() { this.errorMessage = null; }

    handleTicketStateChange(event) {
        const { ticketId, fromStatusId, toStatusId } = event.detail;
        if (toStatusId === fromStatusId) return;
        const ticket = this._sprintTickets.find(t => t.Id === ticketId);
        if (!ticket) return;
        const transitionId = findTransitionId(
            ticket.Ticket_Type__c, fromStatusId, toStatusId, this._ticketTypes, this._workflowTransitions
        );
        if (!transitionId) { this.errorMessage = 'This transition is not allowed by the workflow.'; return; }
        this._sprintTickets = this._sprintTickets.map(t =>
            t.Id === ticketId ? { ...t, CurrentState__c: toStatusId } : t
        );
        this.columns = buildColumns(this._statuses, this._sprintTickets);
        this._callChangeTicketState(ticketId, fromStatusId, toStatusId);
    }

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          TICKET SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleTicketDragStart(evt) {
        const { ticketId, fromStatusId, ticketTypeId } = evt.detail;
        this._dragTicketId     = ticketId;
        this._dragFromStatusId = fromStatusId;
        this._dragTicketTypeId = ticketTypeId;

        const validTargets = getValidTargetStatusIds(
            ticketTypeId, fromStatusId, this._ticketTypes, this._workflowTransitions
        );

        this.columns = this.columns.map(col => ({
            ...col,
            isValidTarget: validTargets.has(col.statusId)
        }));
    }

    handleTicketDrop(evt) {
        const { toStatusId }  = evt.detail;
        const ticketId        = this._dragTicketId;
        const fromStatusId    = this._dragFromStatusId;
        const ticketTypeId    = this._dragTicketTypeId;

        if (toStatusId === fromStatusId) return;
        this._dragToStatusId = toStatusId;

        const error = validateChangeTicketState(ticketId, toStatusId);
        if (error) { this.errorMessage = error; return; }

        const transitionId = findTransitionId(
            ticketTypeId, fromStatusId, toStatusId, this._ticketTypes, this._workflowTransitions
        );
        if (!transitionId) { this.errorMessage = 'This transition is not allowed by the workflow.'; return; }

        this._callChangeTicketState(ticketId, fromStatusId, toStatusId);
    }

    handleTicketDragEnd(evt) {
        const { ticketId }         = evt.detail;
        const newCurrentStatusId   = this._dragToStatusId;
        if (ticketId && newCurrentStatusId) {
            this._sprintTickets = this._sprintTickets.map(t =>
                t.Id === ticketId ? { ...t, CurrentState__c: newCurrentStatusId } : t
            );
        }
        this._clearDragState();
        this.columns = buildColumns(this._statuses, this._sprintTickets);
    }

    // ─── PRIVATE HELPERS ──────────────────────────────────────────────────────
    _clearDragState() {
        this._dragTicketId     = null;
        this._dragFromStatusId = null;
        this._dragTicketTypeId = null;
        this._dragToStatusId   = null;
        this.columns = this.columns.map(col => ({ ...col, isValidTarget: false }));
    }

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                       LINKED-TO POPUP SECTION                            ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleOpenLinkedTo(evt) {
        const { ticketId } = evt.detail;
        this._linkedToTicketId  = ticketId;
        this._showLinkedToPopup = true;
    }

    handleExpandLinkedTo(evt) {
        const { ticketId } = evt.detail;
        if (this._linkedToWireId === ticketId) {
            refreshApex(this._wiredLinkedItemsResult);
        } else {
            this._linkedToWireId = ticketId;
        }
    }

    handleCloseLinkedTo() {
        this._showLinkedToPopup  = false;
        this._linkedToTicketId   = null;
        this._linkedToItems      = [];
        this._linkedToListKey    = '';
    }
}

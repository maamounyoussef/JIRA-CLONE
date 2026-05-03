import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import loadManageTicketTrackingPage from '@salesforce/apex/ManageTicketTrackingController.loadManageTicketTrackingPage';
import changeTicketState            from '@salesforce/apex/ManageTicketTrackingController.changeTicketState';
import aoThemeResource              from '@salesforce/resourceUrl/aoTheme';

import { validateChangeTicketState }                        from './manageTicketTrackingValidator';
import { buildColumns }                                     from './ticketUtils';
import { getValidTargetStatusIds, findTransitionId, getWorkflowId } from './workflowUtils';
import { formatSprintDateRange }                            from './sprintUtils';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                           PAGE SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

export default class ManageTicketTracking extends LightningElement {

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    _projectId   = null;
    isLoading    = false;
    errorMessage = null;

    @track columns       = [];
    @track memberOptions = [];

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

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get sprint() { return this._sprint; }

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
                this._sprintTickets       = response.sprint_tickets || [];
                this.memberOptions        = (response.members || []).map(m => ({
                    Id:   m.Id,
                    name: (m.User__r && m.User__r.Name) || m.Name || ''
                }));
                this.columns = buildColumns(this._statuses, this._sprintTickets);
            })
            .catch(err => { this.errorMessage = (err.body && err.body.message) || 'Error loading page'; })
            .finally(() => { this.isLoading = false; });
    }

    _callChangeTicketState(ticketId, toStatusId, workflowId, workflowTransitionId) {
        changeTicketState({ ticketId, toStatusId, workflowId, workflowTransitionId })
            .then(res => {
                if (!res.success) { this.errorMessage = res.message; return; }
                this._sprintTickets = this._sprintTickets.map(ticket =>
                    ticket.Id === ticketId
                     ? {
                         ...ticket,
                         CurrentState__c: toStatusId,
                        currentStatuses: this._statuses.find(
                        status => status.statusId === toStatusId
                         ) || null
                       }
                       : ticket
               );
            })
            .catch(err => { this.errorMessage = (err.body && err.body.message) || 'Error changing ticket state'; })
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    clearError() { this.errorMessage = null; }

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

        const workflowId = getWorkflowId(ticketTypeId, this._ticketTypes);
        this._callChangeTicketState(ticketId, toStatusId, workflowId, transitionId);
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
}
